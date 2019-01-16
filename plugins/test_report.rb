module Danger
  class DangerTestReport < Plugin
    # An attribute to make the plugin show a warning on skipped tests.
    #
    # @return   [Bool]
    attr_accessor :warn_skipped_tests

    # An attribute to make the plugin show test suite names.
    #
    # @return   [Bool]
    attr_accessor :show_test_suite

    # An array of symbols that become the columns of your tests,
    # if `nil`, the default, it will be all of the attributes.
    #
    # @return   [Array<Symbol>]
    attr_accessor :headers

    # Parses an XML file, which fills all the attributes,
    # will `raise` for errors
    # @return   [void]
    def parse(file)
      return nil unless file
      return merge(file.map { |f| parse(f) }) if file.is_a?(Array)

      require 'rexml/document'

      doc = if file.is_a? String
         REXML::Document.new(file)
      else
        raise "No JUnit file was found at #{file}" unless File.exist? file
        REXML::Document.new(File.read(file))
      end

      suite_root = doc.root.name == 'testsuites' ? doc.elements.first : doc
      suites_elements = doc.root.name == 'testsuites' ? doc.root : [doc.root]

      test_suites = suites_elements.map do |suite|
        next nil if suite.node_type == :text

        name = suite.name

        tests = suite.elements.select { |node| node.name == 'testcase' }

        failed_tests = suite.elements.select { |node| node.name == 'testcase' }

        failures = failed_tests.select do |test| 
          test.elements.count > 0
        end.select do |test|
          node = test.elements.first
          node.name == 'failure'
        end

        errors = failed_tests.select do |test| 
          test.elements.count > 0
        end.select do |test| 
          node = test.elements.first
          node.name == 'error'
        end

        skipped = tests.select do |test| 
          test.elements.count > 0
        end.select do |test| 
          node = test.elements.first
          node.name == 'skipped'
        end

        passes = tests - failures - errors - skipped

        {
          name: name,
          tests: tests,
          passes: passes,
          failures: failures,
          errors: errors,
          skipped: skipped,
        }
      end.compact

      {
        name: suite_root.attributes['name'],
        time: suite_root.attributes['time'].to_f,
        test_suites: test_suites,
        tests: test_suites.map {|suite| suite[:tests] }.flatten.size,
        passes: test_suites.map {|suite| suite[:passes] }.flatten.size,
        failures: test_suites.map {|suite| suite[:failures] }.flatten.size,
        errors: test_suites.map {|suite| suite[:errors] }.flatten.size,
        skipped: test_suites.map {|suite| suite[:skipped] }.flatten.size,
      }
    end

    def merge(results)
      default = {
        name: '',
        time: 0.0,
        test_suites: [],
        tests: 0,
        passes: 0,
        failures: 0,
        errors: 0,
        skipped: 0,
      }

      results.reduce(default) do |r, t|
        {
          name: '',
          time: r[:time] + t[:time],
          test_suites: r[:test_suites].concat(t[:test_suites]),
          tests: r[:tests] + t[:tests],
          passes: r[:passes] + t[:passes],
          failures: r[:failures] + t[:failures],
          errors: r[:errors] + t[:errors],
          skipped: r[:skipped] + t[:skipped],
        }
      end
    end

    # Causes a build fail if there are test failures,
    # and outputs a markdown table of the results.
    #
    # @return   [void]
    def report(file: nil, url: nil, title: 'Tests')
      @message = []

      file_result = parse(file)

      report_summary(file_result, url, title)
      report_failures(file_result)
      report_skipped(file_result)

      markdown @message.join("\n") + "\n\n"
    end

    def report_skipped(file_result)
      warn("Skipped #{file_result[:skipped]} tests.") if warn_skipped_tests && file_result[:skipped] > 0
    end

    def report_summary(file_result, url, title)
      summary_title = url ? "[**#{title}**](#{url})" : title

      # Create the headers
      if show_test_suite
        @message << "### #{summary_title}"
        @message << ''

        headers = ['Test Suite', 'Result']
      else
        headers = [summary_title]
      end

      @message << headers.join(' | ') + "|"
      @message << headers.map { |_| '---' }.join(' | ') + "|"

      if show_test_suite
        file_result[:test_suites].each do |suite|
          row_values = [suite[:name], summary_text(suite)]
          @message << row_values.join(' | ') + "|"
        end
      else
        row_values = [summary_text(file_result)]
        @message << row_values.join(' | ') + "|"
      end
    end

    def report_failures(file_result)

      test_passed = file_result[:failures].zero? && file_result[:errors].zero?

      return if test_passed

      fail('Tests have failed, see below for more information.')
    end

    def summary_text(result)
      failures = result[:failures] + result[:errors]

      mark = if failures > 0
               ':umbrella:'
             elsif result[:skipped] > 0 || result[:tests] == 0
               ':cloud:'
             else
               ':sunny:'
             end

      num_text = [
        plural_text(result[:tests], 'test'),
        plural_text(failures, 'failure'),
        result[:skipped].zero? ? nil : plural_text(result[:skipped], 'skipped'),
      ].compact.join(', ') + '.'

      "#{mark} **#{num_text}**"
    end

    def summary_text_with_diff(head_result, base_result)
      return summary_text(head_result) if base_result.nil?

      diff_value = head_result[:tests] - base_result[:tests]
      diff_text = if diff_value.zero?
                    "±#{diff_value}"
                  elsif diff_value > 0
                    "+#{diff_value}"
                  else
                    "#{diff_value}"
                  end

      "#{summary_text(head_result)} (#{diff_text})"
    end

    private

    def plural_text(num, word)
      num.to_s + ' ' + (num == 1 ? word : word + 's')
    end
  end
end
