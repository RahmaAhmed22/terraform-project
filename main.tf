provider "aws" {
  region  = "us-east-1"
  profile = "rahma"

}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "abc-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet["subnet1"]["cidr"]
  availability_zone = var.subnet["subnet1"]["az"]
  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet["subnet2"]["cidr"]
  availability_zone = var.subnet["subnet2"]["az"]
  tags = {
    Name = "subnet2"
  }
}