warn "Work In Progress" if github.pr_title.downcase.include?("wip")
warn "Do not merge!", sticky: false  unless github.pr_json["mergeable"]

message "Large PR!" if git.lines_of_code > 600

['README.md', 'Gemfile', 'Makefile', 'Dangerfile.default', 'Dockerfile', 'shard.yml'].each do |path|
  message "`#{path}` has changed" if git.modified_files.include? path
end

message ENV["DANGER_ACTION"]
message ENV["DANGER_EVENT"]

lgtm.check_lgtm https_image_only: true
