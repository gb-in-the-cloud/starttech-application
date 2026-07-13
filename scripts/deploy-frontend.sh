#!/usr/bin/env bash
# =============================================================================
# deploy-frontend.sh
# Builds and deploys the React frontend to S3 and invalidates CloudFront cache
#
# Usage: ./scripts/deploy-frontend.sh
# =============================================================================

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"; }
error(){ echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"; }

# ─── Config ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$ROOT_DIR/frontend"

S3_BUCKET="${S3_BUCKET_NAME:-}"
CLOUDFRONT_ID="${CLOUDFRONT_DISTRIBUTION_ID:-}"
AWS_REGION="${AWS_REGION:-eu-west-3}"

# ─── Preflight Checks ─────────────────────────────────────────────────────────
check_prerequisites() {
  log "Running preflight checks..."

  if ! command -v node &>/dev/null; then
    error "Node.js not installed."
  fi
  info "Node.js: $(node --version)"

  if ! command -v npm &>/dev/null; then
    error "npm not installed."
  fi
  info "npm: $(npm --version)"

  if ! command -v aws &>/dev/null; then
    error "AWS CLI not installed."
  fi

  if [[ -z "$S3_BUCKET" ]]; then
    error "S3_BUCKET_NAME environment variable not set."
  fi

  if [[ -z "$CLOUDFRONT_ID" ]]; then
    error "CLOUDFRONT_DISTRIBUTION_ID environment variable not set."
  fi

  log "Preflight checks passed ✓"
}

# ─── Build ────────────────────────────────────────────────────────────────────
build_frontend() {
  log "Building React frontend..."
  cd "$FRONTEND_DIR"

  # Install dependencies
  npm ci

  # Security scan
  log "Running security scan..."
  npm audit --audit-level=high

  # Build
  log "Compiling static site..."
  npm run build

  log "Build complete ✓"
}

# ─── Deploy ───────────────────────────────────────────────────────────────────
deploy_to_s3() {
  log "Uploading to S3 bucket: $S3_BUCKET"

  # Sync all files except index.html with long cache
  aws s3 sync "$FRONTEND_DIR/build/" "s3://$S3_BUCKET" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "index.html" \
    --region "$AWS_REGION"

  # Upload index.html with no-cache
  aws s3 cp "$FRONTEND_DIR/build/index.html" "s3://$S3_BUCKET/index.html" \
    --cache-control "no-cache, no-store, must-revalidate" \
    --region "$AWS_REGION"

  log "Upload complete ✓"
}

# ─── Invalidate CloudFront ────────────────────────────────────────────────────
invalidate_cloudfront() {
  log "Invalidating CloudFront cache..."

  INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$CLOUDFRONT_ID" \
    --paths "/*" \
    --query "Invalidation.Id" \
    --output text)

  info "Invalidation ID: $INVALIDATION_ID"

  log "Waiting for invalidation to complete..."
  aws cloudfront wait invalidation-completed \
    --distribution-id "$CLOUDFRONT_ID" \
    --id "$INVALIDATION_ID"

  log "CloudFront cache invalidated ✓"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════╗"
  echo "║     StartTech Frontend Deployment         ║"
  echo "╚═══════════════════════════════════════════╝"
  echo -e "${NC}"

  check_prerequisites
  build_frontend
  deploy_to_s3
  invalidate_cloudfront

  echo -e "${GREEN}"
  echo "  ════════════════════════════════════════"
  echo "  Frontend deployed successfully!"
  echo "  S3 Bucket  : $S3_BUCKET"
  echo "  CloudFront : $CLOUDFRONT_ID"
  echo "  ════════════════════════════════════════"
  echo -e "${NC}"
}

main "$@"