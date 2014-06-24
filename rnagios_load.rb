#!/usr/bin/env ruby

require 'bundler'
Bundler.require

require 'rredis'

rrd = RReDis.new

config = {
  min01: {
    steps: 60, rows: 2880,
    aggregations: ["average", "min", "max"],
    rra: [ {:steps=>300, :rows=>2976, :xff=>0.5},
           {:steps=>900, :rows=>2976, :xff=>0.5},
           {:steps=>3600, :rows=>8760, :xff=>0.5}]
  },
  min05: {
    steps: 300, rows: 576,
    aggregations: ["average", "min", "max"],
    rra: [ {:steps=>900, :rows=>2976, :xff=>0.5},
           {:steps=>3600, :rows=>8760, :xff=>0.5}]
  },
}

config_set = {}

services = {
  "best" => {
    config: :min01
  },
}

Dir.open("/home/users/nagios/var").each do |d|
  next unless d=~/^service-perfdata/
  puts "Parse #{d}..."
  File.open("/home/users/nagios/var/#{d}") do |f|
  f.each do |line|
    line.chomp!
    line_a = line.split(/:/)
    next if line_a.size < 4
    div = 300
    cnf = config[:min05]
    if services.has_key?(line_a[2])
      if services[line_a[2]][:config] == :min01
        cnf = config[:min01]
        div = 60
      end
      if services[line_a[2]][:config] == :default
        cnf = nil
        div = 600
      end
    end
    time = line_a[0].to_i/div*div
    data = []
    if line_a[2]=~/^b_/
      sub = line_a[2].gsub(/^b_/,'')
      line_a[3].split(/;/).each do |vals|
        val = vals.split(/ /)
        key = "#{line_a[1]}_#{sub}_#{val[0]}"
        unless config_set.has_key?(key)
          rrd.config(key, cnf) unless cnf.nil?
          config_set[key] = 1
        end
        rrd.store key, time, val[1].to_f
      end
    else
      val = nil
      val = $2 if line_a[3]=~/^(time=)?([0-9\.]+)/
      key = "#{line_a[1]}_#{line_a[2]}"
      unless config_set.has_key?(key)
        rrd.config(key, cnf) unless cnf.nil?
        config_set[key] = 1
      end
      rrd.store(key, time, val.to_f) unless val.nil?
    end
  end
end
end

