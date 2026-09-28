#!/usr/bin/env bash
# The referee (referee.mjs) as a Lambda with a function URL, and the hourly
# rule that settles the games one player never reported.
#
#   scripts/ratings/deploy.sh              # create or update everything
#   CODE_ONLY=1 scripts/ratings/deploy.sh  # just the code
#   DRY_RUN=1 scripts/ratings/deploy.sh    # say what it would do
#
# Beside the daily feed, in the same bucket: the ratings under
# ratings-state/ (private — the site serves only media/*), and each clock's
# list under media/ratings/v1/, which is what the app reads.
set -euo pipefail

REGION="${RATINGS_REGION:-eu-central-1}"
NAME=brasspawn-ratings
RULE=brasspawn-ratings-sweep
BUCKET="${RATINGS_BUCKET:-brasspawn-media}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

log() { printf '\033[36m▸\033[0m %s\n' "$*"; }
run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then printf '\033[90m  would run: aws %s\033[0m\n' "$*"; else aws "$@"; fi
}

BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
mkdir -p "$BUILD/scripts/ratings" "$BUILD/scripts/feed" "$BUILD/node_modules"
for f in glicko identity referee store lambda; do cp "$ROOT/scripts/ratings/$f.mjs" "$BUILD/scripts/ratings/"; done
cp "$ROOT/scripts/feed/s3.mjs" "$BUILD/scripts/feed/"
cp -R "$ROOT/node_modules/chess.js" "$BUILD/node_modules/"
printf '{ "type": "module" }\n' > "$BUILD/package.json"
(cd "$BUILD" && zip -qr function.zip package.json scripts node_modules)
log "Package: $(du -h "$BUILD/function.zip" | cut -f1)"

if [[ "${CODE_ONLY:-0}" == "1" ]]; then
  run lambda update-function-code --region "$REGION" --function-name "$NAME" \
    --zip-file "fileb://$BUILD/function.zip" --query CodeSize --output text
  exit 0
fi

ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
ROLE_ARN="arn:aws:iam::$ACCOUNT:role/$NAME"

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
# Its own two prefixes and nothing else in the bucket.
run iam put-role-policy --role-name "$NAME" --policy-name ratings-bucket --policy-document "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    { \"Effect\": \"Allow\", \"Action\": [\"s3:GetObject\", \"s3:PutObject\", \"s3:DeleteObject\"],
      \"Resource\": \"arn:aws:s3:::$BUCKET/ratings-state/*\" },
    { \"Effect\": \"Allow\", \"Action\": \"s3:PutObject\", \"Resource\": \"arn:aws:s3:::$BUCKET/media/ratings/*\" },
    { \"Effect\": \"Allow\", \"Action\": \"s3:ListBucket\", \"Resource\": \"arn:aws:s3:::$BUCKET\",
      \"Condition\": { \"StringLike\": { \"s3:prefix\": \"ratings-state/*\" } } }
  ]
}"
[[ "${CREATED_ROLE:-0}" == "1" && "${DRY_RUN:-0}" != "1" ]] && sleep 12

ENVIRONMENT="Variables={RATINGS_BUCKET=$BUCKET,RATINGS_REGION=$REGION}"
if aws lambda get-function --region "$REGION" --function-name "$NAME" >/dev/null 2>&1; then
  log "Updating $NAME"
  run lambda update-function-code --region "$REGION" --function-name "$NAME" \
    --zip-file "fileb://$BUILD/function.zip" --query CodeSize --output text
  [[ "${DRY_RUN:-0}" == "1" ]] || aws lambda wait function-updated --region "$REGION" --function-name "$NAME"
  run lambda update-function-configuration --region "$REGION" --function-name "$NAME" \
    --environment "$ENVIRONMENT" --timeout 20 --memory-size 256 --query LastUpdateStatus --output text
else
  log "Creating $NAME"
  for attempt in 1 2 3 4 5 6; do
    if run lambda create-function --region "$REGION" --function-name "$NAME" \
      --runtime nodejs22.x --architectures arm64 --handler scripts/ratings/lambda.handler \
      --role "$ROLE_ARN" --memory-size 256 --timeout 20 \
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

# The address the app posts to. Open to anyone: every request proves who is
# asking with Game Center's signature, which the function checks itself.
if ! aws lambda get-function-url-config --region "$REGION" --function-name "$NAME" >/dev/null 2>&1; then
  log "Creating the function URL"
  run lambda create-function-url-config --region "$REGION" --function-name "$NAME" --auth-type NONE >/dev/null
  run lambda add-permission --region "$REGION" --function-name "$NAME" --statement-id public-url \
    --action lambda:InvokeFunctionUrl --principal '*' --function-url-auth-type NONE >/dev/null
  run lambda add-permission --region "$REGION" --function-name "$NAME" --statement-id public-url-invoke \
    --action lambda:InvokeFunction --principal '*' --invoked-via-function-url >/dev/null 2>&1 || true
fi

# Every hour: the games whose other report never came.
FUNCTION_ARN="arn:aws:lambda:$REGION:$ACCOUNT:function:$NAME"
run events put-rule --region "$REGION" --name "$RULE" --schedule-expression 'rate(1 hour)' --query RuleArn --output text >/dev/null
run events put-targets --region "$REGION" --rule "$RULE" --targets "Id=referee,Arn=$FUNCTION_ARN" >/dev/null
aws lambda add-permission --region "$REGION" --function-name "$NAME" --statement-id hourly-sweep \
  --action lambda:InvokeFunction --principal events.amazonaws.com \
  --source-arn "arn:aws:events:$REGION:$ACCOUNT:rule/$RULE" >/dev/null 2>&1 || true

URL="$(aws lambda get-function-url-config --region "$REGION" --function-name "$NAME" --query FunctionUrl --output text 2>/dev/null || echo '(none yet)')"
log "Referee at $URL"
