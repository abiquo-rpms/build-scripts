#!/usr/bin/env ruby
require 'rubygems'
require 'gen_community_dev_release'
require 'gen_enterprise_dev_release'
require 'gen_community_all'

class RPMBuilderConfig
  
  @@enterprise_release_url = 'http://hudson/stable/premium/'
  @@release_url = 'http://hudson/stable/premium/'
  @@release_tag = 'stable'
  @@build_host = 'builder'
  @@ci_host = 'hudson'

  def self.release_tag=(arg)
    @@release_tag = arg
  end

  def self.release_tag
    @@release_tag
  end

  def self.release_url
    "http://#{@@ci_host}/#{@@release_tag}/community/"
  end
  
  def self.enterprise_release_url
    "http://#{@@ci_host}/#{@@release_tag}/premium/"
  end

  def self.build_host
    @@build_host
  end

end

ENV['PATH'] = ENV['PATH'] + ':/var/lib/gems/1.8/bin:/var/lib/gems/1.9/bin'

#
# DO NOT CHANGE
#
GH_REPOS_URL = 'http://github.com/api/v2/yaml/repos/show/abiquo-rpms'
GH_URL = 'http://github.com/abiquo-rpms'
REPOS_BASE = 'packages'
PKGWIZ='pkgwiz'

def clean_rpmbuild_dir
  Dir["#{ENV['HOME']}/rpmbuild/*"].each do |entry|
    FileUtils.rm_rf entry
  end
end


def test_200(url)
  h = Streamly.head(url).lines.first 
  if h =~ /HTTP.*?200/ 
    return true
  end 
  false
end


def main

  begin
    require 'rest-client'
  rescue LoadError => e
    $stderr.puts "rest-client not found. Install it first:"
    $stderr.puts "  sudo gem install rest-client"
    exit 1
  end
  begin
    require 'rufus/scheduler'
  rescue LoadError => e
    $stderr.puts "rufus-scheduler not found. Install it first:"
    $stderr.puts "  sudo gem install rufus-scheduler"
    exit 1
  end

  require 'yaml'
  begin
    require 'pkg-wizard'
    require 'pkg-wizard/git'
  rescue LoadError => e
    $stderr.puts "pkg-wizard not found. Install it first:"
    $stderr.puts "  sudo gem install pkg-wizard"
    exit 1
  end

  begin
    require 'streamly'
  rescue LoadError => e
    $stderr.puts "streamly not found. Install it first:"
    $stderr.puts "  sudo gem install streamly"
    exit 1
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

  RestClient.post "http://#{RPMBuilderConfig.build_host}:4567/job/clean", {}
  cwd = Dir.pwd
  Dir.chdir REPOS_BASE
  if ARGV.include?('--all')
    gen_community_all
  else
    gen_community_dev_release
  end

  gen_enterprise_dev_release

  sched = Rufus::Scheduler.start_new
  sched.every '10s', :blocking => true do |job|
    yaml = YAML.load RestClient.get "http://#{RPMBuilderConfig.build_host}:4567/job/stats"
    if yaml[:enqueued] == 0 and yaml[:building] == 0
      puts '* Creating snapshot...'
      RestClient.post "http://#{RPMBuilderConfig.build_host}:4567/createsnapshot", {}
      puts '* Creating repo...'
      RestClient.post "http://#{RPMBuilderConfig.build_host}:4567/createrepo", {}
      puts '* Creating tagging...'
      RestClient.post "http://#{RPMBuilderConfig.build_host}:4567/tag/#{RPMBuilderConfig.release_tag}", {}
      puts "* Rufus is done!"
      job.unschedule
    end
  end
  sched.join
  puts "* Waiting for build-bot to complete the job..."
  Dir.chdir cwd
end

if ARGV.include? '--script'
  main
else
  require 'sinatra'

  set :port, 4444

  get '/' do
    'stuff'
  end

  post '/start' do
    tag = params[:tag] || RPMBuilderConfig.release_tag
    build_host = params[:build_host] || RPMBuilderConfig.build_host
    RPMBuilderConfig.release_tag = tag
    puts
    puts "[#{Time.now}] Building #{RPMBuilderConfig.release_tag} ... \n\n"
    begin
      main
    rescue SystemExit
      puts "* Done"
    rescue Exception => e
      puts e.class
      puts "FAILED"
      puts e.message
      puts e.backtrace
    end
  end
end
