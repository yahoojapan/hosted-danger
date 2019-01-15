# Hosted Danger

<p align="center">
  <i>:zap: Accelerate your pull requests by awesome automations :zap:</i>
</p>

Hosted Danger helps agressive automations for your pull requests especially for assigning reviewers, checking CI statuses and merging.
Hosted Danger executes [danger](https://github.com/danger/danger) internally. The differences of original danger are "when" and "what" to be executed.

- :heavy_check_mark: **When**: Hosted Danger is detached from CI processes. So danger can be executed interactively. (It's reacted for Github Webhooks.)
- :heavy_check_mark: **What**: It cannot refer the source codes and build products basically. It's specialized for Pull Requests automations, not for showing results of lints, tests or coverages.

:rocket: The Hosted Danger is activated on **more than 1500 repositoies** in Yahoo! JAPAN. :rocket:

## About This Repository
This repository includes
- [A server of Hosted Danger](/src)
- [A fork of danger/danger as 'no_fetch_danger'](/no_fetch_danger)
- [A set of plugins](/plugins)

## Docs
- [Concept](/docs/concept.md)
- [Launch Server](/docs/launch_server.md)
- [Setup Repository](/docs/setup_repository.md)
- [Examples of Dangerfile](/docs/example_of_dangerfile.md)

## Contribution

This project requires contributors to agree to a [CLA (Contributor License Agreement)](https://gist.github.com/ydnjp/3095832f100d5c3d2592).

Note that only for contributions to the Hosted Danger repository on the GitHub (https://github.com/yahoojapan/hosted-danger), the contributors of them shall be deemed to have agreed to the CLA without individual written agreements.
