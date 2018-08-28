provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

# Get VPC of foreign deployment
data "aws_vpc" "foreign_vpc" {
  id = "${var.foreign_vpc_id}"
}

# Get VPC of the Databricks deployment
data "aws_vpc" "databricks_vpc" {
  tags = {
    Name = "${var.databricks_workspace_name}"
  }
}

# Get existing route table associated with the databricks vpc id
data "aws_route_table" "db_vpc_rt" {
  vpc_id = "${data.aws_vpc.databricks_vpc.id}"
}

# Get existing route table this time associated with the foreign vpc
data "aws_route_table" "foreign_vpc_rt" {
  vpc_id = "${data.aws_vpc.foreign_vpc.id}"
}

# Establish the VPC connection
resource "aws_vpc_peering_connection" "foreign_vpc_to_db_vpc" {
  vpc_id = "${data.aws_vpc.foreign_vpc.id}"
  peer_vpc_id = "${data.aws_vpc.databricks_vpc.id}"
  auto_accept = true # Only works if both VPCs are in the same account - if we support cross acounts we'll need an acceptor resource

  accepter {
      allow_remote_vpc_dns_resolution = true
  }
}

# Add route to the existing Databricks VPC route table allowing foreign CIDR
resource "aws_route" "databricks_new_dest_route" {
  route_table_id = "${data.aws_route_table.db_vpc_rt.route_table_id}" # Reference to the existing

  destination_cidr_block = "${data.aws_vpc.foreign_vpc.cidr_block}" # The CIDR block used by the existing foreign VPC
  vpc_peering_connection_id = "${aws_vpc_peering_connection.foreign_vpc_to_db_vpc.id}" # The id of the peering connection
}

# Add route to the existing foreign VPC route table allowing Databricks CIDR
resource "aws_route" "foreign_new_dest_route" {
  route_table_id = "${data.aws_route_table.foreign_vpc_rt.route_table_id}"

  destination_cidr_block = "${data.aws_vpc.databricks_vpc.cidr_block}" # CIDR of existing Databricks VPC
  vpc_peering_connection_id = "${aws_vpc_peering_connection.foreign_vpc_to_db_vpc.id}"
}


### 4 ### Add rule to foreign security group allowing Databricks unmanaged access

# Look up existing sg associated with the foreign VPC
data "aws_security_group" "foreign_sg" {
  vpc_id = "${data.aws_vpc.foreign_vpc.id}" # Assumes only one sg for vpc
}

# Look up existing unmanaged sg associated with the Databricks VPC
data "aws_security_group" "databricks_unmanaged_sg" {
  name = "${data.aws_vpc.databricks_vpc.tags.Name}-worker-unmanaged" # Select only the unmanaged group
  vpc_id = "${data.aws_vpc.databricks_vpc.id}"
}

# Add a new rule to allow TCP 5439 ingress to the existing unmanaged Databricks VPC security group
resource "aws_security_group_rule" "ingress_from_foreign_rule" {
  security_group_id = "${data.aws_security_group.databricks_unmanaged_sg.id}"

  source_security_group_id = "${data.aws_security_group.foreign_sg.id}"
  type = "ingress"
  protocol = "tcp"
  from_port = "${var.port_to_allow}"
  to_port = "${var.port_to_allow}"
}