
variable "vpc_cidr" {
  default = "10.0.0.0/16"
  description = "default CIRD range of VPC"

}

variable "aws_region" {
  default = "us-east-1"
}

variable "kubernetes_version" {
  default = "1.30"
}