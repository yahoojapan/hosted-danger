<h1 align="center">
  <img src="https://user-images.githubusercontent.com/3483230/53308591-f0cace80-38e5-11e9-9e56-3b64b28a27ba.png" width="540"/>
</h1>

<p align="center">
  <a href="https://circleci.com/gh/yahoojapan/hosted-danger">
    <img src="https://img.shields.io/circleci/project/github/yahoojapan/hosted-danger.svg?style=flat-square"/>
  </a>

  <a href="https://github.com/yahoojapan/hosted-danger/issues">
    <img src="https://img.shields.io/github/issues/yahoojapan/hosted-danger.svg?style=flat-square"/>
  </a>

  <a href="https://github.com/yahoojapan/hosted-danger/pulls">
    <img src="https://img.shields.io/github/issues-pr/yahoojapan/hosted-danger.svg?style=flat-square"/>
  </a>
  
  <a href="https://github.com/yahoojapan/hosted-danger/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/yahoojapan/hosted-danger.svg?style=flat-square"/>
  </a>
</p>

<p align="center">
  <i>:zap: Accelerate your pull requests by awesome automations :zap:</i>
</p>

Hosted Danger helps agressive automations for your pull requests especially for assigning reviewers, checking CI statuses and merging.
Hosted Danger executes [danger](https://github.com/danger/danger) internally. In other words, it's a **Danger As A Service**. The differences of original danger are "when" and "what" to be executed.

- :heavy_check_mark: **When**: Hosted Danger is detached from CI processes. So danger can be executed interactively. (It's reacted for Github Webhooks.)
- :heavy_check_mark: **What**: It cannot refer the source codes and build products basically. It's specialized for Pull Requests automations, not for showing results of lints, tests or coverages.

:rocket: The Hosted Danger is activated on **more than 1500 repositoies** in Yahoo! JAPAN. :rocket:

<i>[danger/danger](https://github.com/danger/danger) is really awesome OSS. I would like to send a big respect for @orta.</i>

## About This Repository
This repository includes
- [A server of Hosted Danger](/src)
- [A set of plugins](/plugins)

## Docs
- [Concept](/docs/concept.md)
- [Launch Server](/docs/launch_server.md)
- [Setup Repository](/docs/setup_repository.md)
- [Examples of Dangerfile](/docs/example_of_dangerfile.md)

## Contribution

This project requires contributors to agree to a [CLA (Contributor License Agreement)](https://gist.github.com/ydnjp/3095832f100d5c3d2592).

Note that only for contributions to the Hosted Danger repository on the GitHub (https://github.com/yahoojapan/hosted-danger), the contributors of them shall be deemed to have agreed to the CLA without individual written agreements.
