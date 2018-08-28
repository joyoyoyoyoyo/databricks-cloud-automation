variable "aws_access_key" {
  type = "string"
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type = "string"
  description = "AWS Secrete Key"
}

variable "aws_region" {
  type = "string"
  description = "The region where AWS operations will take place"
}

variable "foreign_vpc_id" {
  type = "string"
  description = "ID of the VPC to which the Databricks VPC should peer (i.e. the VPC thats not the Databricks VPC)"
}

variable "databricks_vpc_id" {
  type = "string"
  description = "ID of VPC which was used to deploy Databricks. Contact sales@databricks.com for help determining your Databricks VPC ID or deploying a Databricks workspace."
}

variable "port_to_allow" {
  type = "string"
  description = "TCP port to open between VPCs (all inter-VPC traffic will be permitted on this port)"
}