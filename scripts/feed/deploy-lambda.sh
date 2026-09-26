#!/usr/bin/env bash
# Put the feed collector in Lambda, or update the one that is there.
#
#   scripts/feed/deploy-lambda.sh            package, create or update, schedule
#   DRY_RUN=1 scripts/feed/deploy-lambda.sh  package only, and say what would be done
#   CODE_ONLY=1 scripts/feed/deploy-lambda.sh  the package and nothing else — what a site deploy runs
#
# What it makes, all in eu-central-1 beside the media bucket:
#   brasspawn-feed-collector       the function: Node 22 on arm64, 2 GB, 15 minutes
#   brasspawn-feed-collector       its role: read and write media/feed/ and feed-state/, write the
#                                  site's today/ and sitemap-today.xml, and nothing else
#   brasspawn-feed-every-2-hours   the EventBridge rule that runs it
#   /aws/lambda/brasspawn-feed-collector, kept for fourteen days
#
# The package is the collector's own files, chess.js, the one Stockfish build
# it uses, and the website's renderer from the last site build — the Angular
# server bundle, which renders a new story's page (pages.mjs). No SDK: S3 is
# spoken to in signed HTTP (scripts/feed/s3.mjs).
#
# The renderer must be the deployed build's: a page it renders asks for that
# build's chunks. web/scripts/deploy.sh runs this with CODE_ONLY=1 after every
# site deploy for exactly that reason.
set -euo pipefail

REGION="${FEED_REGION:-eu-central-1}"
NAME=brasspawn-feed-collector
RULE=brasspawn-feed-every-2-hours
BUCKET="${FEED_BUCKET:-brasspawn-media}"
SITE_BUCKET="${SITE_BUCKET:-brasspawn.com}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SERVER="$ROOT/web/dist/brass-pawn/server"

log() { printf '\033[36m▸\033[0m %s\n' "$*"; }
run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then printf '\033[90m  would run: aws %s\033[0m\n' "$*"; else aws "$@"; fi
}

# ------------------------------------------------------------------ package
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
mkdir -p "$BUILD/scripts/feed" "$BUILD/feed" "$BUILD/node_modules/stockfish/bin"
cp "$ROOT/scripts/engine-node.mjs" "$BUILD/scripts/"
for f in lichess words analyse collect store s3 engine-pool diagram page-story pages lambda; do
  cp "$ROOT/scripts/feed/$f.mjs" "$BUILD/scripts/feed/"
done
# The renderer, as the collector needs it — see pack-renderer.mjs.
[[ -f "$SERVER/server.mjs" ]] || { echo "No site renderer at $SERVER — build the site first (cd web && npm run build:prod)." >&2; exit 1; }
node "$ROOT/scripts/feed/pack-renderer.mjs" "$SERVER" "$BUILD/scripts/feed/site-server"
cp "$ROOT/feed/players.json" "$BUILD/feed/"
cp -R "$ROOT/node_modules/chess.js" "$BUILD/node_modules/"
cp "$ROOT/node_modules/stockfish/index.js" "$ROOT/node_modules/stockfish/package.json" \
   "$ROOT/node_modules/stockfish/Copying.txt" "$BUILD/node_modules/stockfish/"
cp "$ROOT/node_modules/stockfish/bin/stockfish-18-lite-single.js" \
   "$ROOT/node_modules/stockfish/bin/stockfish-18-lite-single.wasm" "$BUILD/node_modules/stockfish/bin/"
(cd "$BUILD" && zip -qr function.zip scripts feed node_modules)
log "Package: $(du -h "$BUILD/function.zip" | cut -f1)"
if [[ -n "${PACKAGE_OUT:-}" ]]; then
  cp "$BUILD/function.zip" "$PACKAGE_OUT"
  log "Kept a copy at $PACKAGE_OUT"
  [[ "${PACKAGE_ONLY:-0}" == "1" ]] && exit 0
fi

# A site deploy refreshes the renderer and touches nothing else — least of all
# FEED_PUBLIC, which is somebody's decision and not the site's.
if [[ "${CODE_ONLY:-0}" == "1" ]]; then
  log "Updating $NAME's code"
  run lambda update-function-code --region "$REGION" --function-name "$NAME" \
    --zip-file "fileb://$BUILD/function.zip" --query CodeSize --output text
  [[ "${DRY_RUN:-0}" == "1" ]] || aws lambda wait function-updated --region "$REGION" --function-name "$NAME"
  exit 0
fi

# What the feed shows is kept as it is unless it is said otherwise: running
# this to change the package must not quietly make every draft public again.
PUBLIC="${FEED_PUBLIC:-$(aws lambda get-function-configuration --region "$REGION" --function-name "$NAME" \
  --query Environment.Variables.FEED_PUBLIC --output text 2>/dev/null || true)}"
[[ -z "$PUBLIC" || "$PUBLIC" == "None" ]] && PUBLIC=all
# IndexNow's key is the one key file the site serves; it is public by design.
INDEXNOW_KEY="$(ls "$ROOT/web/public" | grep -E '^[a-f0-9-]{8,128}\.txt$' | head -1 | sed 's/\.txt$//')"

ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
ROLE_ARN="arn:aws:iam::$ACCOUNT:role/$NAME"

# --------------------------------------------------------------------- role
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
# Listing is allowed so that a key that does not exist yet answers 404 rather
# than 403 — the collector asks for its state before there is any.
run iam put-role-policy --role-name "$NAME" --policy-name feed-bucket --policy-document "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    { \"Effect\": \"Allow\", \"Action\": [\"s3:GetObject\", \"s3:PutObject\"],
      \"Resource\": [\"arn:aws:s3:::$BUCKET/media/feed/*\", \"arn:aws:s3:::$BUCKET/feed-state/*\"] },
    { \"Effect\": \"Allow\", \"Action\": \"s3:ListBucket\", \"Resource\": \"arn:aws:s3:::$BUCKET\" },
    { \"Effect\": \"Allow\", \"Action\": \"s3:PutObject\",
      \"Resource\": [\"arn:aws:s3:::$SITE_BUCKET/today/*\", \"arn:aws:s3:::$SITE_BUCKET/sitemap-today.xml\"] }
  ]
}"
# A new role takes a few seconds to be assumable by Lambda.
[[ "${CREATED_ROLE:-0}" == "1" && "${DRY_RUN:-0}" != "1" ]] && sleep 12

# ----------------------------------------------------------------- function
ENVIRONMENT="Variables={FEED_BUCKET=$BUCKET,FEED_REGION=$REGION,FEED_PUBLIC=$PUBLIC,FEED_WORKERS=1,SITE_BUCKET=$SITE_BUCKET,SITE_REGION=$REGION,INDEXNOW_KEY=$INDEXNOW_KEY}"
if aws lambda get-function --region "$REGION" --function-name "$NAME" >/dev/null 2>&1; then
  log "Updating $NAME"
  run lambda update-function-code --region "$REGION" --function-name "$NAME" \
    --zip-file "fileb://$BUILD/function.zip" --query CodeSize --output text
  [[ "${DRY_RUN:-0}" == "1" ]] || aws lambda wait function-updated --region "$REGION" --function-name "$NAME"
  run lambda update-function-configuration --region "$REGION" --function-name "$NAME" \
    --environment "$ENVIRONMENT" --timeout 900 --memory-size 2048 --query LastUpdateStatus --output text
else
  log "Creating $NAME"
  # A role made a moment ago can take longer to be assumable than the pause
  # above allows. Lambda refuses the function until it is, and a few seconds
  # later accepts it — so it is asked again rather than the deploy failing.
  for attempt in 1 2 3 4 5 6; do
    if run lambda create-function --region "$REGION" --function-name "$NAME" \
      --runtime nodejs22.x --architectures arm64 --handler scripts/feed/lambda.handler \
      --role "$ROLE_ARN" --memory-size 2048 --timeout 900 \
      --environment "$ENVIRONMENT" \
      --description "Brass Pawn daily feed: finished top-broadcast games into media/feed/v1" \
      --zip-file "fileb://$BUILD/function.zip" --query FunctionArn --output text; then
      break
    fi
    [[ "$attempt" == "6" ]] && { echo "Could not create $NAME" >&2; exit 1; }
    sleep 5
  done
  [[ "${DRY_RUN:-0}" == "1" ]] || aws lambda wait function-active-v2 --region "$REGION" --function-name "$NAME"
fi

# One run at a time: two collectors reading the same state would each write
# a version that lost the other's stories. And no automatic retry of a failed
# run — the next scheduled one is two hours away and starts from the state.
run lambda put-function-concurrency --region "$REGION" --function-name "$NAME" \
  --reserved-concurrent-executions 1 >/dev/null
run lambda put-function-event-invoke-config --region "$REGION" --function-name "$NAME" \
  --maximum-retry-attempts 0 >/dev/null

# --------------------------------------------------------------------- logs
run logs create-log-group --region "$REGION" --log-group-name "/aws/lambda/$NAME" 2>/dev/null || true
run logs put-retention-policy --region "$REGION" --log-group-name "/aws/lambda/$NAME" --retention-in-days 14

# ----------------------------------------------------------------- schedule
FUNCTION_ARN="arn:aws:lambda:$REGION:$ACCOUNT:function:$NAME"
RULE_ARN="$(run events put-rule --region "$REGION" --name "$RULE" --schedule-expression 'rate(2 hours)' \
  --description 'Run the Brass Pawn feed collector' --query RuleArn --output text)"
run lambda add-permission --region "$REGION" --function-name "$NAME" --statement-id "$RULE" \
  --action lambda:InvokeFunction --principal events.amazonaws.com \
  --source-arn "arn:aws:events:$REGION:$ACCOUNT:rule/$RULE" >/dev/null 2>&1 || true
run events put-targets --region "$REGION" --rule "$RULE" --targets "Id=collector,Arn=$FUNCTION_ARN" >/dev/null
log "Scheduled every two hours. Run it now with:"
echo "  aws lambda invoke --region $REGION --function-name $NAME --invocation-type Event /dev/null"
