# dillon.bostwick@databricks.com

provider "aws" {
  alias = "customerDataAwsAccount" # alias is needed to distinguish in case we are working with more aws accounts
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

provider "http" {}
data "aws_caller_identity" "current" {}

# Set up bucket policy:

data "aws_s3_bucket" "target_s3_bucket" {
  bucket = "${var.s3_bucket_name}"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${data.aws_s3_bucket.target_s3_bucket.id}"
  policy = "${data.template_file.bucket_policy.rendered}"
}

data "template_file" "bucket_policy" {
  template = "${file("${path.module}/policies/bucket_policy.template.json")}"
  vars = {
    aws_account_id = "${data.aws_caller_identity.current.account_id}"
    s3_cross_account_role = "${aws_iam_role.databricks_to_s3_role.id}"
    target_bucket_name = "${data.aws_s3_bucket.target_s3_bucket.id}"
  }
}


# Configure IAM role for Databricks to access bucket:

# Role for S3 access
resource "aws_iam_role" "databricks_to_s3_role" {
  name = "${var.custom_iam_role_name}"
  assume_role_policy = "${file("${path.module}/policies/assume_role_policy.json")}"
}

# Need to explicitally specify the instance profile for the role as well
resource "aws_iam_instance_profile" "role_instance_profile" {
  name = "${aws_iam_role.databricks_to_s3_role.name}"
  role = "${aws_iam_role.databricks_to_s3_role.name}"
}

# Attach an inline policy to the role
resource "aws_iam_policy" "databricks_to_s3_policy" {
  name = "databricks_to_s3_policy"
  policy = "${data.template_file.databricks_to_s3_policy_config.rendered}"
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
  role = "${aws_iam_role.databricks_to_s3_role.id}"
  policy_arn = "${aws_iam_policy.databricks_to_s3_policy.arn}"
}

# Interpolate the role inline policy config template
data "template_file" "databricks_to_s3_policy_config" {
  template = "${file("${path.module}/policies/role_policy.template.json")}"
  vars = {
    target_bucket_name = "${data.aws_s3_bucket.target_s3_bucket.id}"
  }
}


# Set up pass through from the shard role:

# New policy gets added to the existing Databricks EC2 role:
resource "aws_iam_policy" "pass_through_policy" {
  name = "ec2-pass-to-databricks-bucket-role"
  policy = "${data.template_file.pass_through_policy_config.rendered}"
}

resource "aws_iam_role_policy_attachment" "attach_pass_through_policy_to_databricks_bucket_role" {
  role = "${var.databricks_deployment_role}"
  policy_arn = "${aws_iam_policy.pass_through_policy.arn}"
}

data "template_file" "pass_through_policy_config" {
  template = "${file("${path.module}/policies/pass_through_policy.template.json")}"
  vars = {
    aws_account_id_databricks = "${data.aws_caller_identity.current.account_id}"
    iam_role_for_s3_access = "${aws_iam_role.databricks_to_s3_role.name}"
  }
}


# User must now enter the IAM Role to Databricks, etc:

data "aws_iam_instance_profile" "databricks_to_s3_role_instance_profile" {
  name = "${aws_iam_role.databricks_to_s3_role.id}"
}

# Use Instance Profiles API to add the new role
data "http" "add_instance_profile_to_databricks" {
  url = "${var.databricks_shard_url}Cust/api/2.0/instance-profiles/add"

  request_headers {
    "Content-Type" = "application/json"
    "Authorization" = "Bearer ${var.databricks_access_token}"
  }

  body = "{ \"instance_profile_arn\": \"${data.aws_iam_instance_profile.databricks_to_s3_role_instance_profile.arn}\" }"
}

# Output the role name so user can attach to cluster:

output "s3_role_name_to_attach" {
  value = "${aws_iam_role.databricks_to_s3_role.name}"
}