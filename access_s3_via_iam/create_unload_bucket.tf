# dillon.bostwick@databricks.com

provider "aws" {
  alias = "customerDataAwsAccount" # alias is needed to distinguish in case we are working with more aws accounts
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

data "aws_caller_identity" "current" {} # Needed to declare to later 



# Set up the unload bucket with appropriate policy:

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

resource "aws_s3_bucket_policy" "unload_bucket_policy" {
  bucket = "${aws_s3_bucket.unload_bucket.id}"
  policy = "${data.template_file.unload_bucket_policy.rendered}"
}

data "template_file" "unload_bucket_policy" {
  template = "${file("${path.module}/policies/unload_bucket_policy.template.json")}"
  vars = {
    aws_account_id = "${data.aws_caller_identity.current.account_id}"
    s3_cross_account_role = "${aws_iam_role.unload_role.id}"
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

# Need to explicitally specify the instance profile for the role as well
resource "aws_iam_instance_profile" "unload_role_instance_profile" {
  name = "${aws_iam_role.unload_role.name}"
  role = "${aws_iam_role.unload_role.name}"
}

# Attach an inline policy to the role
resource "aws_iam_policy" "unload_role_policy" {
  name = "unload_policy"
  policy = "${data.template_file.unload_policy_config.rendered}"
}

resource "aws_iam_role_policy_attachment" "attach_unload_policy_to_unload_role" {
  role = "${aws_iam_role.unload_role.id}"
  policy_arn = "${aws_iam_policy.unload_role_policy.arn}"
}

# Interpolate the role inline policy config template
data "template_file" "unload_policy_config" {
  template = "${file("${path.module}/policies/unload_role_policy.template.json")}"
  vars = {
    unload_bucket_name = "${aws_s3_bucket.unload_bucket.id}"
  }
}





# Set up pass through from the shard role:

# New policy gets added to the existing Databricks EC2 role:
resource "aws_iam_policy" "pass_through_policy" {
  name = "ec2-pass-to-unload-role"
  description = "Allow EC2 pass through to unload IAM role"
  policy = "${data.template_file.pass_through_policy_config.rendered}"
}

resource "aws_iam_role_policy_attachment" "attach_pass_through_policy_to_unload_role" {
  role = "${var.db_deployment_role}"
  policy_arn = "${aws_iam_policy.pass_through_policy.arn}"
}

data "template_file" "pass_through_policy_config" {
  template = "${file("${path.module}/policies/pass_through_policy.template.json")}"
  vars = {
    aws_account_id_databricks = "${data.aws_caller_identity.current.account_id}"
    iam_role_for_s3_access = "${aws_iam_role.unload_role.name}"
  }
}







# User must now enter the IAM Role, etc:

data "aws_iam_instance_profile" "unload_role_instance_profile" {
  name = "${aws_iam_role.unload_role.id}"
}
# data.aws_iam_instance_profile.unload_role_instance_profile.arn

output "result" {
  value = "Databricks > Admin Console > IAM roles > Add IAM Role > Enter the following: '${aws_iam_instance_profile.unload_role_instance_profile.arn}'\n To test, attach the IAM role to a cluster and run: 'dbutils.fs.ls('s3a://${aws_s3_bucket.unload_bucket.id}')'"
}







# TODO:
# https://docs.databricks.com/administration-guide/cloud-configurations/aws/iam-roles.html#id6
# Steps 5, 6, 7



