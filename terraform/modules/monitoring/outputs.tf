output "public_ip" {
  value       = aws_instance.monitoring.public_ip
  description = "Public IP address of monitoring server"
}

output "instance_id" {
  value       = aws_instance.monitoring.id
  description = "EC2 Monitoring Instance ID"
}
