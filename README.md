# Hosted Danger

<i>Accelerate your pull requests by automations</i>

Hosted Danger helps agressive automations for your Pull Requests especially for assigning reviewers, checking CI statuses and merging pull requests.
Hosted Danger hosts [danger](https://github.com/danger/danger), so it executes danger internally.
The difference is "when" and "what" to be executed.

- **When**: Hosted Danger is detached from CI process. So danger can be executed interactively. (It's reacted for Github Webhooks.)
- **What**: Since it's detached from CI, it cannot refer the source codes and build products basically. It's specialized for Pull Requests automations, not for showing results of lints, tests or coverages.

The Hosted Danger is activated on **more than 1500 repositoies** in Yahoo! JAPAN.

## Indices
- [Quick Start](/quick_start.md)
- [Use Cases](/basic_examples.md)

## Details of Cencept

### An Example of Legacy Pull Request Flow
<img src="https://user-images.githubusercontent.com/3483230/46455263-2b23ba00-c7e5-11e8-842d-180ac8503799.png" />

In this flow, the coder have to assign reviewers and merge pull request.
Before them, the coder have to check CI status.
To do so, the coder have to wait completion of CI processes.
Even if there is notification for it, the coder have to go back to the pull request page at least.

### With Hosted Danger
<img src="https://user-images.githubusercontent.com/3483230/46455255-252dd900-c7e5-11e8-8b63-cd31e00c69dc.png" />

The assigning reviewers, checking CI statuses and merging pull requet is done by Hosted Danger.
As you can see that the coder just write codes and push it and reviewers just do review.
So Hosted Danger create free times for developers to do some stuffs.

## Comparison with CI danger

Here we show the comparison of Hosted Danger and CI danger.

|               | Timing of execution   | Access to the source code and build products |
|---------------|-----------------------|----------------------------------------------|
| Hosted Danger | Interactively         | Limited                                      |
| CI danger     | End of the CI process | Full access                                  |
