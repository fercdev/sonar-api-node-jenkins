variable "aws_region" {
    type = string
}

variable "image_url" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
    type = list(string)
}