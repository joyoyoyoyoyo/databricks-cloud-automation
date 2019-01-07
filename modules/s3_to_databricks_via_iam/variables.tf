# Required variables:

variable "aws_access_key" {
  type        = "string"
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type        = "string"
  description = "AWS Secret Key"
}

variable "aws_region" {
  type        = "string"
  description = "The region where AWS operations will take place"
}

variable "s3_bucket_name" {
  type        = "string"
  description = "Name of the bucket to connect"
}

variable "databricks_deployment_role" {
  type        = "string"
  description = "Role used to deploy Databricks. This may be determined from the account management console"
}

variable "custom_iam_role_name" {
  type        = "string"
  description = "You must assign a name to the new IAM role that is not currently used by a role in this region"
}

variable "aws_foreign_acct_access_key" {
  type        = "string"
  description = "Specify only if S3 and Databricks are in separate accounts -- this is for the S3 account and the above account will be the Databricks account"
}

variable "aws_foreign_acct_secret_key" {
  type        = "string"
  description = "Specify only if S3 and Databricks are in separate accounts - if using S3 in a separate account -- this is for the S3 account and the above account will be the Databricks account"
}

variable "aws_foreign_acct_region" {
  type        = "string"
  description = "Specify only if S3 and Databricks are in separate accounts - if using S3 in a separate account -- this is for the S3 account and the above account will be the Databricks account"
}

# variable "databricks_worksapce_url" {
#   type = "string"
#   description = "URL to access Databricks workspace"
# }


# variable "databricks_access_token" {
#   type = "string"
#   description = "Databricks API access token"
# }

