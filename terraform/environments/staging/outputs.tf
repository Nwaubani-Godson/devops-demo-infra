output "app_url" {
  value       = "http://${module.alb.alb_dns_name}"
  description = "Public URL for FastAPI app"
}
