#!/usr/bin/env bash
# Who is online (presence.mjs) as a Lambda with a function URL, and the table
# it keeps it in.
#
#   scripts/presence/deploy.sh              # create or update everything
#   CODE_ONLY=1 scripts/presence/deploy.sh  # just the code
#   DRY_RUN=1 scripts/presence/deploy.sh    # say what it would do
set -euo pipefail

REGION="${PRESENCE_REGION:-eu-central-1}"
NAME=brasspawn-presence
TABLE=brasspawn-presence
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

log() { printf '\033[36m▸\033[0m %s\n' "$*"; }
run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then printf '\033[90m  would run: aws %s\033[0m\n' "$*"; else aws "$@"; fi
}

BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
mkdir -p "$BUILD/scripts/presence" "$BUILD/scripts/feed"
for f in identity presence dynamo lambda; do cp "$ROOT/scripts/presence/$f.mjs" "$BUILD/scripts/presence/"; done
cp "$ROOT/scripts/feed/s3.mjs" "$BUILD/scripts/feed/"   # for its credentials()
printf '{ "type": "module" }\n' > "$BUILD/package.json"
(cd "$BUILD" && zip -qr function.zip package.json scripts)
log "Package: $(du -h "$BUILD/function.zip" | cut -f1)"

if [[ "${CODE_ONLY:-0}" == "1" ]]; then
  run lambda update-function-code --region "$REGION" --function-name "$NAME" \
    --zip-file "fileb://$BUILD/function.zip" --query CodeSize --output text
  exit 0
fi

ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
ROLE_ARN="arn:aws:iam::$ACCOUNT:role/$NAME"
TABLE_ARN="arn:aws:dynamodb:$REGION:$ACCOUNT:table/$TABLE"

# One row a player, gone five minutes after they last said so. Paid by the
# request, which at this size is pennies.
if ! aws dynamodb describe-table --region "$REGION" --table-name "$TABLE" >/dev/null 2>&1; then
  log "Creating table $TABLE"
  run dynamodb create-table --region "$REGION" --table-name "$TABLE" \
    --attribute-definitions AttributeName=player,AttributeType=S \
    --key-schema AttributeName=player,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
  [[ "${DRY_RUN:-0}" == "1" ]] || aws dynamodb wait table-exists --region "$REGION" --table-name "$TABLE"
  run dynamodb update-time-to-live --region "$REGION" --table-name "$TABLE" \
    --time-to-live-specification Enabled=true,AttributeName=until >/dev/null
fi

if ! aws iam get-role --role-name "$NAME" >/dev/null 2>&1; then
  log "Creating role $NAME"
  run iam create-role --role-name "$NAME" --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{ "Effect": "Allow", "Principal": { "Service": "lambda.amazonaws.com" }, "Action": "sts:AssumeRole" }]
  }' >/dev/null
  run iam attach-role-policy --role-name "$NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  CREATED_ROLE=1
fi
# The table, and nothing else.
run iam put-role-policy --role-name "$NAME" --policy-name presence-table --policy-document "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    { \"Effect\": \"Allow\", \"Action\": [\"dynamodb:PutItem\", \"dynamodb:DeleteItem\", \"dynamodb:Scan\"],
      \"Resource\": \"$TABLE_ARN\" }
  ]
}"
[[ "${CREATED_ROLE:-0}" == "1" && "${DRY_RUN:-0}" != "1" ]] && sleep 12

ENVIRONMENT="Variables={PRESENCE_REGION=$REGION,PRESENCE_TABLE=$TABLE}"
if aws lambda get-function --region "$REGION" --function-name "$NAME" >/dev/null 2>&1; then
  log "Updating $NAME"
  run lambda update-function-code --region "$REGION" --function-name "$NAME" \
    --zip-file "fileb://$BUILD/function.zip" --query CodeSize --output text
  [[ "${DRY_RUN:-0}" == "1" ]] || aws lambda wait function-updated --region "$REGION" --function-name "$NAME"
  run lambda update-function-configuration --region "$REGION" --function-name "$NAME" \
    --environment "$ENVIRONMENT" --timeout 10 --memory-size 256 --query LastUpdateStatus --output text
else
  log "Creating $NAME"
  for attempt in 1 2 3 4 5 6; do
    if run lambda create-function --region "$REGION" --function-name "$NAME" \
      --runtime nodejs22.x --architectures arm64 --handler scripts/presence/lambda.handler \
      --role "$ROLE_ARN" --memory-size 256 --timeout 10 \
      --environment "$ENVIRONMENT" --zip-file "fileb://$BUILD/function.zip" \
      --query FunctionArn --output text; then break; fi
    # A new role takes a few seconds before Lambda may assume it.
    [[ $attempt == 6 ]] && exit 1
    sleep 10
  done
  [[ "${DRY_RUN:-0}" == "1" ]] || aws lambda wait function-active --region "$REGION" --function-name "$NAME"
fi

# Nobody can run up the bill: at most five at once.
run lambda put-function-concurrency --region "$REGION" --function-name "$NAME" \
  --reserved-concurrent-executions 5 >/dev/null

# Open to anyone: every request proves who is asking with Game Center's
# signature, which the function checks itself.
if ! aws lambda get-function-url-config --region "$REGION" --function-name "$NAME" >/dev/null 2>&1; then
  log "Creating the function URL"
  run lambda create-function-url-config --region "$REGION" --function-name "$NAME" --auth-type NONE >/dev/null
  run lambda add-permission --region "$REGION" --function-name "$NAME" --statement-id public-url \
    --action lambda:InvokeFunctionUrl --principal '*' --function-url-auth-type NONE >/dev/null
fi

# Its log: two weeks.
run logs create-log-group --region "$REGION" --log-group-name "/aws/lambda/$NAME" 2>/dev/null || true
run logs put-retention-policy --region "$REGION" --log-group-name "/aws/lambda/$NAME" --retention-in-days 14

# The table, written, read and cleared from inside the function.
if [[ "${DRY_RUN:-0}" != "1" ]]; then
  aws lambda wait function-updated --region "$REGION" --function-name "$NAME"
  OUT="$(mktemp)"
  aws lambda invoke --region "$REGION" --function-name "$NAME" --payload '{"presenceCheck":true}' \
    --cli-binary-format raw-in-base64-out "$OUT" >/dev/null
  log "Presence check: $(cat "$OUT")"
  rm -f "$OUT"
fi

URL="$(aws lambda get-function-url-config --region "$REGION" --function-name "$NAME" --query FunctionUrl --output text 2>/dev/null || echo '(none yet)')"
log "Presence at $URL"
