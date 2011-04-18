#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'streamly'
require 'fileutils'

def gen_enterprise_dev_release

  if not File.exist?(`which #{PKGWIZ}`.strip.chomp)
    $stderr.puts 'pkgwiz not found. Install it first'
    exit 1
  end

  if not test_200(RPMBuilderConfig.enterprise_release_url)
    $stderr.puts "Could not reach #{RPMBuilderConfig.enterprise_release_url}. Aborting."
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
    'abiquo-lvmiscsi' => 'lvmiscsi.war',
    'abiquo-nodecollector' => 'nodecollector.war',
    'abiquo-v2v' => 'bpm-async.war',
    'abiquo-ssm' => 'ssm.war'
  }

  clean_rpmbuild_dir

  rpms.each do |key,val|
    if test_200(RPMBuilderConfig.enterprise_release_url + "/#{val}")
      puts "* Updating #{val}..."
      if key.eql? 'abiquo-server'
        if test_200(RPMBuilderConfig.enterprise_release_url + '/kinton-schema.sql')
          puts "Updating kinton-schema..."
          File.open("#{key}/kinton-schema.sql", 'w') do |f|
            Streamly.get "#{RPMBuilderConfig.enterprise_release_url}/kinton-schema.sql" do |chunk|
              f.write chunk
            end
          end
        else
          raise Exception.new('Could not download kinton-schema.sql')
        end
      end
      File.open("#{key}/#{val}", 'w') do |f|
        Streamly.get "#{RPMBuilderConfig.enterprise_release_url}/#{val}" do |chunk|
          f.write chunk
        end
      end
      pwd = Dir.pwd
      Dir.chdir key
      puts "** Sending #{key} to #{RPMBuilderConfig.build_host}"
      `#{PKGWIZ} remote-build --build-port 4567 --buildbot #{RPMBuilderConfig.build_host}`
      if $? != 0
        raise Exception.new("Could not build SRPM for #{val}")
      end
      Dir.chdir pwd
    else
      raise Exception.new("Could not retrieve #{val}")
    end
  end

end
