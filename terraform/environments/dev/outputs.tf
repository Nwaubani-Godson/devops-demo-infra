output "app_url" {
  value       = "http://${module.alb.alb_dns_name}"
  description = "Public URL for FastAPI app"
}

output "monitoring_ip" {
  value       = module.monitoring.public_ip
  description = "Public IP for Prometheus & Grafana EC2 Monitoring host"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "Amazon ECR Repository URL"
}
