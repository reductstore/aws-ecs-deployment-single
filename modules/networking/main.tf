
resource "aws_security_group" "svc" {
  name        = "${var.name}-svc-sg"
  description = "Allow ALB -> ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Public access to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow ALB to reach tasks on container port
resource "aws_security_group_rule" "alb_to_svc" {
  type                     = "ingress"
  from_port                = var.reductstore_port
  to_port                  = var.reductstore_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.svc.id
  source_security_group_id = aws_security_group.alb.id
}
