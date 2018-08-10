# dillon.bostwick@databricks.com

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}" # TODO infer the region from the shard name?
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

# Output role to then be attached to the existing Redshift cluster TODO figure out how to do this
output "role_arn_to_attach" {
  value = "${aws_iam_role.redshift_unload_bucket_role.arn}"
} 


### 3 ### Establish VPC peering and new routes

# Get existing Redshift cluster
data "aws_redshift_cluster" "existing_cluster" {
  cluster_identifier = "${var.redshift_cluster_id}"
}

# Get VPC of Redshift deployment
data "aws_vpc" "redshift_vpc" {
  id = "${data.aws_redshift_cluster.existing_cluster.vpc_id}"
}

# Get VPC of the Databricks deployment
data "aws_vpc" "databricks_vpc" {
  tags = {
    Name = "${var.databricks_shard_name}"
  }
}

# Get existing route table associated with the databricks vpc id
data "aws_route_table" "db_vpc_rt" {
  vpc_id = "${data.aws_vpc.databricks_vpc.id}"
}

# Get existing route table this time associated with the Redshift vpc
data "aws_route_table" "redshift_vpc_rt" {
  vpc_id = "${data.aws_vpc.redshift_vpc.id}"
}

# Establish the VPC connection
resource "aws_vpc_peering_connection" "redshift_vpc_to_db_vpc" {
  vpc_id = "${data.aws_vpc.redshift_vpc.id}"
  peer_vpc_id = "${data.aws_vpc.databricks_vpc.id}"
  auto_accept = true # Only works if both VPCs are in the same account - if we support cross acounts we'll need an acceptor resource

  accepter {
      allow_remote_vpc_dns_resolution = true
  }
}

# Add route to the existing Databricks VPC route table allowing Redshift CIDR
resource "aws_route" "databricks_new_dest_route" {
  route_table_id = "${data.aws_route_table.db_vpc_rt.route_table_id}" # Reference to the existing

  destination_cidr_block = "${data.aws_vpc.redshift_vpc.cidr_block}" # The CIDR block used by the existing Redshift VPC
  vpc_peering_connection_id = "${aws_vpc_peering_connection.redshift_vpc_to_db_vpc.id}" # The id of the peering connection
}

# Add route to the existing Redshift VPC route table allowing Databricks CIDR
resource "aws_route" "redshift_new_dest_route" {
  route_table_id = "${data.aws_route_table.redshift_vpc_rt.route_table_id}"

  destination_cidr_block = "${data.aws_vpc.databricks_vpc.cidr_block}" # CIDR of existing Databricks VPC
  vpc_peering_connection_id = "${aws_vpc_peering_connection.redshift_vpc_to_db_vpc.id}"
}


### 4 ### Add rule to Redshift security group allowing Databricks unmanaged access

# Look up existing sg associated with the Redshift VPC
data "aws_security_group" "redshift_sg" {
  vpc_id = "${data.aws_vpc.redshift_vpc.id}" # Assumes only one sg for vpc
}

# Look up existing unmanaged sg associated with the Databricks VPC
data "aws_security_group" "databricks_unmanaged_sg" {
  name = "dbe-worker-849931139926137-8a0a62e5-0ede-47f6-a58e-c0136240f006-unmanaged"
  # name = "${data.aws_vpc.databricks_vpc.tags.Name}-worker-unmanaged" # Select only the unmanaged group
  vpc_id = "${data.aws_vpc.databricks_vpc.id}"
}

# Add a new rule to allow TCP 5439 ingress to the existing unmanaged Databricks VPC security group
resource "aws_security_group_rule" "ingress_from_redshift_rule" {
  security_group_id = "${data.aws_security_group.databricks_unmanaged_sg.id}"

  source_security_group_id = "${data.aws_security_group.redshift_sg.id}"
  type = "ingress"
  protocol = "tcp"
  from_port = 5439
  to_port = 5439
}
