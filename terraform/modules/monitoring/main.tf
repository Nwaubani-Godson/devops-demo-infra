data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "monitoring" {
  name        = "devops-demo-monitoring-sg-${var.environment}"
  description = "Allow SSH, Prometheus, and Grafana inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devops-demo-monitoring-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  associate_public_ip_address = true

  # Bootstrap: install Docker, Prometheus, and Grafana on first boot
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Install Docker
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker

    # Create Prometheus config
    mkdir -p /etc/prometheus
    cat > /etc/prometheus/prometheus.yml <<'PROMEOF'
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    scrape_configs:
      - job_name: "prometheus"
        static_configs:
          - targets: ["localhost:9090"]

      - job_name: "devops-demo-app-${var.environment}"
        metrics_path: /metrics
        static_configs:
          - targets: ["${var.app_alb_dns}:80"]
    PROMEOF

    # Run Prometheus
    docker run -d \
      --name prometheus \
      --restart=always \
      -p 9090:9090 \
      -v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
      prom/prometheus:latest \
      --config.file=/etc/prometheus/prometheus.yml \
      --web.enable-lifecycle

    # Run Grafana
    docker run -d \
      --name grafana \
      --restart=always \
      -p 3000:3000 \
      -e GF_SECURITY_ADMIN_USER=admin \
      -e GF_SECURITY_ADMIN_PASSWORD=devops123 \
      -e GF_AUTH_ANONYMOUS_ENABLED=true \
      -e GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer \
      grafana/grafana:latest

    echo "Monitoring stack started successfully" >> /var/log/bootstrap.log
  EOF

  user_data_replace_on_change = true

  tags = {
    Name        = "devops-demo-monitoring-host-${var.environment}"
    Environment = var.environment
    Role        = "Prometheus-Grafana-Host"
  }
}
