#!/usr/bin/env bash
# =============================================================================
# deploy-backend.sh
# Builds Docker image, pushes to ECR, and deploys to EKS
#
# Usage: ./scripts/deploy-backend.sh
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
BACKEND_DIR="$ROOT_DIR/backend"
K8S_DIR="$ROOT_DIR/k8s"

AWS_REGION="${AWS_REGION:-eu-west-3}"
ECR_REGISTRY="${ECR_REGISTRY:-}"
ECR_REPOSITORY="starttech-backend-api"
EKS_CLUSTER="${EKS_CLUSTER_NAME:-starttech-cluster}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD)}"

# ─── Preflight Checks ─────────────────────────────────────────────────────────
check_prerequisites() {
  log "Running preflight checks..."

  command -v docker &>/dev/null   || error "Docker not installed."
  command -v aws &>/dev/null      || error "AWS CLI not installed."
  command -v kubectl &>/dev/null  || error "kubectl not installed."
  command -v go &>/dev/null       || error "Go not installed."

  [[ -z "$ECR_REGISTRY" ]] && error "ECR_REGISTRY environment variable not set."

  info "Image tag: $IMAGE_TAG"
  log "Preflight checks passed ✓"
}

# ─── Run Tests ────────────────────────────────────────────────────────────────
run_tests() {
  log "Running Go tests..."
  cd "$BACKEND_DIR"
  go test ./... -v -cover
  log "Tests passed ✓"
}

# ─── Build and Push ───────────────────────────────────────────────────────────
build_and_push() {
  log "Authenticating to ECR..."
  aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "$ECR_REGISTRY"

  IMAGE_URI="$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
  LATEST_URI="$ECR_REGISTRY/$ECR_REPOSITORY:latest"

  log "Building Docker image..."
  docker build \
    -t "$IMAGE_URI" \
    -t "$LATEST_URI" \
    "$BACKEND_DIR"

  log "Pushing to ECR..."
  docker push "$IMAGE_URI"
  docker push "$LATEST_URI"

  info "Pushed: $IMAGE_URI"
  log "Build and push complete ✓"
}

# ─── Deploy to EKS ────────────────────────────────────────────────────────────
deploy_to_eks() {
  log "Configuring kubectl..."
  aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$EKS_CLUSTER"

  log "Updating deployment manifest with image: $IMAGE_URI"
  sed -i.bak "s|IMAGE_PLACEHOLDER|$IMAGE_URI|g" "$K8S_DIR/deployment.yaml"

  log "Applying Kubernetes manifests..."
  kubectl apply -f "$K8S_DIR/"

  log "Verifying rollout..."
  kubectl rollout status deployment/backend-api --timeout=300s

  log "Deployment complete ✓"

  # Restore original manifest
  mv "$K8S_DIR/deployment.yaml.bak" "$K8S_DIR/deployment.yaml"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════╗"
  echo "║     StartTech Backend Deployment          ║"
  echo "╚═══════════════════════════════════════════╝"
  echo -e "${NC}"

  check_prerequisites
  run_tests
  build_and_push
  deploy_to_eks

  echo -e "${GREEN}"
  echo "  ════════════════════════════════════════"
  echo "  Backend deployed successfully!"
  echo "  Image    : $IMAGE_URI"
  echo "  Cluster  : $EKS_CLUSTER"
  echo "  ════════════════════════════════════════"
  echo -e "${NC}"
}

main "$@"