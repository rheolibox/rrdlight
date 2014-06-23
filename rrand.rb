#!/usr/bin/env ruby

require 'bundler'
Bundler.require

require 'rredis'
rrd = RReDis.new

# We start two hours in the past
start = (Time.now-(3600*2)).to_i

# We pretend to update the data every 10 seconds for two hours
(2*3600/10).times do |step|
  rrd.store "example", start+step*10, rand(100)
end
