# Databricks Cloud Automation Modules
<i>Simplify, accelerate, and secure Databricks cloud deployments</i>

## Introduction

This project aims to reduce the time it takes to deliver and troubleshoot common cloud workloads and scenarios with Databricks. 

## Quick Start

1. `git clone https://github.com/databricks/databricks-cloud-automation.git`
2. `cd databricks-cloud-automation`
3. `pip install databricks-cloud-automation`
4. `databricks-cloud-manager`
5. Open a browser and navigate to `localhost:5000`. Select a module to begin

---

### Notes:

To report an issue or feature request, please use the Github Issues tracker

To learn how to contribute a new module, check out the [advanced guide](https://github.com/databricks/databricks-cloud-automation/tree/master/docs/advanced-guide.md)

When providing access/secret keys to use a module on a given cloud provider, it is recommended that you create a new role that is locked down to only make the changes (creates and updates, primarily) necessary. For example, if you are creating a connection to AWS Redshift, you should allow DescribeClusters permission without any Write access level permissions.

#### Disclaimers
- The UI server is only intended to be run locally by using the databricks-cloud-automation CLI command. It is not intended to be run as a web service.
- Databricks does not provide formal support or SLA for this project.