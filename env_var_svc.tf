
###
# ECS Bits - Task Definition and Service - Describes the Container/Task
###

resource "aws_ecs_task_definition" "env-var-svc" {
  family                   = "env-var-svc"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.env-var-svc.arn
  execution_role_arn       = aws_iam_role.exec-role.arn

  container_definitions = jsonencode([
    {
      name      = "env-var-svc"
      image     = aws_ecr_repository.testimage.repository_url
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      secrets = [
        {
          name = "MY_ENV_VAR_1",
          valueFrom = "${aws_secretsmanager_secret.env-var-svc.arn}:MY-SECRET-1::"
        },
        {
          name = "MY_ENV_VAR_2",
          valueFrom = "${aws_secretsmanager_secret.env-var-svc.arn}:MY-SECRET-2::"
        },
        {
          name = "MY_ENV_VAR_3",
          valueFrom = "${aws_secretsmanager_secret.env-var-svc.arn}:MY-SECRET-3::"
        }
      ]
#      environment = local.env_vars
      #      logConfiguration = {
      #        logDriver = "awslogs"
      #        options = {
      #          awslogs-group         = var.cloudwatch_group_name
      #          awslogs-region        = var.log_region
      #          awslogs-stream-prefix = "app"
      #        }
      #      }
    }
  ])

  tags = local.tags
}

resource "aws_ecs_service" "main" {
  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }

  name = "env-var-svc"

  cluster                            = aws_ecs_cluster.testcluster.arn
  desired_count                      = 1
  enable_execute_command             = true
  force_new_deployment               = true
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  propagate_tags                     = "SERVICE"
  task_definition                    = aws_ecs_task_definition.env-var-svc.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.env-var-svc.arn
    container_name   = "env-var-svc"
    container_port   = 8080
  }

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.env-var-svc-sg.security_group_id]
    assign_public_ip = false
  }

  tags = local.tags
}

###
# IAM - Container's Role
###

resource "aws_iam_role" "env-var-svc" {
  name = "${local.environment-name}-env-var-svc-role"
  description = "${local.environment-name} - Role for env-var-svc container"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = local.tags
}

resource "aws_iam_policy" "secret-manager-reader" {
  name = "${local.environment-name}-env_var_svc_secrets_reader"
  description = "${local.environment-name} - Read access to env-var-svc secrets"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "${aws_secretsmanager_secret.env-var-svc.arn}*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        }
  ]
}
EOF

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "env-var-svc-secrets-reader" {
  role       = aws_iam_role.env-var-svc.name
  policy_arn = aws_iam_policy.secret-manager-reader.arn
}

###
# IAM - ECS's Execution Role
###

resource "aws_iam_role" "exec-role" {
  name = "${local.environment-name}-env-var-svc-exec-role"
  description = "${local.environment-name} - Role for env-var-svc execution role thingie"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "exec-role-plain-jane" {
  role       = aws_iam_role.exec-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "exec-role-secrets-reader" {
  role       = aws_iam_role.exec-role.name
  policy_arn = aws_iam_policy.secret-manager-reader.arn
}

###
# Secrets
###

resource "aws_secretsmanager_secret" "env-var-svc" {
  name = "env-var-svc"
}

variable "env-var-svc-secrets" {
  default = {
    MY-SECRET-1 = "foo"
    MY-SECRET-2 = "bar"
    MY-SECRET-3 = "baz"
  }
  type = map(string)
}

resource "aws_secretsmanager_secret_version" "env-var-svc" {
  secret_id     = aws_secretsmanager_secret.env-var-svc.id
  secret_string = jsonencode(var.env-var-svc-secrets)
}

module "env-var-svc-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${local.environment-name}-env-var-svc"
  description = "${local.environment-name} - Security group for env var svc"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "http"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  # egress
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "wide open exit"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(
    {
      Name = "${local.environment-name}-env-var-svc"
    }, local.tags
  )
}
