# Pass through the local value so user can see which name to attach to their Databricks clusters
output "s3_role_name_to_attach" {
  value = "${module.s3_to_databricks_via_iam.s3_role_name_to_attach}"
}

output "s3_role_instance_profile" {
  value = "${module.s3_to_databricks_via_iam.s3_role_instance_profile}"
}

output "Walkthrough" {
  value ="Please add this instance profile to your Databricks workspace by navigating to the Admin Console and selecting 'IAM Roles'. When completed, apply the IAM Role to clusters as needed."
}