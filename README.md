# Bakery — DevOps Final Project

A small online bakery shop built as a polyglot microservice stack, used as the
vehicle for an EKS / Terraform / GitOps capstone project.

## Architecture

```
        ┌────────────┐
        │  React UI  │  apps/web        (port 5173)
        └─────┬──────┘
              │
   ┌──────────┼─────────────────┐
   ▼          ▼                 ▼
┌────────┐ ┌────────┐      ┌──────────┐
│catalog │ │ orders │ ───▶ │inventory │
│ Java   │ │ Python │      │  Python  │
│:8081   │ │ :8083  │      │  :8082   │
└───┬────┘ └────┬───┘      └─────┬────┘
    │           │                │
    └───────────┴───── RDS ──────┘
              (Postgres, schema-per-service)
```

| Service          | Stack            | Schema     | Responsibility                          |
| ---------------- | ---------------- | ---------- | --------------------------------------- |
| `catalog-svc`    | Java 21 / Boot 3 | `catalog`  | List baked goods, prices                |
| `inventory-svc`  | Python 3.12 / FastAPI | `inventory` | Stock levels per product           |
| `orders-svc`     | Python 3.12 / FastAPI | `orders`    | Place order, list orders by email  |
| `web`            | React 18 / Vite / Tailwind | n/a | Storefront UI                       |

## Local development

```bash
docker compose up --build
```

- Storefront: <http://localhost:5173>
- Catalog API: <http://localhost:8081/products>
- Orders API: <http://localhost:8083/orders?email=test@example.com>
- Inventory API: <http://localhost:8082/stock>

Tear down with `docker compose down -v` (the `-v` wipes the Postgres volume).

## Project status

- [x] Local docker-compose stack
- [ ] Helm charts per service
- [ ] Terraform (VPC / EKS / RDS / IAM / ACM / Route53)
- [ ] GitHub Actions CI (build + push to ECR)
- [ ] Argo CD + Argo Rollouts (Blue/Green)
- [ ] kube-prometheus-stack + Loki + Grafana (GitHub OAuth)
- [ ] Day 2: AMI rotation drill
- [ ] Day 2: schema migration drill
