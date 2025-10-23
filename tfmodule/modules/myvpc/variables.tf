variable "region" {
  type        = string
  default     = "us-west-1"
}

variable "az" {
  type        = list(string)
  default     = ["a","c"]
}



