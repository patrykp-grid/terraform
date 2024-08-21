# modules/compute/variables.tf
variable "subnets" {
  description = "The IDs of the subnets to deploy resources in"
  type        = list(string)
}

variable "security_groups" {
  description = "The IDs of the security groups to assign to instances"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}
