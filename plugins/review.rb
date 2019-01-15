module Danger
  class DangerReview < Plugin
    def request(reviewers: [], message: nil, override: false)
      return if closed?
      return unless ready_for_review?

      #
      # https://developer.github.com/v3/pulls/review_requests/#list-review-requests
      #
      req_reviewers = github.api.pull_request_review_requests(repo, number).users.map { |u| u.login }

      cur_reviewers = github.api.pull_request_reviews(repo, number)
                        .map { |x| x.user.login }
                        .reject { |user| user =~ /^ap-/ }
                        .reject { |user| user == author }

      cur_reviewers += req_reviewers
      cur_reviewers.uniq!

      new_reviewers = reviewers - cur_reviewers - [author]

      return false if !cur_reviewers.empty? && !override

      return false if new_reviewers.empty?

      github.api.request_pull_request_review(repo, number, new_reviewers) 

      if message && !message.empty?
        mention = new_reviewers.map {|x| "@#{x}" }.join(' ')
        comment = mention + ' ' + message
        github.api.add_comment(repo, number, comment)
      end

      true
    end

    def apply_inreview_label(label: "in review")
      if ready_for_review?
        unless label_exists?(label)
          github.api.add_labels_to_an_issue(repo, number, [label])
        end
      elsif wip?
        if label_exists?(label)
          github.api.remove_label(repo, number, label)
        end
      end
    end

    def ready_for_review?
      no_errors = status_report[:errors].empty?
      no_warns = status_report[:warnings].reject { |w| w.include?("#reviewable") }.empty?
      no_errors && no_warns && !wip?
    end

    def wip?
      github.pr_title.downcase.include?("[wip]") || github.pr_labels.any? {|l| l =~ /^wip$/i }
    end

    def dnm?
      github.pr_title.downcase.include?("[dnm]") || github.pr_title.downcase.include?("[do not merge]")
    end

    def mergeable?(approved_num: nil)
      return not_merge "Need to specify argument `approved_num` of `review#auto_merge`" if approved_num.nil?
      return not_merge "This pull request is not mergeable" unless github.pr_json["mergeable"]
      return not_merge "It's WIP or DNM" if wip? || dnm?
      return not_merge "There are errors or warns on danger's result" unless status_report[:errors].empty? && status_report[:warnings].empty?

      req_reviewers = github.api.pull_request_review_requests(repo, number)

      if !req_reviewers.kind_of?(Array) && req_reviewers[:users] && req_reviewers[:teams]
        # https://developer.github.com/v3/pulls/review_requests/#list-review-requests
        req_reviewers = req_reviewers[:users] + req_reviewers[:teams]
      end

      #
      # https://developer.github.com/v3/pulls/reviews/#list-reviews-on-a-pull-request
      #
      cur_reviews = github.api.pull_request_reviews(repo, number)
                      .reject { |r| r[:user][:login] =~ /^ap-/ }
                      .reject { |r| r[:user][:login] == author }

      return not_merge "Reviewer is not set" if cur_reviews.empty? && req_reviewers.empty?

      cur_reviewers = cur_reviews.group_by { |r| r[:user][:login] }
      cur_reviewers_approved = cur_reviewers.select do |u, r|
        (r.rindex { |r| r[:state] == 'APPROVED' && r[:author_association] != 'NONE' } || -1) >
          (r.rindex { |r| r[:state] == 'CHANGES_REQUESTED' && r[:author_association] != 'NONE' } || -1)
      end

      cur_reviewers_rejected = cur_reviewers.select do |u, r|
        (r.rindex { |r| r[:state] == 'CHANGES_REQUESTED' && r[:author_association] != 'NONE' } || -1) >
          (r.rindex { |r| r[:state] == 'APPROVED' && r[:author_association] != 'NONE' } || -1)
      end

      return not_merge "#{approved_num - cur_reviewers_approved.size} approves are required to merge" if cur_reviewers_approved.size < approved_num
      return not_merge "There is request changes" if cur_reviewers_rejected.size > 0

      statuses = github.api
                   .combined_status(repo, sha)
                   .statuses
                   .reject { |x| x[:context] == 'danger/hosted-danger' }
      return not_merge "There is a CI status which is not 'success'" unless statuses.all? { |status| status[:state] == 'success' }

      true
    end

    def auto_merge(commit_message: '', delete_branch: true, approved_num: nil, **options)
      return if closed?
      return unless mergeable?(approved_num: approved_num)

      status_options = {
        context: 'danger/hosted-danger',
        target_url: html_url,
        description: 'Approved via auto_merge!',
      }

      github.api.create_status(repo, sha, 'success', status_options)
      github.api.merge_pull_request(repo, number, commit_message, options)
      github.api.delete_branch(repo, branch) if delete_branch && !fork? && deletable?
    end

    private

    def state
      github.pr_json[:state]
    end

    def closed?
      state == 'closed'
    end

    def html_url
      github.pr_json[:html_url]
    end

    def repo
      github.pr_json[:base][:repo][:full_name]
    end

    def branch
      github.pr_json[:head][:ref]
    end

    def number
      github.pr_json[:number]
    end

    def sha
      github.pr_json[:head][:sha]
    end

    def author
      github.pr_json[:user][:login]
    end

    def label_exists?(label)
      github.pr_labels.include?(label)
    end

    def labels
      github.pr_labels
    end

    def fork?
      github.pr_json[:base][:repo][:full_name] != github.pr_json[:head][:repo][:full_name]
    end

    def default_branch
      github.api.repo(repo)[:default_branch]
    end

    def protected_branches
      github.api.branches(repo, accept: preview_header).select { |b| b[:protected] }.map { |b| b[:name] }
    end

    def deletable?
      ![default_branch, protected_branches].flatten.include?(branch)
    end

    def preview_header
      Octokit::Preview::PREVIEW_TYPES[:branch_protection]
    end

    #
    # return: Bool
    #
    def not_merge(reason)
      message "Auto-merge was blocked for the reason: #{reason}"

      false
    end
  end
end
