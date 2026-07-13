#!/usr/bin/env bash
# =============================================================================
# health-check.sh
# Checks the health of the backend API and Kubernetes pods
#
# Usage: ./scripts/health-check.sh
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error(){ echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"; }

CLOUDFRONT_DOMAIN="${CLOUDFRONT_DOMAIN:-}"
EKS_CLUSTER="${EKS_CLUSTER_NAME:-starttech-cluster}"
AWS_REGION="${AWS_REGION:-eu-west-3}"

# ─── Check Kubernetes Pods ────────────────────────────────────────────────────
check_pods() {
  log "Checking Kubernetes pods..."

  aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$EKS_CLUSTER" \
    2>/dev/null

  kubectl get pods -l app=backend-api
  kubectl get services
  kubectl get ingress

  # Check if all pods are running
  READY=$(kubectl get deployment backend-api \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

  DESIRED=$(kubectl get deployment backend-api \
    -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

  if [[ "$READY" == "$DESIRED" ]]; then
    log "All pods running: $READY/$DESIRED ✓"
  else
    error "Pods not ready: $READY/$DESIRED"
  fi
}

# ─── Check API Health ─────────────────────────────────────────────────────────
check_api_health() {
  if [[ -z "$CLOUDFRONT_DOMAIN" ]]; then
    info "CLOUDFRONT_DOMAIN not set — skipping API health check"
    return
  fi

  log "Checking API health endpoint..."

  HEALTH_URL="https://$CLOUDFRONT_DOMAIN/health"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || echo "000")

  if [[ "$STATUS" == "200" ]]; then
    log "API health check passed: $HEALTH_URL → $STATUS ✓"
  else
    error "API health check failed: $HEALTH_URL → $STATUS"
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════╗"
  echo "║     StartTech Health Check                ║"
  echo "╚═══════════════════════════════════════════╝"
  echo -e "${NC}"

  check_pods
  check_api_health

  log "All health checks passed ✓"
}

main "$@"