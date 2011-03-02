#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'

post '/bootstrap' do
  print "[#{Time.now}] Bootstraping... "
  begin
    load 'bootstrap'
    puts "OK"
  rescue Exception => e
    puts "FAILED"
    puts e.message
  end
end
