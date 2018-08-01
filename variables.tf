variable "custom_unload_bucket_name" {
  type = "string"
  description = "Optionally assign a custom name to the temporary S3 bucket which is used to unload query results from Redshift"
  default = "redshift-unload-to-databricks"
}

variable "custom_unload_role_name" {
  type = "string"
  description = "Optionally assign a custom name to the IAM role which enables Databricks access to the temporary unload S3 bucket"
  default = "redshift-unload-to-databricks-role"
}

variable "db_deployment_role" {
  type = "string"
  description = "The IAM role used to originally deploy the Databricks shard. Databricks homepage > Account Console > AWS Account > note the role name at the end of the Role ARN"
}