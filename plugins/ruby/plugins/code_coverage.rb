module Danger
  class DangerCodeCoverage < Plugin

    def parse(file)
      return nil unless file

      require 'rexml/document'

      doc = if file.is_a? String
         REXML::Document.new(file)
      else
        REXML::Document.new(File.read(file))
      end

      root_name = doc.root.name

      case doc.root.name
      when 'report' then parse_jacoco(doc)
      when 'coverage' then parse_cobertura(doc)
      else raise "Unknown coverage format, root = #{root_name}"
      end
    end

    def parse_jacoco(doc)
      line_rate_node = REXML::XPath.match(doc, "/report/counter[@type='LINE']")[0]

      missed_total = line_rate_node.attributes["missed"].to_f
      covered_total = line_rate_node.attributes["covered"].to_f
      line_rate = missed_total + covered_total > 0 ? covered_total / (missed_total + covered_total) : 0.0

      files = REXML::XPath.match(doc, "/report/package/class").map do |c|
        name = c.attribute("name").to_s

        next if name =~ /.*\$.$/

        missed = 0.0
        covered = 0.0

        REXML::XPath.match(c, "/report/package/class[@name='#{name}']/counter[@type='LINE']").each do |counter|
          missed += counter.attributes["missed"].to_f
          covered += counter.attributes["covered"].to_f
        end

        coverage = missed + covered > 0 ? covered / (missed + covered) : 0.0

        {
          file: name,
          coverage: coverage,
        }
      end.compact

      {
        line_rate: line_rate,
        files: files,
      }
    end

    def parse_cobertura(doc)
      coverage_root = doc.root
      line_rate = coverage_root.attributes["line-rate"].to_f

      files_covs = []

      coverage_root.each_recursive do |node|
        files_covs << { file: node.attributes["filename"], coverage: node.attributes["line-rate"].to_f } if node.name == 'class'
      end

      {
        line_rate: line_rate,
        files: files_covs,
      }
    end

    def report(file: nil, url: nil)
      unless file
        raise "Pass the file parameter."
      end

      raise "No Coverage file was found at #{file}" unless File.exist? file

      changed_files = git.modified_files | git.added_files
      changed_files_covs = []

      cov = parse(file)

      cov[:files].each do |file_cov|
        if changed_files.include?(file_cov[:file])
          changed_files_covs << file_cov
        end
      end

      msg = []

      title = "Coverage #{(cov[:line_rate] * 100).round}%"
      msg << '### ' + (url ? "[#{title}](#{url})" : title )

      msg << ''
      msg << '| Files changed | Cov2. |'
      msg << '|-|-|'

      changed_files_covs.each do |cov|
        msg << "| #{cov[:file]} | `#{(cov[:coverage] * 100).round}%` |"
      end

      markdown msg.join("\n") + "\n"
    end

    def summary_text(result)
      (result[:line_rate] * 100).round.to_s + "%"
    end

    def summary_text_with_diff(head_result, base_result)
      #
      # base_result がない場合は、diff なしで返す
      #
      return summary_text(head_result) if base_result.nil?

      diff_value = ((head_result[:line_rate] - base_result[:line_rate]) * 100).round
      diff_text = if diff_value.zero?
                    "±#{diff_value}%"
                  elsif diff_value > 0
                    "+#{diff_value}%"
                  else
                    "#{diff_value}%"
                  end

      "#{summary_text(head_result)} (#{diff_text})"
    end
  end
end
