# -----------------------------------
# ECS Cluster
# -----------------------------------

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

# -----------------------------------
# CloudWatch Log Group
# -----------------------------------

resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/${var.project_name}-strapi"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-log-group"
  }
}

# -----------------------------------
# Task Definition (FARGATE)
# -----------------------------------

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "512"
  memory = "1024"

  execution_role_arn = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = var.image_uri
      essential = true

      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = var.db_endpoint },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USERNAME", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password },

        { name = "DATABASE_SSL", value = "true" },
        { name = "DATABASE_SSL_REJECT_UNAUTHORIZED", value = "false" },

        { name = "APP_KEYS", value = "key1,key2,key3,key4" },
        { name = "JWT_SECRET", value = "jwtsecret123" },
        { name = "ADMIN_JWT_SECRET", value = "adminsecret123" },
        { name = "API_TOKEN_SALT", value = "salt123" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_cloudwatch_log_group.strapi
  ]
}

# -----------------------------------
# ECS Service (FARGATE - PRIVATE)
# -----------------------------------

resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false   # IMPORTANT: private subnet
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "strapi"
    container_port   = 1337
  }

  propagate_tags = "SERVICE"

  depends_on = [
    aws_ecs_task_definition.this
  ]
}

# -----------------------------------
# CloudWatch Dashboard
# -----------------------------------

resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "${var.project_name}-ecs-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.this.name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.this.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "CPU and Memory Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.this.name],
            ["AWS/ECS", "NetworkRxBytes", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.this.name],
            ["AWS/ECS", "NetworkTxBytes", "ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.this.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Task Count and Network Traffic"
        }
      }
    ]
  })
}