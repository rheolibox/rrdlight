#!/opt/script/autoadm/tools/bin/ruby

require 'pp'

class RRD

  def initialize(file, max_duration=nil, slot_time=nil)
    @file = file
    if File.exists?(file)
      @rrd = Marshal.load(File.open(file))
      return
    end
    time_now = (Time.now.to_i/slot_time)*slot_time
    @rrd = {
      max_duration: max_duration, slot_time: slot_time,
      slots: {}
    }
    time_at = time_now
    while time_at > (time_now - max_duration)
      @rrd[:slots][time_at] = nil
      time_at -= slot_time
    end
  end

  def save
    File.open(@file, "wb") do |f|
      f.write Marshal.dump(@rrd)
    end
  end

  def add(time, value)
    time_at = (time/@rrd[:slot_time])*@rrd[:slot_time]
    if @rrd[:slots].has_key?(time_at)
      @rrd[:slots][time_at] = value
      return
    end
    if time_at < @rrd[:slots].keys.sort[0]
      puts "Value is older => ignore value (#{time} #{value})"
      return
    end
    if time_at > @rrd[:slots].keys.sort[-1]
      time_i = @rrd[:slots].keys.sort[-1] + @rrd[:slot_time]
      count = 0
      while time_i <= time_at
        @rrd[:slots][time_i] = nil
        time_i += @rrd[:slot_time]
        count += 1
      end
      @rrd[:slots][time_at] = value
      time_i = @rrd[:slots].keys.sort[0]
      1.upto(count) do |i|
        @rrd[:slots].delete(time_i)
        time_i += @rrd[:slot_time]
      end
    end
  end
end

rrd = RRD.new("test.rrd", (86400*1.5), 300)
rrd.add(Time.now.to_i+1200, 1.2)
rrd.save

#=EOF
