# dillon.bostwick@databricks.com

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

# Get existing Redshift cluster
data "aws_redshift_cluster" "existing_cluster" {
  cluster_identifier = "${var.redshift_cluster_id}"
}

### 1 ### Create unload bucket for query results:

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

# Establish access between Databricks and the bucket
module "s3_to_databricks_via_iam" {
  source = "../s3_to_databricks_via_iam"

  # Pass through vars
  aws_access_key = "${var.aws_access_key}"
  aws_secret_key = "${var.aws_secret_key}"
  aws_region = "${var.aws_region}"
  databricks_deployment_role = "${var.databricks_deployment_role}"
  custom_iam_role_name = "${var.custom_iam_role_name_for_s3_conection}"
  # databricks_workspace_url = "${var.databricks_workspace_url}"
  # databricks_access_token = "${var.databricks_access_token}"
  
  aws_foreign_acct_access_key = "${var.aws_foreign_acct_access_key}"
  aws_foreign_acct_secret_key = "${var.aws_foreign_acct_secret_key}"
  aws_foreign_acct_region = "${var.aws_foreign_acct_region}"

  s3_bucket_name = "${aws_s3_bucket.unload_bucket.id}"
}

### 2 ### Create role for Redshfit to access the unload bucket:

# Establish role with AmazonS3ReadOnlyAccess
resource "aws_iam_role" "redshift_unload_bucket_role" {
  name = "${var.custom_unload_bucket_name}"
  assume_role_policy = "${file("${path.module}/policies/assume_role_policy.json")}"
}

# Apply the existing aws policy, AmazonS3ReadOnlyAccess, to the new role
resource "aws_iam_role_policy_attachment" "attach_s3_permissions_to_redshift_role" {
  role = "${aws_iam_role.redshift_unload_bucket_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Attach role to redshift cluster
# Note this is a temporary workaround until Terraform supports adding/removing single
# roles to Redshift clusters
resource "null_resource" "attach_role_to_cluster" {
  # If the role and/or cluster changes, reapply the python script
  triggers {
    unload_role = "${aws_iam_role.redshift_unload_bucket_role.name}"
    cluster_id = "${data.aws_redshift_cluster.existing_cluster.id}"
  }

  provisioner "local-exec" {
    command = <<EOF
    python ${path.module}/attach_role_to_cluster/main.py\
    ${var.aws_access_key}\
    ${var.aws_secret_key}\
    ${var.aws_region}\
    ${data.aws_redshift_cluster.existing_cluster.id}\
    ${aws_iam_role.redshift_unload_bucket_role.arn}
    EOF
  }
}

### 3 ### Establish VPC peering and new routes

# Establish peering and open 5439
module "vpc_peer_to_databricks" {
  source = "../vpc_peer_to_databricks"

  # Pass through vars
  aws_access_key = "${var.aws_access_key}"
  aws_secret_key = "${var.aws_secret_key}"
  aws_region = "${var.aws_region}"

  aws_foreign_acct_access_key = "${var.aws_foreign_acct_access_key}"
  aws_foreign_acct_secret_key = "${var.aws_foreign_acct_secret_key}"
  aws_foreign_acct_region = "${var.aws_foreign_acct_region}"

  foreign_vpc_id = "${data.aws_redshift_cluster.existing_cluster.vpc_id}"
  databricks_vpc_id = "${var.databricks_vpc_id}"
  foreign_sg_id = "${data.aws_redshift_cluster.existing_cluster.vpc_security_group_ids.0}"
  enterprise_workspace_id = "${var.enterprise_workspace_id}"

  port_to_allow = 5439
}
