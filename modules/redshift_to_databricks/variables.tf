variable "aws_access_key" {
  type = "string"
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type = "string"
  description = "AWS Secrete Key"
}

variable "expire_query_results_days" {
  type = "string"
  description = "# days before query results stored in S3 unload bucket are expired"
  default = "10"
}

variable "aws_region" {
  type = "string"
  description = "The region where AWS operations will take place"
}

variable "custom_unload_bucket_name" {
  type = "string"
  description = "Optionally assign a custom name to the temporary S3 bucket which is used to unload query results from Redshift"
  default = "redshift-unload-to-databricks"
}

variable "custom_iam_role_name_for_s3_conection" {
  type = "string"
  description = "Optionally asign a custom name to the role to allow Redshift to access the unload bucket"
  default = "databricks-to-redshift-unload-s3-role"
}

variable "databricks_access_token" {
  type = "string"
  description = "Databricks API access token"
}

variable "databricks_deployment_role" {
  type = "string"
  description = "Role used to deploy Databricks. This may be determine from the account management console"
}

variable "custom_redshift_iam_role_name" {
  type = "string"
  description = "Optionally assign a custom name to the IAM role which will attach to the Redshift cluster and allow unloading query results to the S3 bucket"
  default = "redshift-unload-to-databricks"
}

variable "redshift_cluster_id" {
  type = "string"
  description = "Identifier of the target Redshift cluster to connect"
}

variable "databricks_shard_name" {
  type = "string"
  description = "Name of deployed Databricks shard. Contact sales@databricks.com for help determining your shard name or deploying a Databricks shard."
}