# starttech-application
This repository contains the application source code and deploy manifests.
# StartTech Application

The application layer of the StartTech platform — a full-stack Todo application with a React frontend and Go backend, containerised and deployed to AWS EKS via GitHub Actions CI/CD pipelines.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Tech Stack](#3-tech-stack)
4. [CI/CD Pipelines](#4-cicd-pipelines)
5. [Kubernetes Manifests](#5-kubernetes-manifests)
6. [Getting Started](#6-getting-started)
7. [GitHub Secrets](#7-github-secrets)
8. [Scripts](#8-scripts)

---

## 1. Project Overview

This repository contains the source code and deployment configuration for the StartTech application:

- **Frontend** — React/TypeScript SPA built with Vite, served via S3 and CloudFront
- **Backend** — Go REST API using Gin, MongoDB, Redis, and JWT authentication
- **Infrastructure** — Kubernetes manifests for EKS deployment
- **CI/CD** — GitHub Actions pipelines for automated testing, building, and deployment

---

## 2. Repository Structure

```
starttech-application/
├── .github/
│   └── workflows/
│       ├── frontend-ci-cd.yml    # React build → S3 → CloudFront
│       └── backend-ci-cd.yml     # Go test → Docker → ECR → EKS
├── frontend/                     # React/TypeScript/Vite source
│   ├── src/
│   │   ├── components/
│   │   ├── routes/
│   │   ├── hooks/
│   │   └── types/
│   ├── package.json
│   └── vite.config.ts
├── backend/                      # Go backend source
│   ├── MuchToDo/
│   │   ├── cmd/api/main.go
│   │   ├── internal/
│   │   │   ├── auth/
│   │   │   ├── cache/
│   │   │   ├── config/
│   │   │   ├── database/
│   │   │   ├── handlers/
│   │   │   ├── middleware/
│   │   │   └── routes/
│   │   ├── go.mod
│   │   └── go.sum
│   └── Dockerfile
├── k8s/
│   ├── deployment.yaml           # RollingUpdate deployment
│   ├── service.yaml              # ClusterIP service
│   ├── ingress.yaml              # ALB ingress
│   └── configmap.yaml            # Non-sensitive config
├── scripts/
│   ├── deploy-frontend.sh
│   ├── deploy-backend.sh
│   ├── health-check.sh
│   └── rollback.sh
└── README.md
```

---

## 3. Tech Stack

### Frontend
| Technology            | Purpose            |
| React 18 + TypeScript | UI framework       |
| Vite                  |  Build tool        |
| TanStack Router       | Client-side routing|
| AWS S3                | Static file hosting|
| CloudFront            | CDN and HTTPS      |

### Backend
| Technology            | Purpose                 |
| Go 1.25               | Language                |
| Gin                   | HTTP framework          |
| MongoDB Atlas         | Database                |
| Redis (ElastiCache)   | Caching                 |
| JWT                   | Authentication          |
| Docker                | Containerisation        |
| Amazon ECR            | Container registry      |
| Amazon EKS            | Container orchestration |

---

## 4. CI/CD Pipelines

### Frontend Pipeline (`frontend-ci-cd.yml`)

Triggers on changes to `frontend/` pushed to `main`.

```
Push to main
      │
      ▼
Install dependencies (npm ci)
      │
      ▼
Security scan (npm audit)
      │
      ▼
Build static site (npm run build)
      │
      ▼
Upload to S3 (aws s3 sync)
      │
      ▼
Invalidate CloudFront cache
```

### Backend Pipeline (`backend-ci-cd.yml`)

Triggers on changes to `backend/` or `k8s/` pushed to `main`.

```
Push to main
      │
      ▼
Run Go tests (go test ./...)
      │
      ▼
Build Docker image (tagged with git SHA)
      │
      ▼
Scan for vulnerabilities (Trivy)
      │
      ▼
Push to Amazon ECR
      │
      ▼
Update deployment manifest with image tag
      │
      ▼
kubectl apply -f k8s/
      │
      ▼
kubectl rollout status deployment/backend-api
```

---

## 5. Kubernetes Manifests

### Deployment (`k8s/deployment.yaml`)

- 2 replicas for high availability
- Rolling update strategy — zero downtime deployments
- Liveness and readiness probes on `/health`
- Resource limits: 500m CPU, 256Mi memory

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

### Service (`k8s/service.yaml`)

- Type: ClusterIP
- Port 80 → container port 8080

### Ingress (`k8s/ingress.yaml`)

- AWS Load Balancer Controller (ALB)
- Internet-facing scheme
- Routes `/api` and `/health` to the backend service

### ConfigMap (`k8s/configmap.yaml`)

- Non-sensitive configuration (Redis host, DB name, log level)
- Sensitive values (MONGO_URI, JWT_SECRET_KEY) managed via Kubernetes Secrets created outside of version control

---

## 6. Getting Started

### Prerequisites

```bash
node --version    # >= 20
go version        # >= 1.25
docker --version
kubectl version
aws --version
```

### Frontend Local Development

```bash
cd frontend
npm install
npm run dev
```

### Backend Local Development

```bash
cd backend/MuchToDo

# Create app.env file
cat > app.env << 'EOF'
PORT=8080
SERVER_PORT=8080
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/starttech
DB_NAME=starttech
JWT_SECRET_KEY=your-secret-key
JWT_EXPIRATION_HOURS=72
LOG_LEVEL=INFO
LOG_FORMAT=json
ENABLE_CACHE=false
EOF

# Run the app
go run cmd/api/main.go
```

### Docker Build

```bash
cd backend
docker build -t starttech-backend-api:latest .
docker run -p 8080:8080 --env-file MuchToDo/app.env starttech-backend-api:latest
```

---

## 7. GitHub Secrets

Set these in **Settings → Secrets and variables → Actions** and **Settings → Environments → production**:

| Secret                  | Description                         |
| `AWS_ACCESS_KEY_ID`     | AWS access key                      |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key                      |
| `MONGO_URI`             | MongoDB Atlas connection string     |
| `JWT_SECRET_KEY`        | JWT signing secret                  |

Set these as **Repository Variables** in **Settings → Secrets and variables → Actions → Variables**:
 
| Variable                     | Value                                          |
| `AWS_REGION`                 | `eu-west-3`                                    |
| `ECR_REGISTRY`               | `262945455354.dkr.ecr.eu-west-3.amazonaws.com` |
| `ECR_REPOSITORY`             | `starttech-backend-api`                        |
| `EKS_CLUSTER_NAME`           | `starttech-cluster`                            |
| `S3_BUCKET_NAME`             | `starttech-frontend-bucket-paris-2026`         |
| `CLOUDFRONT_DISTRIBUTION_ID` | CloudFront distribution ID                     |

---

## 8. Scripts

All scripts are in `scripts/` and require environment variables to be set.

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy frontend to S3
S3_BUCKET_NAME=starttech-frontend-bucket-paris-2026 \
CLOUDFRONT_DISTRIBUTION_ID=xxxx \
AWS_REGION=eu-west-3 \
./scripts/deploy-frontend.sh

# Deploy backend to EKS
ECR_REGISTRY=262945455354.dkr.ecr.eu-west-3.amazonaws.com \
AWS_REGION=eu-west-3 \
./scripts/deploy-backend.sh

# Health check
CLOUDFRONT_DOMAIN=dc5f1xv5b6hrf.cloudfront.net \
./scripts/health-check.sh

# Rollback backend deployment
./scripts/rollback.sh
```

---

## Security Notes

- No credentials are committed to this repository
- Kubernetes Secrets are created via `kubectl` or GitHub Actions — never stored in YAML files
- All sensitive values are stored in GitHub Secrets
- Docker images are scanned for vulnerabilities with Trivy before pushing to ECR

---

## Author

**Oluwagbenga Oyewole**
GitHub: [@gb-in-the-cloud](https://github.com/gb-in-the-cloud)

AWS Region: `eu-west-3` (Paris)
EKS Cluster: `starttech-cluster`
