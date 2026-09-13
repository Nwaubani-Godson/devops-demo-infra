output "cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS Cluster Name"
}

output "service_name" {
  value       = aws_ecs_service.main.name
  description = "ECS Service Name"
}
