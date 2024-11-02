variable "resource_name" {
  description = "Base name for IAM policy, role, user, group, and DynamoDB table"
  type        = string
}

variable "region" {
  description = "Region to create the s3 bucket and dynamodb"
  type        = string
}

variable "environment" {
  description = "Environment DEV/QA/STG/PROD"
  type        = string
}

variable "team" {
  description = "Team name who will manage this resources"
  type        = string
}



variable "bucket_name" {
  description = "Name for the S3 bucket"
  type        = string
}

variable "iam_path_admins" {
  description = "Name for the S3 bucket"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name for the DynamoDB table for state locking"
  type        = string
}

variable "admin_users" {
  description = "List of users to assign to the IAM role"
  type        = list(string)
  default     = ["admin_user1", "admin_user2", "admin_user3"] # Replace with actual usernames
}

variable "users" {
  description = "List of users to create and add to the IAM group"
  type        = list(string)
  default     = ["user1", "user2", "user3"] # Replace with actual usernames
}

variable "iam_path_users" {
  description = "IAM path for the users, roles, and policies"
  type        = string
}
