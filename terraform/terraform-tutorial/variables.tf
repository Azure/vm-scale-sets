
variable "num_instances" {
  description = "Number of instances for the worker"
  type        = number
  default     = 3
}


variable "nat_rule_frontend_port_start" {
  description = "The Load Balancer port through which you can ssh into the first VM instance"
  type        = number
  default     = 50000
}