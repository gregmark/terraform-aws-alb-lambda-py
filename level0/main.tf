# ./main.tf

# ------------------------------------------------------------------------------

resource "aws_vpc" "alp_vpc" {
  cidr_block = "192.168.0.0/24"
  tags       = var.tags
}

resource "aws_subnet" "alp_subnet_a" {
  vpc_id            = aws_vpc.alp_vpc.id
  cidr_block        = "192.168.0.0/28"
  availability_zone = "${var.region}a"
  tags              = var.tags
}

resource "aws_subnet" "alp_subnet_b" {
  vpc_id            = aws_vpc.alp_vpc.id
  cidr_block        = "192.168.0.16/28"
  availability_zone = "${var.region}b"
  tags              = var.tags
}

resource "aws_internet_gateway" "alp_igw" {
  vpc_id = aws_vpc.alp_vpc.id
  tags   = var.tags
}

resource "aws_route_table" "alp_rtb" {
  vpc_id = aws_vpc.alp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.alp_igw.id
  }
  tags = var.tags
}

resource "aws_route_table_association" "alp_rtb_assoc_a" {
  subnet_id      = aws_subnet.alp_subnet_a.id
  route_table_id = aws_route_table.alp_rtb.id
}

resource "aws_route_table_association" "alp_rtb_assoc_b" {
  subnet_id      = aws_subnet.alp_subnet_b.id
  route_table_id = aws_route_table.alp_rtb.id
}

resource "aws_network_acl" "alp_vpc_nacl" {
  vpc_id     = aws_vpc.alp_vpc.id
  subnet_ids = [aws_subnet.alp_subnet_a.id, aws_subnet.alp_subnet_b.id]
  ingress {
    rule_no    = 10
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  egress {
    rule_no    = 10
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  tags = var.tags
}

# ------------------------------------------------------------------------------

resource "aws_security_group" "alp_alb_sg" {
  name        = "alp-alb-sg"
  description = "manage alb network access"
  vpc_id      = aws_vpc.alp_vpc.id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alp_alb_rule_ingress" {
  security_group_id = aws_security_group.alp_alb_sg.id
  description       = "allow port 80/tcp from internet to alb"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alp_alb_rule_egress" {
  security_group_id        = aws_security_group.alp_alb_sg.id
  description              = "allow port 80/tcp access from alb to lambda"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.alp_lambda_sg.id
}

# ------------------------------------------------------------------------------

resource "aws_lb" "alp_alb" {
  name               = "alp-alb"
  internal           = false
  load_balancer_type = "application"
  subnets = [
    aws_subnet.alp_subnet_a.id,
    aws_subnet.alp_subnet_b.id,
  ]
  security_groups = [aws_security_group.alp_alb_sg.id]
  access_logs {
    enabled = true
    bucket  = aws_s3_bucket.alp_s3.bucket
  }
  tags = var.tags
}

resource "aws_lb_target_group" "alp_alb_tg" {
  name        = "alp-alb-tg"
  target_type = "lambda"
  tags        = var.tags
}

resource "aws_lb_listener" "alp_alb_listener" {
  load_balancer_arn = aws_lb.alp_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = jsonencode({nobody = "home"})
      status_code  = "404"
    }
  }
  tags = var.tags
}

# ------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "alp_health_check" {
  listener_arn = aws_lb_listener.alp_alb_listener.arn
  priority     = 100
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "HEALTHY"
      status_code  = "200"
    }
  }
  condition {
    query_string {
      key   = "health"
      value = "alb"
    }
    query_string {
      value = "alb"
    }
  }
}

resource "aws_lb_listener_rule" "alp_lambda_healthcheck" {
  listener_arn = aws_lb_listener.alp_alb_listener.arn
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alp_alb_tg.arn
  }
  condition {
    path_pattern {
      values = ["/check", "/now", "/version"]
    }
  }
}

# ------------------------------------------------------------------------------

resource "aws_iam_role" "alp_lambda_exec_role" {
  name               = "alp-lambda-exec-role"
  description        = "Execution role for lambda"
  assume_role_policy = file("${path.module}/files/lambda-execution-role.json")
  tags               = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "alp_lambda_role_polattach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.alp_lambda_exec_role.name
}

# ------------------------------------------------------------------------------

resource "aws_security_group" "alp_lambda_sg" {
  name        = "alp-lambda-sg"
  description = "manage lambda network access"
  vpc_id      = aws_vpc.alp_vpc.id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alp_lambda_ingress_rule" {
  security_group_id        = aws_security_group.alp_lambda_sg.id
  description              = "allow port 80/tcp to lambda from alb"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.alp_alb_sg.id
}

resource "aws_security_group_rule" "alp_lambda_egress_rule" {
  security_group_id = aws_security_group.alp_lambda_sg.id
  description       = "allow all outbound from lambda"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ------------------------------------------------------------------------------

data "archive_file" "alp_lambda_zip" {
  type        = "zip"
  source_file = "./files/lambda_function.py"
  output_path = "./files/lambda_function.zip"
}

# ------------------------------------------------------------------------------

resource "aws_lambda_function" "alp_lambda_function" {
  function_name    = "alp-lambda-function"
  role             = aws_iam_role.alp_lambda_exec_role.arn
  runtime          = "python3.8"
  handler          = "lambda_function.lambda_handler"
  filename         = "./files/lambda_function.zip"
  source_code_hash = data.archive_file.alp_lambda_zip.output_base64sha256
  timeout          = 10
  vpc_config {
    subnet_ids = [
      aws_subnet.alp_subnet_a.id,
      aws_subnet.alp_subnet_b.id,
    ]
    security_group_ids = [aws_security_group.alp_lambda_sg.id]
  }
  environment {
    variables = {
      ALP_VER = "$LATEST"
    }
  }
  tags = var.tags
}

resource "aws_lambda_permission" "alp_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alp_lambda_function.arn
  statement_id  = "allow-alb-to-invoke-lambda-function"
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.alp_alb_tg.arn
}

# ------------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "alp_alb_tg_attach" {
  target_group_arn = aws_lb_target_group.alp_alb_tg.arn
  target_id        = aws_lambda_function.alp_lambda_function.arn
  depends_on       = [aws_lambda_permission.alp_lambda_permission]
}

#EOF
