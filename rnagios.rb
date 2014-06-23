#!/usr/bin/env ruby

require 'bundler'
Bundler.require

require 'rredis'

rrd = RReDis.new

config_05min = 
{:steps=>300, :rows=>10080, 
 :aggregations=>["average", "min", "max"], 
 :rra => [ {:steps=>900, :rows=>2976, :xff=>0.5},
           {:steps=>3600, :rows=>8760, :xff=>0.5}]}

config_10min = 
{:steps=>10, :rows=>17280, 
 :aggregations=>["average", "min", "max"], 
 :rra => [ {:steps=>60, :rows=>10080, :xff=>0.5},
           {:steps=>900, :rows=>2976, :xff=>0.5},
           {:steps=>3600, :rows=>8760, :xff=>0.5}]}

# in produktion am besten mit tail oeffnen
File.open("service-perfdata") do |f|
  f.each do |line|
    line.chomp!
    line_a = line.split(/:/)
    next if line_a.size < 4
    time = line_a[0].to_i/300*300
    data = []
    if line_a[2]=~/^b_/
next
      sub = line_a[2].gsub(/^abx_/,'')
      line_a[3].split(/;/).each do |vals|
        val = vals.split(/ /)
        rrd.store "#{line_a[1]}_#{sub}_#{val[0]}", time, val[1].to_f
      end
    else
      val = nil
      val = $1 if line_a[3]=~/^time=([0-9\.]+)s/
      rrd.config("#{line_a[1]}_#{line_a[2]}", config_05min)
      rrd.store("#{line_a[1]}_#{line_a[2]}", time, val.to_f) unless val.nil?
    end
  end
end

