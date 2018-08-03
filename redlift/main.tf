# dillon.bostwick@databricks.com

provider "aws" {
  alias = "customerDataAwsAccount" # alias is needed to distinguish in case we are working with more aws accounts
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}





# Create unload bucket for query results:

resource "aws_s3_bucket" "unload_bucket" {
  bucket = "${var.custom_unload_bucket_name}"

  # Automatically expire query results after fixed period
  lifecycle_rule {
    id = "remove-all-10-days"
    enabled = true
    expiration = {
      days = "${var.expire_query_results_days}"
    }
  }
}



# Create role for Redshfit to access the unload bucket:

# Establish role with AmazonS3ReadOnlyAccess
resource "aws_iam_role" "redshift_to_unload_bucket_role" {
  name = "${var.custom_unload_bucket_name}"
  assume_role_policy = "${file("${path.module}/policies/assume_role_policy.json")}"
}

# Apply the existing aws policy, AmazonS3ReadOnlyAccess, to the new role
resource "aws_iam_role_policy_attachment" "attach_s3_permissions_to_redshift_role" {
  role = "${aws_iam_role.redshift_to_unload_bucket_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}



# Optionally run "terraform import" before applying in order to use an existing
# cluster
resource "aws_redshift_cluster" "to_connect" {
  
}












