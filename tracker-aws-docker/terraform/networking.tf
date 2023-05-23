
resource "aws_vpc" "tracker_vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "tracker_vpc"
  }
}

resource "aws_subnet" "tracker_subnet" {
  vpc_id                  = aws_vpc.tracker_vpc.id
  cidr_block              = "172.31.0.0/16"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tracker_subnet"
  }
}

resource "aws_internet_gateway" "tracker_gateway" {
  vpc_id = aws_vpc.tracker_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.tracker_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tracker_gateway.id
  }

  tags = {
    Name = "public subnet route table"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.tracker_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "allow ssh"
  vpc_id      = aws_vpc.tracker_vpc.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # gh-actions ci/cd uses ssh. password auth is disabled
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_security_group" "allow_mssql_from_vpc" {
  name        = "allow_mssql_from_vpc"
  description = "allow MSSQL inbound traffic from VPC"
  vpc_id      = aws_vpc.tracker_vpc.id

  ingress {
    description = "MSSQL from VPC"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.tracker_vpc.cidr_block, format("%s/%s", aws_instance.server.public_ip, "32")]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_mssql_from_vpc"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_mssql_from_api_public_ip" {
  security_group_id = "sg-0d47358ef5626ec5a"

  cidr_ipv4   = format("%s/%s", aws_instance.server.public_ip, "32")
  from_port   = 1433
  to_port     = 1433
  ip_protocol = "tcp"

  tags = {
    Name = "allow_mssql_from_api_public_ip"
  }
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "allow HTTPS inbound traffic from anywhere"
  vpc_id      = aws_vpc.tracker_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_https"
  }
}

resource "aws_security_group" "allow_api_port" {
  name        = "allow_api_port"
  description = "allow api inbound traffic from anywhere"
  vpc_id      = aws_vpc.tracker_vpc.id

  ingress {
    description = "API"
    from_port   = 7004
    to_port     = 7004
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_api_port"
  }
}
