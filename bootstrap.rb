#!/usr/bin/env ruby
require 'rubygems'

#
# Tweak this VARS to fit your needs
#
BUILD_HOST = 'builder'

#
# DO NOT CHANGE
#
GH_REPOS_URL = 'http://github.com/api/v2/yaml/repos/show/abiquo-rpms'
GH_URL = 'http://github.com/abiquo-rpms'
REPOS_BASE = 'packages'

begin
  require 'rest-client'
rescue LoadError => e
  $stderr.puts "rest-client not found. Install it first:"
  $stderr.puts "  sudo gem install rest-client"
end

require 'yaml'
begin
  require 'pkg-wizard'
  require 'pkg-wizard/git'
rescue LoadError => e
  $stderr.puts "pkg-wizard not found. Install it first:"
  $stderr.puts "  sudo gem install pkg-wizard"
end

begin
  require 'streamly'
rescue LoadError => e
  $stderr.puts "streamly not found. Install it first:"
  $stderr.puts "  sudo gem install streamly"
end


Dir.mkdir REPOS_BASE if not File.exist?(REPOS_BASE)

if not ARGV.include?('--skip-fetch')
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
end

Dir.chdir REPOS_BASE
if ARGV.include?('--all')
  require '../gen_community_all'
else
  require '../gen_community_dev_release'
end

require '../gen_enterprise_dev_release'
