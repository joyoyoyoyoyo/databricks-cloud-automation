# Advanced Guide

This guide provides detailed information for power users and those wishing to contribute new modules.

## User Guide

### Terraform Overview

https://www.terraform.io/intro/index.html

Terraform allows infrastructure configuration to be described with a high-level, declarative syntax called HCL.

Terraform generates an "execution plan" based on the difference between the infrastructure's current state and the desired state as specified by the HCL files.

Terraform will autogenerate a "resource graph" of the desired state which automatically determines the order in which resources should be provisioned.

These features allow terraform to efficiently and easily handle infrastructure compliance as resource plans change or config drifts.

### State

State is stored locally in the `terraform.tfstate` JSON file, separately for each module. This file should not be modified manually. Instead you should interact with it via `terraform state`. You can use this to diagnose state problems or perform "state surgery" if you need to recognize an out-of-band change.

#### Importing existing infrastructure

Terraform by default assumes it needs to create everything in the module from scratch. If you have some resource (like an S3 bucket) that already exists, you should use `terraform import`.


Doing so will inform terraform not to create the resource from scratch, however if some aspect of the resource is out of compliance with the module, terraform may still enact some change

Usage: https://www.terraform.io/docs/import/

#### Managing state of multiple deployments

If managing multiple different deployments, keep in mind that each state file is located by default in the module's directory. You will need to reference/swap other state files to avoid mixing up state tracking.

## Using terraform directly (without the UI):

1. Install terraform. 
	- For generic installation instructions, see https://www.terraform.io/intro/getting-started/install.html.
	- MacOS via brew: `brew install terraform`
	- Linux via wget:
		`wget https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip?_ga=2.244423109.1597180439.1514829700-1217072508.1514829700
		unzip terraform
		mv terraform /usr/local/bin/` 
2. Verify installation via running `terraform`
	(This is also an opportunity to get familiar with terraform's commands)
3. Navigate to `modules` directory. Each directory here represents a terraform module
	- Each module includes a README which describes its purpose
	- Modules can invoke other modules
	- Modules are interpreted by terraform
4. Navigate to a sample module e.g. `cd s3_to_databricks_via_iam`
5. Run `terraform init`
6. Run `terraform apply` and answer the prompt for needed varibles.
7. The resulting "terraform plan" to determine what it will add, modify, or remove. Review this plan carefully

Optional steps:

8. Input `yes` if you would like to execute the plan.
	- Logs will indicate real-time modifications to your infrastructure.
	- If an error occurs, the prior changes will not roll back, but the current state will be for a subsequent `apply`
9. You can save your variables in a JSON file to avoid having to answer the prompt each time you `apply` by using the `-var-file` flag
	- Example: `terraform apply -var-file=/path/to/vars.tfvars`
10. Some modules have extra variables that you weren't prompted for. If you specify them in your tfvars file they will be overwritten. To see the full list of variables for the module, inspect the module's `variables.tf` file.

## Developer Guide

### Root modules vs. submodules

In accordance with the "single responsibility principle" terraform allows modules to invoke other modules. A module inside a module is treated like any other resource entity. The output of the module become its attributes (an attribute is produced instead of specified, such as the ARN of an AWS resource).

We use the term "root module" to refer to one that a user invokes directly and "submodule" to refer to a module invoked by another root module or submodule.

It is encouraged that as you develop new modules you avoid reinventing the wheel and leverage our existing modules as much as possible.

### Module variables

All modules have input referred to as "variables" and output. While these can be declared anywhere, please keep variables in a file `variables.tf` and outputs in a file `outputs.tf` so that consumers of that module can easily see its interface -- both human users and module developers should refer to these files for guidance. This is especially useful as <b>variables with a default value (i.e. overrideable variables) will not be prompted if a `-var-file` is not provided and thus can only be determined by inspecting the `variables.tf` file</b>

### Contributing

All changes should be submitted via a detailed GitHub Pull Request to the `master` branch. PRs are more likely to get approved if they correspond to an open, reviewed issue.

There are a number ways you can help to make this project great.

- Contribute to module READMEs:
	- Give an example use case where you've used the module successfully
	- Describe side effects or any "gotchas" that you found in your environment that we might have missed

- Improve flexibility to your environment
	- As adoption grows, we will inevitably encounter new cloud environments and scenarios that are currently unsupported or fall outside the module's current scope. While we would like to support every edge case ourselves and make the modules support all environments, you can help us add support for your edge case by submitting a patch with associated test cases. This will ensure that we support your use case in the long run and minimize future regressions. Ultimtely, edge case support will skew towards environments with the most external PRs, so your contributions are the most effective way to ensure your ennvironment is supported as our project grows to support more use cases.

- Develop new modules:
	- Create new root modules that leverage the existing submodules - for example an Aurora connector would leverage the existing vpc_peer_to_databricks module
	- Create a new submodule to be levaraged by new root modules - for example there are many pages in the Databricks docs that describe low-level tasks like IAM authentication via roles and access keys. This is a low-hanging fruit for new contributors!


If you have questions about getting involved or have an idea for a new module, reach out to sales@databricks.com.
