variable "project_name" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "aws_region" {
  default = "ap-south-1"
}variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "image_uri" {
  description = "Docker image URI from ECR"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}