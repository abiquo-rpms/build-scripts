#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'streamly'
require 'fileutils'

#
# Tweak this to fit your needs
#
ENTERPRISE_RELEASE_URL = 'http://hudson/1.7.0/premium/'

RPMWIZ='/var/lib/gems/1.8/bin//pkgwiz' if not defined? RPMWIZ
BUILD_HOST = 'builder' if not defined? BUILD_HOST
###

def test_200(url)
  h = Streamly.head(url).lines.first 
  if h =~ /HTTP.*?200/ 
    return true
  end 
  false
end

def clean_rpmbuild_dir
  Dir["#{ENV['HOME']}/rpmbuild/*"].each do |entry|
    FileUtils.rm_rf entry
  end
end

if not File.exist?(RPMWIZ)
  $stderr.puts 'pkgwiz not found. Install it first'
  exit 1
end

if not test_200(ENTERPRISE_RELEASE_URL)
  $stderr.puts "Could not reach #{ENTERPRISE_RELEASE_URL}. Aborting."
  exit 1
end

puts
puts "*************************"
puts "       ENTERPRISE        "
puts "*************************"
puts

rpms = {
  'abiquo-virtualfactory' => 'virtualfactory.war',
  'abiquo-client-premium' => 'client-premium.war',
  'abiquo-server' => 'server.war',
  'abiquo-api' => 'api.war',
  'abiquo-ontap' => 'ontap.war',
  'abiquo-lvmiscsi' => 'lvmiscsi.war',
  'abiquo-nodecollector' => 'nodecollector.war',
  'abiquo-v2v' => 'bpm-async.war',
  'abiquo-ssm' => 'ssm.war'
}

clean_rpmbuild_dir

rpms.each do |key,val|
  if test_200(ENTERPRISE_RELEASE_URL + "/#{val}")
    puts "* Updating #{val}..."
    if key.eql? 'abiquo-server'
      if test_200(ENTERPRISE_RELEASE_URL + '/kinton-schema.sql')
        puts "Updating kinton-schema..."
        File.open("#{key}/kinton-schema.sql", 'w') do |f|
          Streamly.get "#{ENTERPRISE_RELEASE_URL}/kinton-schema.sql" do |chunk|
            f.write chunk
          end
        end
      else
        raise Exception.new('Could not download kinton-schema.sql')
      end
    end
    File.open("#{key}/#{val}", 'w') do |f|
      Streamly.get "#{ENTERPRISE_RELEASE_URL}/#{val}" do |chunk|
        f.write chunk
      end
    end
    pwd = Dir.pwd
    Dir.chdir key
    puts "** Sending #{key} to #{BUILD_HOST}"
    `#{RPMWIZ} remote-build --buildbot #{BUILD_HOST}`
    if $? != 0
      raise Exception.new("Could not build SRPM for #{val}")
    end
    Dir.chdir pwd
  else
    raise Exception.new("Could not retrieve #{val}")
  end
end

