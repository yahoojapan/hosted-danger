# Example of Dangerfile

```ruby
```

# More Use Cases

Use can use danger as usual unless it accesses to the source codes or build products.
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

