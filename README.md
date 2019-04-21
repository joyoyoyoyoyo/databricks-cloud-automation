# Databricks Cloud Automation Modules
<i>Simplify, accelerate, and secure Databricks cloud deployments</i>

## Introduction

This project aims to reduce the time it takes to deliver and troubleshoot common cloud workloads and scenarios with Databricks. 

## Quick Install

1. `git clone https://github.com/databricks/databricks-cloud-automation.git`
2. `cd databricks-cloud-automation`
3. `pip install .`

## Using the Terraform modules

[Terraform](https://www.terraform.io/intro/index.html) is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions. Each Terraform module is located in the `modules` directory. You will interface primarily with each module through the `terraform` CLI utility. To familiarize yourself with using these terraform modules, see their [getting started guide](https://learn.hashicorp.com/terraform/getting-started/build). As you become more familiar with our modules our you would like to contribute a new module, you may find our `docs/advanced-guide.md` useful.

## Using the GUI

We provide a UI to simplify using the Terraform modules. Instead of passing variables to the module and creating plans to execute a module, instead you will pass variables through a browser based form. While this reduces the learning curve for those new to Terraform, the tradeoff is loss in some of the flexibility and functionality of the Terraform utility. For example, advanced features like deploying multiple states for the same module, importing a pre-deployed existing resource into a state, or modifying a module to tailor it to your specific deployment are not possible through the UI and instead should be handled directly through the Terraform CLI.

To use the GUI, add 2 more steps to the installation:

4. `databricks-cloud-manager`
5. Open a browser and navigate to `localhost:5000`. Select a module to begin

---

### Notes:

To report an issue or feature request, please use the Github Issues tracker

When providing access/secret keys to use a module on a given cloud provider, it is recommended that you create a new role that is locked down to only make the changes (creates and updates, primarily) necessary. For example, if you are creating a connection to AWS Redshift, you should allow DescribeClusters permission without any Write access level permissions.

#### Disclaimers
- The UI server is only intended to be run locally by using the databricks-cloud-automation CLI command. It is not intended to be run as a web service.
- Databricks does not provide formal support or SLA for this project.
