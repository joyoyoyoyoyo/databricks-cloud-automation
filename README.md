Connect to existing Redshift from Databricks
dillon.bostwick@databricks.com

1. Install terraform (brew, apt-get, yum, etc. or https://www.terraform.io/intro/getting-started/install.html)
2. cd this directory
3. `terraform init`
4. `terraform apply`

For ease of use you may store variables in either .tfvars or .json form, and pass using -var-file

Update graph with `terraform graph | dot -Tsvg > graph.svg`
