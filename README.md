# Databricks Field Engineering Cloud Automation Modules

## Introduction

The purpose of this project is to reduce the time it takes to deliver and troubleshoot common cloud workloads and scenarios with Databricks. 

## Installation and Quick Start

1. Install terraform. 
	- For generic installation instructions, see https://www.terraform.io/intro/getting-started/install.html.
	- On MacOS, you may run `brew install terraform`
	- On Linux, you may run:
		`wget https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip?_ga=2.244423109.1597180439.1514829700-1217072508.1514829700
		unzip terraform
		mv terraform /usr/local/bin/` 
2. Verify terraform installation by running `terraform`. This is also an opportunity to get familiar with terraform's commands.
3. Navigate to the `modules` directory. Each directory here represents a terraform module.
	Key points:
	- Each module should include a README which describes its purpose and use.
	- Note that some modules invoke other modules (in this case we call the invoker a "root module" and the invoked a "submodule").
	- Modules do not need to be installed; they are interpreted by terraform.
4. Select the module you wish to use and navigate to it using the `cd` command
5. Run `terraform init` to install prerequisite dependencies
6. Run `terraform apply`. Without any flags, it will begin to prompt you for needed parameters.
7. Inspect the resulting "terraform plan" to determine what it will add, modify, or remove.
8. (optional) Input `yes` if you would like to execute the plan. Logs will indicate real-time modifications to your infrastructure. If an error occurs, the prior changes will not roll back, but the current state will be saved so that when you perform a subsequent `apply`, the plan will reflect only the remaining changes and will not re-execute what has already been applied.

9.  Now that you have an idea of which variables are needed, you can store these as JSON or HCL in a file such as `my-vars.tfvars` and reference them with `terraform apply -var-file=vars.tfvars`.
	- Naming your file `terraform.tfvars` will cause it to load automatically.

## Advanced Guide

### terraform overview

todo

### State

State is stored locally in the `terraform.tfstate` JSON file, separately for each module. This file should (almost) never be modified manually. It is also advised that you interact with it via `terraform state` commands as oppose to accessing the file directly. Nonetheless it is a useful diagnosis tool.

#### Importing existing infrastructure

Terraform will try to create everything by default, as it. For this reason it is useful to import a resource that already exists in your infrastructure into terraform's current state. Doing so will inform terraform not to create the resource from scratch, however if some aspect of the resource is out of compliance with the module, terraform may still enact some change.

For example, say you already have a VPC peering connection and your module requires one. You don't want terraform to create a new, redundant VPC peering connection, so you choose to import the existing VPC peering into state. However, there are some modifications to the peering config that the module requires. In this case terraform will modify the existing peering instead of trying to create a new one.

Usage: https://www.terraform.io/docs/import/

#### Managing state of multiple deployments

State file is by default located in each module directory directory. Keep this in mind if managing multiple different deployments of the same module. You may need to reference or swap out different state files for each deployment instance.

In addition, you should ensure that you do not remove existing state file or use the wrong state file. If this happens you can use `terraform inport` to sync from the actual infrastructure state.

### Modules

#### Root modules vs. submodules

todo

#### Module variables

todo

## Contributing

Please submit a detailed GitHub Pull Request for any changes. PRs are more likely to get approved if they correspond to an open, reviewed issue.

There are a number ways you can help to make this project great.

- Contribute to module READMEs:
	- Give an example use case where you've used the module successfully
	- Describe side effects or any "gotchas" that you found in your environment that we might have missed

- Improve flexibility to your environment
	- As adoption grows, we will inevitably encounter new cloud environments and scenarios that are currently unsupported or fall outside the module's current scope. While we would like to support every edge case ourselves and make the modules support all environments, you can help us add support for your edge case by submitting a patch with associated test cases. This will ensure that we support your use case in the long run and minimize future regressions. Ultimtely, edge case support will skew towards environments with the most external PRs, so your contributions are the most effective way to ensure your ennvironment is supported as our project grows to support more use cases.

- Develop new modules:
	- Create new root modules that leverage the existing submodules - for example an Aurora connector would leverage the existing vpc_peer_to_databricks module
	- Create a new submodule to be levaraged by new root modules - for example there are many pages in the Databricks docs that describe low-level tasks like IAM authentication via roles and access keys. This is a low-hanging fruit for new contributors!


If you have questions about getting involved or have an idea for a new module, reach out to field-eng@databricks.com or dillon.bostwick@databricks.com
