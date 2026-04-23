terraform {
    required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "tf-state-bucket-440763701841-us-east-1-an"
    key    = "terraform.tfstate"
    region = "us-east-1"
    profile = "rahma"
  }
}