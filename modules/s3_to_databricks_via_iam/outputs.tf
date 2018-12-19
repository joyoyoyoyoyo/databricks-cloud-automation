# Output instance profile to add to Databricks:

output "s3_role_instance_profile" {
  value = "${data.aws_iam_instance_profile.databricks_to_s3_role_instance_profile.arn}"
}

# Output the role name so user can attach to cluster:

output "s3_role_name_to_attach" {
  value = "${aws_iam_role.databricks_to_s3_role.name}"
}

output "Walkthrough" {
  value = "Please add this instance profile to your Databricks workspace by navigating to the Admin Console and selecting 'IAM Roles'. When completed, apply the IAM Role to clusters as needed."
}

output "Additional_walkthrough_for_multi_account" {
  value = "${local.multi_account ? file("${path.module}/txt/multi_account_walkthrough.txt") : "N/A"}"
}
