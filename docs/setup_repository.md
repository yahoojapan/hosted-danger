# Setup Repository

In this doc, we assume that you already have a Hosted Danger server. (If not, please refer [here](/docs/launch_server.md))

## Setting Webhooks

Add webhook to the target repository.
Go the repository's Settings page, select Webhooks tab and add webhook as below.

| Payload URL                                          | http(s)://your_hosted_danger_instance.com/hook |
| Content type                                         | application/json                               |
| Secret                                               | None                                           |
| Which events would you like to trigger this webhook? | Send me everything.                            |
| Active                                               | On (Active)                                    |

Note that if you set the webhook to the organization, all repositories are activated.

## Application account

Add your application account to the repository as a collaborator.

Note that if you add the application account to the organization with writable role, all repositories are activated.

## Testing

Create a dummy Pull Request on the repository. If you get a message from your application account, it works perfectly! :tada:

## Next Step
- [Example of Dangerfile](/docs/example_of_dangerfile.md)
