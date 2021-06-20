# ./vpc.tf

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

#EOF
