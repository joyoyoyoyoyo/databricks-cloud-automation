# Attach IAM role to Redshift cluster using boto3
# This may be used as a temporary workaround as Terraform does not allow for add/delete individual IAM roles to/from Redshift cluster

import sys
import boto3

def attach_role_to_cluster(access_key, access_secret, region, cluster_identifier, role_arn):
	redshift_client = boto3.client(
		'redshift',
		aws_access_key_id=access_key,
		aws_secret_access_key=access_secret
	)

	return redshift_client.modify_cluster_iam_roles(
		ClusterIdentifier=cluster_identifier,
		AddIamRoles=[
			role_arn
		]
	)


if __name__ == '__main__':
	print('Begin attach_role_to_cluster')

	access_key, access_secret, region, cluster_identifier, role_arn = sys.argv[1:]
	res = attach_role_to_cluster(access_key, access_secret, region, cluster_identifier, role_arn)

	if res['ResponseMetadata']['HTTPStatusCode'] != 200:
		print('attach_role_to_cluster failed with response:', res)
		raise SystemExit(1)
	else:
		print('attach_role_to_cluster succeeded with response:', res)