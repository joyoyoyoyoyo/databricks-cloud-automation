# Contributing

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
