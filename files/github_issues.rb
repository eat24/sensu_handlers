#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/base"

class GithubIssues < BaseHandler

  def create_issue(summary, full_description, project)
    begin
      require 'octokit'
      client = Octokit::Client.new(:access_token => settings['github_issues']['access_token'])

      host_label_name = "host=#{@event['client']['name']}"
      check_label_name = "check=#{@event['check']['name']}"
      # In order to stop duplicates, we query github for any open tickets
      # in the requested project that have the exact same client name and check name
      existing_issues = client.issues(
        project,
        :state => 'open',
        :labels => "Sensu,#{host_label_name},#{check_label_name}",
        :creator => settings['github_issues']['username'])

      if existing_issues.length > 0
        # If there are tickets that match, we don't make a new one because it is already a known issue
        puts "Not creating a new issue, there are " + existing_issues.length.to_s + " issues already open for " + summary
      else
        puts "Creating a new github issue for: #{summary} on project #{project}"

        # attempt to create labels
        client.add_label(project, host_label_name, "cccccc")
        client.add_label(project, check_label_name, "cccccc")

        issue = client.create_issue(
          project,
          summary,
          full_description,
          :labels => "Sensu,#{host_label_name},#{check_label_name}")

        puts "Created issue #{issue.number} at #{issue.url}"
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
  end

  def close_issue(output, project)
    begin
      require 'octokit'
      client = Octokit::Client.new(:access_token => settings['github_issues']['access_token'])

      host_label_name = "host=#{@event['client']['name']}"
      check_label_name = "check=#{@event['check']['name']}"
      # In order to stop duplicates, we query github for any open tickets
      # in the requested project that have the exact same client name and check name
      client.issues(
        project,
        :state => 'open',
        :labels => "Sensu,#{host_label_name},#{check_label_name}").each do |issue|

        puts "Closing Issue: #{issue.number} (#{issue.url})"

        # Let the world know why we are closing this issue.
        client.add_comment(project, issue.number, "This is fine:\n#{output}")

        client.close_issue(project, issue.number)
      end
    rescue Exception => e
      puts e.backtrace
    end
  end

  def should_ticket?
    @event['check']['ticket'] || false
  end

  def project
    @event['check']['project'] || team_data('project')
  end

  def handle
    return false if !should_ticket?
    return false if !project
    status = human_check_status()
    summary = @event['check']['name'] + " on " + @event['client']['name'] + " is " + status
    full_description = full_description()
    output = @event['check']['output']
    begin
      timeout(10) do
        case @event['check']['status'].to_i
        when 0
          close_issue(output, project)
        else
          create_issue(summary, full_description, project)
        end
      end
    rescue Timeout::Error
      puts 'Timed out while attempting contact Github for ' + @event['action'] + summary
    end
  end

end
