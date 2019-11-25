# coding: utf-8
require 'net/https'
require 'json'

module Danger
  class DangerSlack < Plugin
    ENDPOINT = 'http://localhost/slack'.freeze

    def post(text, channel, attachments = nil)
      if text.nil? && attachments.nil?
        raise "slack plugin: text or attachments must exist"
      end

      uri = URI.parse(ENDPOINT)

      http = Net::HTTP.new(uri.host, uri.port)

      req = Net::HTTP::Post.new(uri.path)
      req['Content-Type'] = 'application/json; charset=UTF-8'

      payload = {
        channel: channel,
        link_names: true,
      }

      payload[:text] = text if text
      payload[:attachments] = attachments if attachments

      req.body = payload.to_json

      http.request(req)
    end

    COLORS = {
      info: '#E6EBF1',
      warning: '#EEAC57',
      success: '#60C0DC',
      merge: '#6F47BE',
      review: '#DAAA29',
      changes_requested: '#C92736',
      approved: '#35BC54',
    }

    def notify(channel, options = { ignores: [], texts: [] })
      event = ENV['DANGER_EVENT']
      action = ENV['DANGER_ACTION']

      return if skip?(event, action, options)

      text = additional_text(event, action, options)

      payload = JSON.parse(ENV['DANGER_PAYLOAD'])

      attachments = case event
                    when 'pull_request'
                      notify_pull_request(payload)
                    when 'pull_request_review'
                      notify_pull_request_review(payload)
                    when 'pull_request_review_comment'
                      notify_pull_request_review_comment(payload)
                    when 'issue_comment'
                      notify_issue_comment(payload)
                    else
                      nil
                    end

      post(text, channel, attachments) if !text.nil? || !attachments.nil?
    end

    def skip?(event, action, options)
      return false unless options[:ignores]
      return true if options[:ignores].include?(event)
      return true if options[:ignores].map { |o|
        if o.is_a?(Hash)
          o[:event] == event && o[:action] == action
        else
          false
        end
      }.any?

      false
    end

    def additional_text(event, action, options)
      return nil unless options[:texts]

      t = options[:texts].select { |t|
        t[:event] == event && t[:action] == action
      }

      return nil if t.count.zero?

      t[0][:text]
    end

    def notify_pull_request(payload)
      head_branch = payload['pull_request']['head']['ref']
      base_branch = payload['pull_request']['base']['ref']

      attachment_base = {
        author_name: payload['pull_request']['user']['login'],
        author_link: payload['pull_request']['user']['html_url'],
        title: payload['pull_request']['title'],
        title_link: payload['pull_request']['html_url'],
        footer: "#{payload['repository']['full_name']} #{base_branch} from #{head_branch}",
        mrkdwn_in: ['text']
      }

      case ENV['DANGER_ACTION']
      when 'synchronize'
        attachment_base[:color] = COLORS[:info]
        attachment_base[:text] = '*Synchronized Pull Request*'
      when 'review_requested'
        reviewer = payload['requested_reviewer']['login']

        attachment_base[:color] = COLORS[:review]
        attachment_base[:text] = "*Review Requested :eyes:*\n:arrow_forward: @#{reviewer}"
      when 'opened'
        attachment_base[:color] = COLORS[:info]
        attachment_base[:text] = '*Pull Request Opened :hand:*'
      when 'closed'
        if payload['pull_request']['merged']
          attachment_base[:color] = COLORS[:merge]
          attachment_base[:text] = '*Merged :tada:*'
        else
          attachment_base[:color] = COLORS[:info]
          attachment_base[:text] = '*Pull Request Closed :wave:*'
        end
      else
        return nil
      end

      attachments = [attachment_base]

      JSON.dump(attachments)
    end

    def notify_pull_request_review(payload)
      head_branch = payload['pull_request']['head']['ref']
      base_branch = payload['pull_request']['base']['ref']

      attachment_base = {
        author_name: payload['review']['user']['login'],
        author_link: payload['review']['user']['html_url'],
        title: payload['pull_request']['title'],
        title_link: payload['review']['html_url'],
        footer: "#{payload['repository']['full_name']} #{base_branch} from #{head_branch}",
        mrkdwn_in: ['text']
      }

      return nil unless ENV['DANGER_ACTION'] == 'submitted'

      case payload['review']['state']
      when 'approved'
        attachment_base[:color] = COLORS[:approved]
        attachment_base[:text] = '*Approved* :+1:'
        attachment_base[:text] += "\n#{payload['review']['body']}" if payload['review']['body']
      when 'changes_requested'
        attachment_base[:color] = COLORS[:changes_requested]
        attachment_base[:text] = '*Changes Requested* :pray:'
        attachment_base[:text] += "\n#{payload['review']['body']}" if payload['review']['body']
      when 'commented'
        #
        # diffに対してコメントすると、bodyが空のpull_request_reviewが飛ぶ
        #
        return nil if payload['review']['body'].nil? || payload['review']['body'] == ''

        attachment_base[:color] = COLORS[:info]
        attachment_base[:text] = payload['review']['body'] if payload['review']['body']
      else
        return nil
      end

      attachments = [attachment_base]

      JSON.dump(attachments)
    end

    def notify_pull_request_review_comment(payload)
      return nil unless ENV['DANGER_ACTION'] == 'created'

      head_branch = payload['pull_request']['head']['ref']
      base_branch = payload['pull_request']['base']['ref']

      attachments = [
        {
          color: COLORS[:info],
          text: payload['comment']['body'],
          author_name: payload['comment']['user']['login'],
          author_link: payload['comment']['user']['html_url'],
          title: payload['pull_request']['title'],
          title_link: payload['comment']['html_url'],
          footer: "#{payload['repository']['full_name']} #{base_branch} from #{head_branch}",
          mrkdwn_in: ['text']
        }
      ]

      JSON.dump(attachments)
    end

    def notify_issue_comment(payload)
      return nil unless ENV['DANGER_ACTION'] == 'created'

      attachments = [
        {
          color: COLORS[:info],
          text: payload['comment']['body'],
          author_name: payload['comment']['user']['login'],
          author_link: payload['comment']['user']['html_url'],
          title: payload['issue']['title'],
          title_link: payload['comment']['html_url'],
          footer: payload['repository']['full_name'],
          mrkdwn_in: ['text']
        }
      ]

      JSON.dump(attachments)
    end
  end
end
