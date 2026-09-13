resource "aws_ecs_cluster" "main" {
  name = "devops-demo-cluster-${var.environment}"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/devops-demo-app-${var.environment}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "devops-demo-ecs-tasks-sg-${var.environment}"
  description = "Allow inbound traffic from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devops-demo-ecs-tasks-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "devops-demo-app-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "devops-demo-app"
      image     = var.image_url
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "APP_VERSION"
          value = var.image_url
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_service" "main" {
  name                               = "devops-demo-service-${var.environment}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.app.arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.public_subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "devops-demo-app"
    container_port   = 8000
  }

  tags = {
    Environment = var.environment
  }
}
