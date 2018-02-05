lgtm = true

if github.pr_title.include? "WIP"
  lgtm = false
  warn("PR is classed as Work in Progress")
end

lgtm.check_lgtm image_url: 'https://mym.corp.yahoo.co.jp/paster/kXafK5a7826d6da12d9ac4eb15039.png' if lgtm
