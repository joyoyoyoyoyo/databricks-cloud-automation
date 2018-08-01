# dillon.bostwick@databricks.com

provider "aws" {
  alias = "customerDataPlane" # alias is needed to distinguish in case we are working with more aws accounts
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}




# Set up the unload bucket with appropriate policy:

resource "aws_s3_bucket" "unload_bucket" {
  bucket = "${var.custom_unload_bucket_name}"
}

resource "aws_s3_bucket_policy" "unload_bucket_policy" {
  bucket = "${aws_s3_bucket.unload_bucket}"
  policy = ${file(${path.module}/policies/unload_bucket_policy.template.json)}
}

data "template_file" "unload_bucket_policy" {
  template = "${file("${path.module}/policies/unload_bucket_policy.template.json")}"
  vars = {
    aws_account_id_databricks = "${local.aws_account_id_databricks}"
    s3_cross_account_role = "aws_iam_role.unload_role.name"
    unload_bucket_name = "${aws_s3_bucket.unload_bucket.id}"
  }
}




# Configure IAM role for Databricks to access unload bucket:

# Role for S3 access
resource "aws_iam_role" "unload_role" {
  name = "${var.custom_unload_role_name}"
  description = "Allow Databricks to access the temporary unload S3 bucket for Redshift query results"
  assume_role_policy = "${file("${path.module}/policies/assume_role_policy.json")}"
}

# Attach an inline policy to the role
resource "aws_iam_policy" "unload_role_inline_policy" {
  name = "unload_policy"
  role = "${aws_iam_role.unload_role.id}"
  policy = "${template_file.unload_policy_config}"
}

# Interpolate the role inline policy config template
data "template_file" "unload_policy_config" {
  template = "${file("${path.module}/policies/unload_role_policy.template.json")}"
  vars = {
    unload_bucket_name = "aws_s3_bucket.unload_bucket.id"
  }
}





# Set up pass through:

# New policy gets added to the existing Databricks EC2 role:
resource "aws_iam_policy" "pass_through_policy" {
  name = "ec2-pass-to-unload-role"
  description = "Allow EC2 pass through to unload IAM role"
  role = "var.db_deployment_role"
  policy = "template_file.pass_through_policy_config"
}

data "template_file" "pass_through_policy_config" {
  template = "${file("${path.module}/policies/pass_through_policy.template.json")}"
  vars = {
    aws_account_id_databricks = "${local.aws_account_id_databricks}"
    iam_role_for_s3_access = "aws_iam_role.unload_role.name"  
  }
}
