provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

# This is only initialized if the connection is cross account.
# In this case the "foreign"
# account refers to the account that is not the account hosting the
# Databricks data plane account. If both VPCs are in the same account,
# then the above "default" (aka non-aliased) provider is used for all resources
# in this module 
provider "aws" {
  alias      = "foreign_acct"
  region     = "${var.aws_foreign_acct_region != "" ? var.aws_foreign_acct_region : var.aws_region}"
  access_key = "${var.aws_foreign_acct_access_key != "" ? var.aws_foreign_acct_access_key : var.aws_access_key}"
  secret_key = "${var.aws_foreign_acct_secret_key != "" ? var.aws_foreign_acct_secret_key : var.aws_secret_key}"
  version    = "~>1.52.0"
}

locals {
  multi_account = "${var.aws_foreign_acct_access_key == "" ? 0 : 0}"
}

data "aws_caller_identity" "foreign" {
  provider = "aws.foreign_acct"
}

# Get VPC of foreign deployment
data "aws_vpc" "foreign_vpc" {
  provider = "aws.foreign_acct"
  id = "${var.foreign_vpc_id}"
}

# Get VPC of the Databricks deployment
data "aws_vpc" "databricks_vpc" {
  id = "${var.databricks_vpc_id}"
}

# Get existing route table associated with the databricks vpc id
data "aws_route_table" "db_vpc_rt" {
  vpc_id = "${data.aws_vpc.databricks_vpc.id}"
}

# Get existing route table this time associated with the foreign vpc
data "aws_route_table" "foreign_vpc_rt" {
  provider = "aws.foreign_acct"
  vpc_id = "${data.aws_vpc.foreign_vpc.id}"
}

# Establish the VPC connection
resource "aws_vpc_peering_connection" "foreign_vpc_to_db_vpc" {
  vpc_id = "${data.aws_vpc.foreign_vpc.id}"
  peer_vpc_id = "${data.aws_vpc.databricks_vpc.id}"
  auto_accept = "${local.multi_account}" # Only works if both VPCs are in the same account - if we support cross acounts we'll need an acceptor resource

  peer_region = "${var.aws_foreign_acct_region}"
  peer_owner_id = "${data.aws_caller_identity.foreign.account_id}"

  accepter {
      allow_remote_vpc_dns_resolution = true
  }
}

# Only create if multi account. Otherwise auto accept on peering is sufficient
resource "aws_vpc_peering_connection_accepter" "acceptor" {
  count = "${local.multi_account ? 1 : 0}"
  provider = "aws.foreign_acct"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.foreign_vpc_to_db_vpc.id}"
  auto_accept = true
}

# Add route to the existing Databricks VPC route table allowing foreign CIDR
resource "aws_route" "databricks_new_dest_route" {
  route_table_id = "${data.aws_route_table.db_vpc_rt.route_table_id}" # Reference to the existing

  destination_cidr_block = "${data.aws_vpc.foreign_vpc.cidr_block}" # The CIDR block used by the existing foreign VPC
  vpc_peering_connection_id = "${aws_vpc_peering_connection.foreign_vpc_to_db_vpc.id}" # The id of the peering connection
}

# Add route to the existing foreign VPC route table allowing Databricks CIDR
resource "aws_route" "foreign_new_dest_route" {
  provider = "aws.foreign_acct"
  route_table_id = "${data.aws_route_table.foreign_vpc_rt.route_table_id}"

  destination_cidr_block = "${data.aws_vpc.databricks_vpc.cidr_block}" # CIDR of existing Databricks VPC
  vpc_peering_connection_id = "${aws_vpc_peering_connection.foreign_vpc_to_db_vpc.id}"
}


### 4 ### Add rule to foreign security group allowing Databricks unmanaged access

# Look up existing sg associated with the foreign VPC
# data "aws_security_group" "foreign_sg" {
  # vpc_id = "${data.aws_vpc.foreign_vpc.id}" # Assumes only one sg for vpc
# }

# Look up existing unmanaged sg associated with the Databricks VPC
data "aws_security_group" "databricks_unmanaged_sg" {
  # Select only the unmanaged group - note that naming convention differs based on multi vs single tenant deployments.
  # Empty enterprise_workspace_id means multitenant
  name = "${ var.enterprise_workspace_id == "" ? "${data.aws_vpc.databricks_vpc.tags.Name}-worker-unmanaged" : "dbe-worker-${var.enterprise_workspace_id}-worker-unmanaged" }"
  vpc_id = "${data.aws_vpc.databricks_vpc.id}"
}

# Add a new rule to allow TCP port ingress to the existing unmanaged Databricks VPC security group
resource "aws_security_group_rule" "ingress_from_foreign_rule" {
  security_group_id = "${data.aws_security_group.databricks_unmanaged_sg.id}"

  source_security_group_id = "${var.foreign_sg_id}"
  type = "ingress"
  protocol = "tcp"
  from_port = "${var.port_to_allow}"
  to_port = "${var.port_to_allow}"
}