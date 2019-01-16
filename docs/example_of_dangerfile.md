# Basic Usage
- Hosted Danger recognizes **Dangerfile.hosted.rb** or **Dangerfile.hosted** as a Dangerfile to be executed.
  - Put **Dangerfile.hosted.rb** at root of you project.
  - Which means you can use both of Hosted Danger and CI danger.

# Example of Dangerfile

We have [useful plugins](/dangerfile) that realize basic behaviors of Hosted Danger.

```ruby
# In your "Dangerfile.hosted.rb".
# First, import our plugins by

danger.import_dangerfile(github: "yahoojapan/hosted-danger", path: "plugins/Dangerfile")

# Assigning reviewers automatically when it should be.
# It checks below conditions to decide the pull request is assignable or not.
# - The pull request is not closed.
# - No errors and warnings.
# - It's not WIP. (The title doesn't contain "WIP")
# - There is no assigned reviewers.
# - There is no reviews.
# See the plugins/review.rb#request for details.

review.request reviewers: ['john', 'taro'], message: "Please review! :)"

# Automatically merge pull request when it should be.
# It checks below conditions to decide the pull request is mergeable or not.
# - The pull request is not conflicted.
# - It's not WIP and DNM. (The title doesn't contain "WIP" and "DNM")
# - Danger doesn't report any errors or warnings.
# - Enough number of approves.
# - Every CI statuses are success.
# See the plugins/review.rb#auto_merge for details.

review.auto_merge(approved_num: 2)
```

# More Use Cases

You can use danger as usual unless it accesses to the source codes or build products.
Here we show some examples of other use cases.

The reference of original danger is [here](https://danger.systems/reference.html).

## Basic Examples
You can copy and paste below examples into your Dangerfile.hosted.rb if you need it.

```ruby
# In Dangerfile.hosted.rb
#
# Classify the pull requests
#
def wip?
  github.pr_title.downcase.include?("[wip]")
end

def dnm?
  github.pr_title.downcase.include?("[dnm]")
end

def test?
  github.pr_title.downcase.include?("[test]")
end

#
# You can send messages as usual
#
message("Hi I'm Hosted Danger! :heart:")

#
# Classify the pull requests for avoiding auto merging
#
warn "PR is classed as Work in Progress" if wip?
warn "PR is classed as Do Not Merge" if dnm?
warn "PR is classed as Test" if test?

#
# Show a warn message when the milestone is not set for the pull request
#
has_milestone = github.pr_json['milestone'] != nil
warn('Milestone is not set') unless has_milestone

#
# Show a warn message when there are unchecked tasks in the description
#
has_unchecked_tasks = github.pr_body =~ /^\s*- \[ \] /
warn 'There are unchecked tasks. :white_medium_square:' if has_unchecked_tasks
```
