provider "aws" {
  region  = "us-east-1"
  profile = "rahma"

}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "abc-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "abc-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "abc-rt"
  }
}

resource "aws_route_table_association" "rt-association1" {
  subnet_id      = aws_subnet.subnet["subnet1"].id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rt-association2" {
  subnet_id      = aws_subnet.subnet["subnet2"].id
  route_table_id = aws_route_table.rt.id
}

resource "aws_subnet" "subnet" {
  for_each          = var.subnet
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value["cidr"]
  availability_zone = each.value["az"]
  tags = {
    Name = each.key
  }
}


# S3
resource "aws_s3_bucket" "bucket" {
  bucket = "abc-test-20010556"
  tags = {
    Name = "abc bucket"
  }
}

# sg
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow ssh and http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_ssh_http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# generating SSH key
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "abc-key"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "local_file" "ec2_private_key" {
  filename = "./ec2_key.pem"
  content  = tls_private_key.private_key.private_key_pem
  file_permission = "400"
}

# EC2
data "aws_ami" "example" {
  most_recent      = true
  name_regex       = "al2023-ami-2023.*-6.1-x86_64"
  owners           = ["137112412989"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.example.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet["subnet1"].id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ec2_key.key_name
  user_data                   = <<-EOF
    #!/bin/bash
    dnf install nginx -y
    systemctl start nginx
  EOF
  
  tags = {
    Name = "abc-ec2"
  }

  #lifecycle {
   # create_before_destroy = true
  #}
}

output "instance_dns" {
  value = aws_instance.ec2.public_dns
}

output "instance_public_ip" {
  value = aws_instance.ec2.public_ip
}

# RDS
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

  lifecycle {
    prevent_destroy = true
  }
}