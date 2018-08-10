variable "bucket_name" {
  type = "string"
  description = "Name of the bucket to connect"
}

variable "custom_iam_role_name" {
  type = "string"
  description = "Optionally assign a custom name to the IAM role"
  default = "databricks_to_s3_role"
}

variable "db_deployment_role" {
  type = "string"
  description = "The IAM role used to originally deploy the Databricks shard. Databricks homepage > Account Console > AWS Account > note the role name at the end of the Role ARN"
}

variable "aws_access_key" {
  type = "string"
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type = "string"
  description = "AWS Secrete Key"
}

variable "aws_region" {
  type = "string"
  description = "The region where AWS operations will take place"
}