# dillon.bostwick@databricks.com

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
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
  databricks_access_token = "${var.databricks_access_token}"
  custom_iam_role_name = "${var.custom_iam_role_name_for_s3_conection}"

  s3_bucket_name = "${aws_s3_bucket.unload_bucket.bucket}"
}

### 2 ### Create role for Redshfit to access the unload bucket:

# Get existing Redshift cluster
data "aws_redshift_cluster" "existing_cluster" {
  cluster_identifier = "${var.redshift_cluster_id}"
}

# Establish role with AmazonS3ReadOnlyAccess
resource "aws_iam_role" "redshift_unload_bucket_role" {
  name = "${var.custom_unload_bucket_name}"
  assume_role_policy = "${file("${path.module}/policies/assume_role_policy.json")}"

  # Attach role to existing Redshift cluster:
  provisioner "local-exec" {
    command = "python attach_role_to_cluster.py"
    environment {
      "CLUSTER_ID" = "${data.aws_redshift_cluster.existing_cluster.id}"
      "ROLE_ARN" = "${aws_iam_role.redshift_unload_bucket_role.arn}"
    }
  }
}

# Apply the existing aws policy, AmazonS3ReadOnlyAccess, to the new role
resource "aws_iam_role_policy_attachment" "attach_s3_permissions_to_redshift_role" {
  role = "${aws_iam_role.redshift_unload_bucket_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


### 3 ### Establish VPC peering and new routes

# Establish peering and open 5439
module "vpc_peer_to_databricks" {
  source = "../vpc_peer_to_databricks"

  # Pass through vars
  aws_access_key = "${var.aws_access_key}"
  aws_secret_key = "${var.aws_secret_key}"
  aws_region = "${var.aws_region}"

  foreign_vpc_id = "${data.aws_redshift_cluster.existing_cluster.vpc_id}"
  databricks_shard_name = "${var.databricks_shard_name}"
  port_to_allow = 5439
}
