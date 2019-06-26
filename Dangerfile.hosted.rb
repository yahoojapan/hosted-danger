danger.import_dangerfile(github: 'yahoojapan/hosted-danger', path: 'plugins/Dangerfile')

def author
  github.pr_json[:user][:login]
end

unless author == 'tbrand'
  review.request reviewers: ['tbrand'], message: '@tbrand New Pull Request! :tada:'
  review.auto_merge approved_num: 1
end
