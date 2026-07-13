#!/usr/bin/env bash
# =============================================================================
# rollback.sh
# Rolls back the backend deployment to the previous version
#
# Usage: ./scripts/rollback.sh
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"; }
error(){ echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"; }

EKS_CLUSTER="${EKS_CLUSTER_NAME:-starttech-cluster}"
AWS_REGION="${AWS_REGION:-eu-west-3}"
DEPLOYMENT="backend-api"

main() {
  echo -e "${RED}"
  echo "╔═══════════════════════════════════════════╗"
  echo "║     StartTech Rollback                    ║"
  echo "╚═══════════════════════════════════════════╝"
  echo -e "${NC}"

  # Configure kubectl
  log "Configuring kubectl..."
  aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$EKS_CLUSTER"

  # Show current deployment status
  log "Current deployment status:"
  kubectl rollout history deployment/$DEPLOYMENT

  # Confirm rollback
  echo -e "${YELLOW}"
  read -rp "  Are you sure you want to rollback $DEPLOYMENT? (yes/no): " CONFIRM
  echo -e "${NC}"

  if [[ "$CONFIRM" != "yes" ]]; then
    warn "Rollback cancelled."
    exit 0
  fi

  # Perform rollback
  log "Rolling back $DEPLOYMENT..."
  kubectl rollout undo deployment/$DEPLOYMENT

  # Verify rollback
  log "Verifying rollback..."
  kubectl rollout status deployment/$DEPLOYMENT --timeout=300s

  # Show new status
  log "Rollback complete. Current status:"
  kubectl get pods -l app=$DEPLOYMENT
  kubectl rollout history deployment/$DEPLOYMENT

  log "Rollback successful ✓"
}

main "$@"