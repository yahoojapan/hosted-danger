warn "Work In Progress" if github.pr_title.downcase == "wip"
warn "Do not merge!", sticky: false  unless github.pr_json["mergeable"]

message "Large PR!" if git.lines_of_code > 600

['README.md', 'Gemfile', 'Makefile', 'Dangerfile', 'Dockerfile', 'shard.yml'].each do |path|
  message "`#{path}` has changed" if git.modified_files.include? path
end

lgtm.check_lgtm image_url: 'https://mym.corp.yahoo.co.jp/paster/kXafK5a7826d6da12d9ac4eb15039.png'
