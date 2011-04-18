#!/usr/bin/env ruby
require 'rubygems'
require 'net/http'
require 'streamly'
require 'fileutils'

def gen_community_all
  if not File.exist?(`which #{PKGWIZ}`.strip.chomp)
    $stderr.puts 'pkgwiz not found. Install it first'
    exit 1
  end

  if not test_200(RPMBuilderConfig.release_url)
    $stderr.puts "Could not reach #{RPMBuilderConfig.release_url}. Aborting."
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
  puts "     COMMUNITY ALL       "
  puts "*************************"
  puts

  clean_rpmbuild_dir

  rpms.each do |key,val|
    if test_200(RPMBuilderConfig.release_url + "/#{val}")
      puts "* Updating #{val}..."
      if key.eql? 'abiquo-server-community'
        if test_200(RPMBuilderConfig.release_url + '/kinton-schema.sql')
          puts "Updating kinton-schema..."
          File.open("#{key}/kinton-schema.sql", 'w') do |f|
            Streamly.get "#{RPMBuilderConfig.release_url}/kinton-schema.sql" do |chunk|
              f.write chunk
            end
          end
        else
          raise Exception.new('Could not download kinton-schema.sql')
        end
      end
      File.open("#{key}/#{val}", 'w') do |f|
        Streamly.get "#{RPMBuilderConfig.release_url}/#{val}" do |chunk|
          f.write chunk
        end
      end
      pwd = Dir.pwd
      Dir.chdir key
      puts "** Creating #{key} SRPM"
      `#{PKGWIZ} remote-build --build-port 4567 --buildbot #{RPMBuilderConfig.build_host}`
      if $? != 0
        raise Exception.new("Could not build SRPM for #{val}")
      end
      Dir.chdir pwd
    else
      raise Exception.new("Could not retrieve #{val}")
    end
  end

  rpms = %w(
    abiquo-aim
    abiquo-cloud-node
    abiquo-community
    abiquo-core
    abiquo-dhcp-relay
    abiquo-logos-ee
    abiquo-release-ee
    abiquo-release-notes-ee
    abiquo-remote-repository-setup
    abiquo-remote-services-community
    abiquo-sosreport-plugins
    abiquo-virtualbox
    abiquo-pocsetup
    anaconda-ee
    hiredis
    libvirt
    redis
    rubygem-abiquo-etk
    thrift
    vboxmanage
  )

  rpms.each do |key,val|
    pwd = Dir.pwd
    Dir.chdir key
    puts "** Sending #{key} to buildbot #{RPMBuilderConfig.build_host}"
    `#{PKGWIZ} remote-build --buildbot #{RPMBuilderConfig.build_host}`
    if $? != 0
      raise Exception.new("Could not build SRPM for #{val}")
    end
    Dir.chdir pwd
  end
end
