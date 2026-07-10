FROM golang:1.25-alpine AS builder

RUN apk --no-cache add ca-certificates 

WORKDIR /app

COPY MuchToDo/go.mod MuchToDo/go.sum ./
RUN go mod download

COPY MuchToDo/ .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /app/bin/starttech-api ./cmd/api

# ─── Stage 2: Final lean image ──────────────────────────────────────────────

FROM alpine:3.20

WORKDIR /app

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/bin/starttech-api /app/bin/starttech-api .

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
   CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["./starttech-api"]
