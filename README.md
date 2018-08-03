Connect to existing Redshift from Databricks
dillon.bostwick@databricks.com

0. Install terraform (brew, apt-get, yum, etc. or https://www.terraform.io/intro/getting-started/install.html)
1. cd this directory
2. `terraform init`
3. `terraform apply`

For ease of use you may store variables in either .tfvars or .json form, and pass using -var-file

`terraform graph | dot -Tsvg > graph.svg`