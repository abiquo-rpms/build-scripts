#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'streamly'
require 'fileutils'

def gen_community_dev_release

  if not File.exist?(`which #{PKGWIZ}`.strip.chomp)
    $stderr.puts 'pkgwiz not found. Install it first'
    exit 1
  end

  if not test_200(RELEASE_URL)
    $stderr.puts "Could not reach #{RELEASE_URL}. Aborting."
    exit 1
  end

  rpms = {
    'abiquo-am' => 'am.war',
    'abiquo-vsm' => 'vsm.war',
    'abiquo-virtualfactory-community' => 'virtualfactory.war',
    'abiquo-client-community' => 'client.war',
    'abiquo-server-community' => 'server.war',
    'abiquo-api-community' => 'api.war'
  }

  puts
  puts "*************************"
  puts "     COMMUNITY PLAT      "
  puts "*************************"
  puts

  clean_rpmbuild_dir

  rpms.each do |key,val|
    if test_200(RELEASE_URL + "/#{val}")
      puts "* Updating #{val}..."
      if key.eql? 'abiquo-server-community'
        if test_200(RELEASE_URL + '/kinton-schema.sql')
          puts "Updating kinton-schema..."
          File.open("#{key}/kinton-schema.sql", 'w') do |f|
            Streamly.get "#{RELEASE_URL}/kinton-schema.sql" do |chunk|
              f.write chunk
            end
          end
        else
          raise Exception.new('Could not download kinton-schema.sql')
        end
      end
      File.open("#{key}/#{val}", 'w') do |f|
        Streamly.get "#{RELEASE_URL}/#{val}" do |chunk|
          f.write chunk
        end
      end
      pwd = Dir.pwd
      Dir.chdir key
      #puts "** Bumping build"
      #`#{RPMDEV_BUMPBUILD} #{key}.spec > /dev/null 2>&1`
      #if $? != 0
      #  raise Exception.new("Error bumping spec build for #{val}")
      #end
      puts "** Sending #{key} to buildbot #{BUILD_HOST}"
      `#{PKGWIZ} remote-build --build-port 4567 --buildbot #{BUILD_HOST}`
      if $? != 0
        raise Exception.new("Could not build SRPM for #{val}")
      end
      Dir.chdir pwd
    else
      raise Exception.new("Could not retrieve #{val}")
    end
  end
end

