# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'net/https'
require 'json'

class GithubStatus
  def initialize
    @token = ENV['GITHUB_TOKEN']
    @repository = ENV['DEPLOYMENT_REPOSITORY']
    @ref = ENV['DEPLOYMENT_REF']

    @env = ENV['DEPLOYMENT_ENVIRONMENT'] || 'staging'
    @task = ENV['DEPLOYMENT_TASK'] || 'helm_release'
    @status = ENV['DEPLOYMENT_STATUS'] || 'in_progress'
    @desc = ENV['DEPLOYMENT_DESC'] || 'Helm Release'
    @log_url = ENV['DEPLOYMENT_LOG_URL'] || ''
  end

  def call
    data = {
      environment: @env,
      state: @status,
      log_url: @log_url
    }

    post_status(data)
  end

  private

  def post_status(data)
    response = http.post("/repos/#{@repository}/deployments/#{deployment_id}/statuses", data.to_json, headers)
    json = JSON.parse(response.body)
    puts "Status JSON\n: #{JSON.pretty_generate(json)}"
  end

  def deployment_id
    @deployment_id ||= existing_deployment_id || new_deployment_id
  end

  def new_deployment_id
    data = {
      environment: :staging,
      ref: @ref,
      task: @task,
      auto_merge: false,
      description: @desc
    }
    response = http.post("/repos/#{@repository}/deployments", data.to_json, headers)
    json = JSON.parse(response.body)
    json.fetch('id').tap do |id|
      puts "New deployment ID: #{id}"
    end
  end

  def existing_deployment_id
    response = http.get("/repos/#{@repository}/deployments?ref=#{@ref}&task=#{@task}", headers)
    json = JSON.parse(response.body)
    json.first&.fetch('id').tap do |id|
      puts "Existing deployment ID: #{id}"
    end
  end

  def http
    @http ||= begin
                uri = URI('https://api.github.com')
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                http.start

                http
              end
  end

  def headers
    {
      'Accept' => 'application/vnd.github+json',
      'Authorization' => "Bearer #{@token}",
      'X-GitHub-Api-Version' => '2022-11-28'
    }
  end
end

GithubStatus.new.call
