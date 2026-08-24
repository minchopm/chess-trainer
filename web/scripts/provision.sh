#!/usr/bin/env bash
#
# Create (or re-assert) the AWS infrastructure this site is served from.
#
# Run once. It is idempotent, so running it again after an accident repairs the
# pieces rather than duplicating them — but it is not a deploy: it moves no
# files. Use scripts/deploy.sh for that.
#
# What it makes, in order:
#
#   1. a private S3 bucket named after the hostname, encrypted, no public access
#   2. an ACM certificate in us-east-1 (CloudFront will not read one anywhere
#      else) for the bare host and its www form, validated through Route53
#   3. an Origin Access Control, so the bucket can stay private
#   4. a CloudFront function that turns /privacy into /privacy/index.html —
#      the S3 REST origin does no index-document resolution of its own, and
#      this site is prerendered into directories rather than being a SPA
#   5. a response-headers policy: HSTS, CSP, and the rest of the hardening
#   6. the distribution, with 403 and 404 both answered by the real /404.html
#   7. a bucket policy naming that distribution, and nothing else
#   8. Route53 A and AAAA aliases for both names
#
#   ./scripts/provision.sh            create anything missing
#   DRY_RUN=1 ./scripts/provision.sh  print what it would do
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
DRY_RUN="${DRY_RUN:-0}"

HOST="${HOST:-brasspawn.com}"
BUCKET="${BUCKET:-$HOST}"
# The films and the screenshots get their own bucket, behind the same
# distribution on a /media/* behaviour. Same origin for the browser, separate
# lifecycle for us: a site deploy cannot reach half a gigabyte it never built.
MEDIA_BUCKET="${MEDIA_BUCKET:-brasspawn-media}"
# Used to name every resource after the site, so a second property in this
# account cannot collide with this one.
SLUG="${HOST//./-}"
REGION="${REGION:-eu-central-1}"
CF_ZONE=Z2FDTNDATAQYW2                                # CloudFront's, and fixed.
CACHING_OPTIMIZED=658327ea-f89d-4fab-a63d-7e88639e58f6

log()  { printf '\033[36m▸\033[0m %s\n' "$*"; }
skip() { printf '\033[90m  already there: %s\033[0m\n' "$*"; }
die()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

[[ -f "$ENV_FILE" ]] || die "No env file at $ENV_FILE."
set -a; source "$ENV_FILE"; set +a

AWS_BIN="${AWS_BIN:-$(command -v aws || true)}"
[[ -n "$AWS_BIN" ]] || die "AWS CLI not found."

aws_do() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '\033[90m  would run: aws %s\033[0m\n' "$*"
    return 0
  fi
  AWS_ACCESS_KEY_ID="$NG_DEPLOY_AWS_ACCESS_KEY_ID" \
  AWS_SECRET_ACCESS_KEY="$NG_DEPLOY_AWS_SECRET_ACCESS_KEY" \
    "$AWS_BIN" "$@"
}
# Reads never change anything, so they run even under DRY_RUN — otherwise a dry
# run cannot tell what already exists and prints a fiction.
aws_read() {
  AWS_ACCESS_KEY_ID="$NG_DEPLOY_AWS_ACCESS_KEY_ID" \
  AWS_SECRET_ACCESS_KEY="$NG_DEPLOY_AWS_SECRET_ACCESS_KEY" \
    "$AWS_BIN" "$@"
}

ACCOUNT="$(aws_read sts get-caller-identity --query Account --output text)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The zone is looked up from the host rather than pasted in, so moving the site
# to another domain is one variable rather than a hunt through the script. The
# apex is the last two labels, which is right for every domain this project
# will use and wrong for the likes of co.uk — worth knowing before reusing it.
if [[ -z "${HOSTED_ZONE:-}" ]]; then
  APEX="$(echo "$HOST" | awk -F. '{print $(NF-1)"."$NF}')"
  HOSTED_ZONE="$(aws_read route53 list-hosted-zones-by-name --dns-name "$APEX." \
    --query "HostedZones[?Name=='$APEX.'].Id | [0]" --output text | sed 's|/hostedzone/||')"
  [[ -n "$HOSTED_ZONE" && "$HOSTED_ZONE" != "None" ]] || die "No Route53 hosted zone for $APEX."
  log "Hosted zone for $APEX: $HOSTED_ZONE"
fi

# ------------------------------------------------------------------- 1. bucket

if aws_read s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  skip "s3://$BUCKET"
else
  log "Creating s3://$BUCKET in $REGION…"
  aws_do s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration "LocationConstraint=$REGION"
  aws_do s3api put-public-access-block --bucket "$BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  aws_do s3api put-bucket-encryption --bucket "$BUCKET" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
fi

if aws_read s3api head-bucket --bucket "$MEDIA_BUCKET" >/dev/null 2>&1; then
  skip "s3://$MEDIA_BUCKET"
else
  log "Creating s3://$MEDIA_BUCKET in $REGION…"
  aws_do s3api create-bucket --bucket "$MEDIA_BUCKET" --region "$REGION" \
    --create-bucket-configuration "LocationConstraint=$REGION"
  aws_do s3api put-public-access-block --bucket "$MEDIA_BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=true
  aws_do s3api put-bucket-encryption --bucket "$MEDIA_BUCKET" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
fi

# -------------------------------------------------------------- 2. certificate

CERT="$(aws_read acm list-certificates --region us-east-1 \
  --query "CertificateSummaryList[?DomainName=='$HOST'].CertificateArn | [0]" --output text)"

if [[ -n "$CERT" && "$CERT" != "None" ]]; then
  skip "certificate $CERT"
else
  log "Requesting a certificate for $HOST and www.$HOST…"
  CERT="$(aws_do acm request-certificate --region us-east-1 \
    --domain-name "$HOST" --subject-alternative-names "www.$HOST" \
    --validation-method DNS --tags Key=Project,Value="$SLUG" \
    --query CertificateArn --output text)"

  if [[ "$DRY_RUN" != "1" ]]; then
    log "Writing the DNS validation records…"
    # ACM fills these in a moment after the request, not instantly.
    for _ in $(seq 1 12); do
      aws_read acm describe-certificate --region us-east-1 --certificate-arn "$CERT" \
        --query 'Certificate.DomainValidationOptions[].ResourceRecord' --output json > "$TMP/val.json"
      grep -q '"Name"' "$TMP/val.json" && break
      sleep 5
    done

    python3 - "$TMP" <<'PY'
import json, sys
tmp = sys.argv[1]
seen, changes = set(), []
for r in json.load(open(tmp + '/val.json')) or []:
    if not r or r['Name'] in seen: continue
    seen.add(r['Name'])
    changes.append({'Action': 'UPSERT', 'ResourceRecordSet': {
        'Name': r['Name'], 'Type': r['Type'], 'TTL': 300,
        'ResourceRecords': [{'Value': r['Value']}]}})
json.dump({'Comment': 'ACM validation', 'Changes': changes}, open(tmp + '/valchange.json', 'w'))
PY
    aws_do route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE" \
      --change-batch "file://$TMP/valchange.json" --query 'ChangeInfo.Status' --output text

    log "Waiting for the certificate to be issued…"
    aws_do acm wait certificate-validated --region us-east-1 --certificate-arn "$CERT"
  fi
fi
log "Certificate: $CERT"

# ---------------------------------------------------------------------- 3. OAC

OAC="$(aws_read cloudfront list-origin-access-controls \
  --query "OriginAccessControlList.Items[?Name=='$HOST'].Id | [0]" --output text)"
if [[ -n "$OAC" && "$OAC" != "None" ]]; then
  skip "origin access control $OAC"
else
  log "Creating the origin access control…"
  OAC="$(aws_do cloudfront create-origin-access-control --origin-access-control-config \
    "{\"Name\":\"$HOST\",\"Description\":\"OAC for the $HOST bucket\",\"SigningProtocol\":\"sigv4\",\"SigningBehavior\":\"always\",\"OriginAccessControlOriginType\":\"s3\"}" \
    --query 'OriginAccessControl.Id' --output text)"
fi
log "Origin access control: $OAC"

MEDIA_OAC="$(aws_read cloudfront list-origin-access-controls \
  --query "OriginAccessControlList.Items[?Name=='$MEDIA_BUCKET'].Id | [0]" \
  --output text 2>/dev/null || true)"
if [[ -z "$MEDIA_OAC" || "$MEDIA_OAC" == "None" ]]; then
  log "Creating the media origin access control…"
  MEDIA_OAC="$(aws_do cloudfront create-origin-access-control \
    --origin-access-control-config \
    "Name=$MEDIA_BUCKET,Description=Media bucket for $HOST,SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3" \
    --query 'OriginAccessControl.Id' --output text)"
fi
log "Media origin access control: $MEDIA_OAC"

# ----------------------------------------------------------------- 4. function

FN_NAME="$SLUG-router"
# The function's source lives in scripts/cloudfront-router.js rather than in a
# heredoc here, because it is also edited by hand when the routing changes and
# two copies of a rewrite rule is one copy too many.
cp "$ROOT_DIR/scripts/cloudfront-router.js" "$TMP/router.js"

if aws_read cloudfront describe-function --name "$FN_NAME" >/dev/null 2>&1; then
  skip "function $FN_NAME"
else
  log "Creating and publishing the URL-rewrite function…"
  aws_do cloudfront create-function --name "$FN_NAME" \
    --function-config "{\"Comment\":\"Prerendered directory index; /en to the root\",\"Runtime\":\"cloudfront-js-2.0\"}" \
    --function-code "fileb://$TMP/router.js" >/dev/null
  if [[ "$DRY_RUN" != "1" ]]; then
    etag="$(aws_read cloudfront describe-function --name "$FN_NAME" --query ETag --output text)"
    aws_do cloudfront publish-function --name "$FN_NAME" --if-match "$etag" >/dev/null
  fi
fi
FN_ARN="arn:aws:cloudfront::$ACCOUNT:function/$FN_NAME"

# ---------------------------------------------------------- 5. header policy

# Everything the site loads is first-party, so the content policy can name a
# single origin. The two 'unsafe-inline' entries are unavoidable and narrow:
# Angular writes style attributes for the scroll-driven animation, and the
# structured data is an inline script in every prerendered page.
CSP="default-src 'self'; base-uri 'self'; object-src 'none'; frame-ancestors 'none'; form-action 'none'; img-src 'self' data:; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self'; manifest-src 'self'; media-src 'self'; upgrade-insecure-requests"
HEADERS_NAME="$SLUG-security-headers"

HEADERS="$(aws_read cloudfront list-response-headers-policies --type custom \
  --query "ResponseHeadersPolicyList.Items[?ResponseHeadersPolicy.ResponseHeadersPolicyConfig.Name=='$HEADERS_NAME'].ResponseHeadersPolicy.Id | [0]" \
  --output text 2>/dev/null || true)"

if [[ -n "$HEADERS" && "$HEADERS" != "None" ]]; then
  skip "response headers policy $HEADERS"
else
  log "Creating the response headers policy…"
  cat > "$TMP/headers.json" <<JSON
{
  "Name": "$HEADERS_NAME",
  "Comment": "Security headers for $HOST",
  "SecurityHeadersConfig": {
    "StrictTransportSecurity": { "Override": true, "AccessControlMaxAgeSec": 63072000, "IncludeSubdomains": true, "Preload": false },
    "ContentTypeOptions": { "Override": true },
    "FrameOptions": { "Override": true, "FrameOption": "DENY" },
    "ReferrerPolicy": { "Override": true, "ReferrerPolicy": "strict-origin-when-cross-origin" },
    "XSSProtection": { "Override": true, "Protection": true, "ModeBlock": true },
    "ContentSecurityPolicy": { "Override": true, "ContentSecurityPolicy": "$CSP" }
  },
  "CustomHeadersConfig": { "Quantity": 1, "Items": [
    { "Header": "Permissions-Policy", "Value": "camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()", "Override": true } ]}
}
JSON
  HEADERS="$(aws_do cloudfront create-response-headers-policy \
    --response-headers-policy-config "file://$TMP/headers.json" \
    --query 'ResponseHeadersPolicy.Id' --output text)"
fi
log "Response headers policy: $HEADERS"

# ------------------------------------------------------------- 6. distribution

DIST="$(aws_read cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Aliases.Items, \`$HOST\`)].Id | [0]" --output text)"

if [[ -n "$DIST" && "$DIST" != "None" ]]; then
  skip "distribution $DIST"
else
  log "Creating the distribution…"
  cat > "$TMP/dist.json" <<JSON
{
  "CallerReference": "$HOST-$(date +%s)",
  "Aliases": { "Quantity": 2, "Items": ["$HOST", "www.$HOST"] },
  "DefaultRootObject": "index.html",
  "Origins": { "Quantity": 1, "Items": [{
      "Id": "$SLUG-s3",
      "DomainName": "$BUCKET.s3.$REGION.amazonaws.com",
      "OriginPath": "", "CustomHeaders": { "Quantity": 0 },
      "S3OriginConfig": { "OriginAccessIdentity": "" },
      "OriginAccessControlId": "$OAC",
      "ConnectionAttempts": 3, "ConnectionTimeout": 10,
      "OriginShield": { "Enabled": false } }]},
  "DefaultCacheBehavior": {
    "TargetOriginId": "$SLUG-s3",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": { "Quantity": 2, "Items": ["HEAD","GET"],
      "CachedMethods": { "Quantity": 2, "Items": ["HEAD","GET"] } },
    "Compress": true,
    "CachePolicyId": "$CACHING_OPTIMIZED",
    "ResponseHeadersPolicyId": "$HEADERS",
    "FunctionAssociations": { "Quantity": 1, "Items": [
      { "FunctionARN": "$FN_ARN", "EventType": "viewer-request" } ] },
    "LambdaFunctionAssociations": { "Quantity": 0 },
    "FieldLevelEncryptionId": "", "SmoothStreaming": false },
  "CacheBehaviors": { "Quantity": 0 },
  "CustomErrorResponses": { "Quantity": 2, "Items": [
    { "ErrorCode": 403, "ResponsePagePath": "/404.html", "ResponseCode": "404", "ErrorCachingMinTTL": 10 },
    { "ErrorCode": 404, "ResponsePagePath": "/404.html", "ResponseCode": "404", "ErrorCachingMinTTL": 10 } ]},
  "Comment": "$HOST — informational site",
  "Logging": { "Enabled": false, "IncludeCookies": false, "Bucket": "", "Prefix": "" },
  "PriceClass": "PriceClass_All", "Enabled": true,
  "ViewerCertificate": { "ACMCertificateArn": "$CERT", "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021", "CloudFrontDefaultCertificate": false },
  "Restrictions": { "GeoRestriction": { "RestrictionType": "none", "Quantity": 0 } },
  "HttpVersion": "http2and3", "IsIPV6Enabled": true
}
JSON
  DIST="$(aws_do cloudfront create-distribution --distribution-config "file://$TMP/dist.json" \
    --query 'Distribution.Id' --output text)"
fi
log "Distribution: $DIST"

# The media origin is attached after the fact rather than written into the
# creation template, because this has to work on the distribution that already
# exists as well as on one made a minute ago.
log "Asserting the media origin and its /media/* behaviour…"
if [[ "$DRY_RUN" == "1" ]]; then
  printf '\033[90m  would add origin %s and behaviour /media/* to %s\033[0m\n' \
    "$MEDIA_BUCKET" "$DIST"
else
  DIST="$DIST" MEDIA_BUCKET="$MEDIA_BUCKET" MEDIA_OAC="$MEDIA_OAC" REGION="$REGION" \
  AWS_ACCESS_KEY_ID="$NG_DEPLOY_AWS_ACCESS_KEY_ID" \
  AWS_SECRET_ACCESS_KEY="$NG_DEPLOY_AWS_SECRET_ACCESS_KEY" \
  AWS_DEFAULT_REGION=us-east-1 \
    python3 "$ROOT_DIR/scripts/media-behaviour.py"
fi

# --------------------------------------------------------------- 7. and 8.

log "Asserting the bucket policy (CloudFront may read, nobody else)…"
cat > "$TMP/policy.json" <<JSON
{ "Version": "2008-10-17", "Statement": [{
    "Sid": "AllowCloudFrontServicePrincipalReadOnly",
    "Effect": "Allow", "Principal": { "Service": "cloudfront.amazonaws.com" },
    "Action": "s3:GetObject", "Resource": "arn:aws:s3:::$BUCKET/*",
    "Condition": { "StringEquals": {
      "AWS:SourceArn": "arn:aws:cloudfront::$ACCOUNT:distribution/$DIST" } } }]}
JSON
aws_do s3api put-bucket-policy --bucket "$BUCKET" --policy "file://$TMP/policy.json"

sed "s|:::$BUCKET/|:::$MEDIA_BUCKET/|" "$TMP/policy.json" > "$TMP/media-policy.json"
aws_do s3api put-bucket-policy --bucket "$MEDIA_BUCKET" --policy "file://$TMP/media-policy.json"

CF_DOMAIN="$(aws_read cloudfront get-distribution --id "$DIST" \
  --query 'Distribution.DomainName' --output text 2>/dev/null || echo "$DIST.cloudfront.net")"

log "Asserting the DNS aliases…"
python3 - "$TMP" "$HOST" "$CF_DOMAIN" "$CF_ZONE" <<'PY'
import json, sys
tmp, host, target, zone = sys.argv[1:5]
changes = [
    {'Action': 'UPSERT', 'ResourceRecordSet': {
        'Name': f'{name}.', 'Type': t,
        'AliasTarget': {'HostedZoneId': zone, 'DNSName': f'{target}.',
                        'EvaluateTargetHealth': False}}}
    for name in (host, f'www.{host}') for t in ('A', 'AAAA')
]
json.dump({'Comment': f'{host} -> CloudFront', 'Changes': changes},
          open(tmp + '/dns.json', 'w'))
PY
aws_do route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE" \
  --change-batch "file://$TMP/dns.json" --query 'ChangeInfo.Status' --output text

cat <<SUMMARY

  Bucket        s3://$BUCKET  ($REGION, private)
  Certificate   $CERT
  OAC           $OAC
  Headers       $HEADERS
  Function      $FN_NAME
  Distribution  $DIST  ($CF_DOMAIN)
  Serving       https://$HOST  and  https://www.$HOST

  Put CLOUDFRONT_DISTRIBUTION_ID=$DIST in .env to skip the alias lookup
  on every deploy. Then: npm run deploy

SUMMARY
