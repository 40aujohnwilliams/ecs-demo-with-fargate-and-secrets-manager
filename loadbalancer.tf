
resource "aws_lb" "thelb" {
  name               = "${local.environment-name}-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups = [module.lb-sg.security_group_id]
  subnets = module.vpc.public_subnets
}

resource "aws_lb_target_group" "env-var-svc" {
  name = "env-var-svc-tg"
  target_type = "ip"
  port = 80
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
}

resource "aws_lb_listener" "env-var-svc" {
  load_balancer_arn = aws_lb.thelb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.env-var-svc.arn
  }
}

# Redirect everything to the service.
resource "aws_lb_listener_rule" "env-var-src" {
  listener_arn = aws_lb_listener.env-var-svc.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.env-var-svc.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

module "lb-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${local.environment-name}-env-var-svc"
  description = "${local.environment-name} - Security group for env var svc"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
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
