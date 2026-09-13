# DevOps Demo Infrastructure — GitOps & AWS Platform Repository

This repository manages the AWS infrastructure, environment configurations (`dev`, `staging`, `prod`), monitoring configuration management (Ansible), and deployment automation pipelines for the **DevOps Pulse Demo Platform**.

---

## 🏗️ Architecture Overview

```
                               ┌───────────────┐
                               │     JIRA      │
                               │   TASK-101    │
                               └───────┬───────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │     GitHub      │
                              │ Code Review/PRs │
                              └────────┬────────┘
                                       │
                ┌──────────────────────┴──────────────────────┐
                │                                             │
                ▼                                             ▼
      devops-demo-app                                devops-demo-infra
(FastAPI, Docker, Pytest, CI)                 (Terraform, Ansible, Workflows)
                │                                             │
         GitHub Actions                                GitHub Actions
 (Lint, Test, Docker Build)                        (Plan / Approval / Apply)
                │                                             │
                ▼                                             ▼
         Amazon ECR Image                             AWS ECS Fargate
   (tag: git-<commit-sha>)                           (Dev -> Staging -> Prod)
                │                                             │
                └──────────────────────┬──────────────────────┘
                                       │
                                       ▼
                       ┌──────────────────────────────┐
                       │    Application Load Balancer │
                       │       (Direct DNS/IP)        │
                       └──────────────┬───────────────┘
                                      │
                       ┌──────────────┴──────────────┐
                       │                             │
                       ▼                             ▼
              FastAPI Dashboard              EC2 Monitoring Host
             (ECS Fargate Tasks)               (t3.micro EC2)
                       │                 (Ansible/Prometheus/Grafana)
                       ▼                             │
                 CloudWatch Logs                     ▼
                                            Prometheus Metrics Scraper
```

---

## 🚀 Key Modules & Structure

* `terraform/modules/vpc`: Public Subnet VPC layout without NAT Gateway hourly costs.
* `terraform/modules/ecr`: ECR repository for `devops-demo-app` with 5-image lifecycle policy.
* `terraform/modules/alb`: Application Load Balancer with direct DNS exposure and HTTP target group `/health` checks.
* `terraform/modules/ecs`: ECS Cluster, Fargate Task Definition (256 CPU / 512 MB RAM), ECS Service (`assign_public_ip = true`), and CloudWatch log groups.
* `terraform/modules/monitoring`: EC2 `t3.micro` monitoring host for Prometheus + Grafana.
* `terraform/modules/iam`: Task execution roles, task roles, and GitHub Actions OIDC federation.
* `ansible/`: Idempotent Ansible playbooks deploying Docker, Prometheus, and Grafana.

---

## ⚡ Deployment Promotion Flow

1. **App Build (`devops-demo-app`):** GitHub Actions builds container image tagged `git-<commit-sha>` and pushes to ECR.
2. **Infrastructure Dispatch:** App pipeline dispatches event to `devops-demo-infra`.
3. **Terraform Plan & Apply:**
   * **Dev:** Automatic `plan` → Automatic `apply`.
   * **Staging:** Automatic `plan` → **GitHub Environment Approval** → `apply`.
   * **Production:** Automatic `plan` → **GitHub Environment Approval** → `apply`.

---

## 🔍 Live Demo Drift Remediation Test

To demonstrate infrastructure drift remediation during a live presentation:
1. Manually edit an ECS service in the AWS Console (e.g., change `desired_count` from `2` to `1`).
2. Run `terraform plan` in `terraform/environments/prod`.
3. Terraform detects drift: `desired_count: 1 -> 2`.
4. Execute `terraform apply` to automatically restore the desired state from Git!
