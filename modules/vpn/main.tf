# Setup based on: https://docs.twingate.com/docs/aws

locals {
  common_tags = {
    ManagedBy      = "Terraform"
    Owner          = "Beckett"
    CostAllocation = "VPN"
    Environment    = var.environment
  }
}

data "aws_ecs_task_definition" "task" {
  count = var.create ? 1 : 0
  task_definition = aws_ecs_task_definition.main[0].family
}

provider "twingate" {
  api_token = var.twingate_api_token
  network   = var.twingate_network_name
}

resource "twingate_remote_network" "aws_network" {
  count = var.create ? 1 : 0

  name = var.remote_network_name
}

resource "twingate_connector" "aws_connector" {
  count = var.create ? 1 : 0

  remote_network_id = twingate_remote_network.aws_network[0].id
}

resource "twingate_connector_tokens" "aws_connector_tokens" {
  count = var.create ? 1 : 0

  connector_id = twingate_connector.aws_connector[0].id
}

resource "twingate_resource" "resource" {
  for_each = toset(var.resource_addresses)

  name              = "network"
  address           = each.value
  remote_network_id = twingate_remote_network.aws_network[0].id
}

resource "aws_security_group" "twingate_ecs" {
  count = var.create ? 1 : 0

  name   = "${var.name}-sg-task-${var.environment}"
  vpc_id = var.vpc_id

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecs_cluster" "main" {
  count = var.create ? 1 : 0

  name = join("-", [var.environment, var.name, "cluster"])

  tags = merge(
    {
      Name = join("-", [var.environment, var.name, "twingate-connector", "cluster"])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = join("-", [var.environment, var.name, "ecs-task-execution-role"])

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "main" {
  count = var.create ? 1 : 0

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  family                   = join("-", [var.environment, var.name, "twingate-connector"])
  container_definitions = jsonencode([{
    name      = "twingate-connector"
    image     = "twingate/connector:1"
    essential = true
    memory    = var.task_memory,
    cpu       = var.task_cpu,
    environment = [
      { "name" : "TENANT_URL", "value" : "https://${var.twingate_network_name}.twingate.com" },
      { "name" : "ACCESS_TOKEN", "value" : twingate_connector_tokens.aws_connector_tokens[0].access_token },
      { "name" : "REFRESH_TOKEN", "value" : twingate_connector_tokens.aws_connector_tokens[0].refresh_token },
      { "name" : "TWINGATE_LOG_ANALYTICS", "value" : "v1" }
    ]
    logConfiguration = {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-group" : join("-", [var.environment, var.name, "twingate-connector"])
        "awslogs-region" : var.region,
        "awslogs-stream-prefix" : "ecs"
      }
    }
  }])

  tags = merge(
    {
      Name = join("-", [var.environment, var.name, "twingate-connector"])
    },
    local.common_tags,
    var.tags
  )
}


resource "aws_ecs_service" "main" {
  count = var.create ? 1 : 0

  name                               = join("-", [var.environment, var.name, "twingate-connector", "service"])
  cluster                            = aws_ecs_cluster.main[0].id
  task_definition                    = "${aws_ecs_task_definition.main[0].family}:${max(aws_ecs_task_definition.main[0].revision, data.aws_ecs_task_definition.task[0].revision)}"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.twingate_ecs[0].id]
    subnets          = var.subnets
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = merge(
    {
      Name = join("-", [var.environment, var.name, "twingate-connector", "service"])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "yada" {
  name = join("-", [var.environment, var.name, "twingate-connector"])

  tags = merge(
    local.common_tags,
    var.tags
  )
}