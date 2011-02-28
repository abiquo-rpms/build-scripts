#!/usr/bin/env ruby
require 'rubygems'
require 'rest-client'
require 'yaml'
require 'pp'
require 'pkg-wizard'
require 'pkg-wizard/git'

GH_REPOS_URL = 'http://github.com/api/v2/yaml/repos/show/abiquo-rpms'
GH_URL = 'http://github.com/abiquo-rpms'
REPOS_BASE = 'packages'
BUILD_HOST = 'builder'

Dir.mkdir REPOS_BASE if not File.exist?(REPOS_BASE)

repo_number = YAML.load(RestClient.get 'http://github.com/api/v2/yaml/user/show/abiquo-rpms')['user']['public_repo_count'].to_i
pages = (repo_number/30.0).ceil

repos = []
1.upto(pages) do |page|
  repos += YAML.load(RestClient.get GH_REPOS_URL + "?page=#{page}")['repositories']
end

repos = repos.sort { |a,b| a[:name] <=> b[:name] }
repos.each do |repo|
  puts "* Fetching #{repo[:name]} repo..."
  PKGWizard::GitRPM.fetch GH_URL + "/#{repo[:name]}", "#{REPOS_BASE}/#{repo[:name]}", :depth => 1
end

Dir.chdir REPOS_BASE
if ARGV.include?('--all')
  require '../gen_community_all'
else
  require '../gen_community_dev_release'
end
