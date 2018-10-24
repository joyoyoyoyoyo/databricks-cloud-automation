## Description:

Generic implementation of a VPC peering between Databricks and another ("foreign") VPC.

This includes the peering itself, configuring route tables, and updating security groups

## Exampe Use Cases:

- Access an existing Database or AWS service in a VPC, including but not limited to:
	- Redshift
	- RDS
	- Kafka
	- Cassandra
	- EMR / Hive Metastore
	- Aurora

## Scope:

This module is closely based off the existing documentation:
https://docs.databricks.com/administration-guide/cloud-configurations/aws/vpc-peering.html
This module can be used as an automated alternative to this documentation.

- This module assumes that the "foreign" VPC already exists. It will not attempt to create the VPC if it is not found.