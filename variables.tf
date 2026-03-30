variable "vpc_cidr" {
  type    = string
}

variable "subnet" {
  type = map(map(string))
  }