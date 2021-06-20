# ./main.tf

# ------------------------------------------------------------------------------

resource "aws_vpc" "alf_vpc" {
  cidr_block = "192.168.0.0/24"
  tags       = var.tags
}

resource "aws_subnet" "alf_subnet_a" {
  vpc_id            = aws_vpc.alf_vpc.id
  cidr_block        = "192.168.0.0/28"
  availability_zone = "${var.region}a"
  tags              = var.tags
}

resource "aws_subnet" "alf_subnet_b" {
  vpc_id            = aws_vpc.alf_vpc.id
  cidr_block        = "192.168.0.16/28"
  availability_zone = "${var.region}b"
  tags              = var.tags
}

resource "aws_internet_gateway" "alf_igw" {
  vpc_id = aws_vpc.alf_vpc.id
  tags   = var.tags
}

resource "aws_route_table" "alf_rtb" {
  vpc_id = aws_vpc.alf_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.alf_igw.id
  }
  tags = var.tags
}

resource "aws_route_table_association" "alf_rtb_assoc_a" {
  subnet_id      = aws_subnet.alf_subnet_a.id
  route_table_id = aws_route_table.alf_rtb.id
}

resource "aws_route_table_association" "alf_rtb_assoc_b" {
  subnet_id      = aws_subnet.alf_subnet_b.id
  route_table_id = aws_route_table.alf_rtb.id
}

resource "aws_network_acl" "alf_vpc_nacl" {
  vpc_id     = aws_vpc.alf_vpc.id
  subnet_ids = [aws_subnet.alf_subnet_a.id, aws_subnet.alf_subnet_b.id]
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

resource "aws_security_group" "alf_alb_sg" {
  name        = "alf-alb-sg"
  description = "manage alb network access"
  vpc_id      = aws_vpc.alf_vpc.id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alf_alb_sg_rule_ingress" {
  security_group_id = aws_security_group.alf_alb_sg.id
  description       = "allow port 80/tcp from internet to alb"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

# this is worthless without further specification
#resource "aws_security_group_rule" "alf_alb_sg_rule_egress" {
#  security_group_id = aws_security_group.alf_alb_sg.id
#  description       = "allow all from alb to internet"
#  type              = "egress"
#  protocol          = "-1"
#  from_port         = 0
#  to_port           = 0
#  cidr_blocks       = ["0.0.0.0/0"]
#}

# ------------------------------------------------------------------------------

resource "aws_lb" "alf_alb" {
  name               = "alf-alb"
  internal           = false
  load_balancer_type = "application"
  subnets = [
    aws_subnet.alf_subnet_a.id,
    aws_subnet.alf_subnet_b.id,
  ]
  security_groups = [aws_security_group.alf_alb_sg.id]
  tags            = var.tags
}

resource "aws_lb_target_group" "alf_alb_tg" {
  name        = "alf-alb-tg"
  target_type = "lambda"
  tags        = var.tags
}

resource "aws_lb_listener" "alf_alb_listener" {
  load_balancer_arn = aws_lb.alf_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alf_alb_tg.arn
  }
  tags = var.tags
}

# ------------------------------------------------------------------------------

resource "aws_iam_role" "alf_lambda_exec_role" {
  name               = "alf-lambda-exec-role"
  description        = "Execution role for lambda"
  assume_role_policy = file("${path.module}/files/lambda-execution-role.json")
  tags               = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "alf_lambda_iam_policy" {
  name   = "alf_lambda_iam_policy"
  policy = file("${path.module}/files/lambda-iam-policy.json")
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "alf_lambda_role_polattach" {
  policy_arn = aws_iam_policy.alf_lambda_iam_policy.arn
  role       = aws_iam_role.alf_lambda_exec_role.name
}

# ------------------------------------------------------------------------------

resource "aws_security_group" "alf_lambda_sg" {
  name        = "alf-lambda-sg"
  description = "manage lambda network access"
  vpc_id      = aws_vpc.alf_vpc.id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alf_lambda_sg_rule_ingress" {
  security_group_id        = aws_security_group.alf_lambda_sg.id
  description              = "allow port 80/tcp to lambda from alb"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.alf_alb_sg.id
}

# ------------------------------------------------------------------------------

data "archive_file" "alf_lambda_zip" {
  type        = "zip"
  source_file = "./files/lambda_function.py"
  output_path = "./files/lambda_function.zip"
}

# ------------------------------------------------------------------------------

resource "aws_lambda_function" "alf_lambda_function" {
  function_name = "alf-lambda-function"
  role          = aws_iam_role.alf_lambda_exec_role.arn
  runtime       = "python3.8"
  filename      = "./files/lambda_function.zip"
  handler       = "lambda_function.lambda_handler"
  vpc_config {
    subnet_ids = [
      aws_subnet.alf_subnet_a.id,
      aws_subnet.alf_subnet_b.id,
    ]
    security_group_ids = [aws_security_group.alf_lambda_sg.id]
  }
  environment {
    variables = {
      APP = "lambda_function.py"
    }
  }
  tags = var.tags
}
