variable "vpc_id" {
  description = "VPC ID where servers will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where servers will be deployed"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into servers"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
