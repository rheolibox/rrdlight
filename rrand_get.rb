#!/usr/bin/env ruby

require 'bundler'
Bundler.require

require 'rredis'
rrd = RReDis.new

# Get the data from 5 minutes ago until now
puts rrd.get('example', Time.now-300, Time.now).inspect
# Get the data from one hour ago until 55 minutes ago
puts rrd.get('example', Time.now-3600, Time.now-3300, 'min').inspect
# Get the data from two hours ago until 90 minutes ago
puts rrd.get('example', Time.now-7200, Time.now-5400, 'max').inspect
