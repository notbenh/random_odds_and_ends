#!/usr/bin/env ruby
require 'plist'

# walk the silly struct from Apple and just collect just the data we care about 
def grab_items(device_hash = Plist::parse_xml( `system_profiler -xml SPUSBDataType` ).first)
  vals = []
  if device_hash.is_a? Array
    vals << device_hash.collect {|dh| grab_items dh}
  else
    if device_hash.has_key? "_name" 
      vals << { :name => device_hash["_name"], :power_used => device_hash["j_bus_power_used"].to_i, :power => device_hash["h_bus_power"].to_i }
    end

    vals << device_hash["_items"].collect {|dh| grab_items dh} if device_hash.has_key? "_items"
  end
  vals.flatten
end

def report_devices (action, devices)
  puts "--  #{action} (#{devices.length}) --"
  total = 0
  devices.each { |x| 
                 total+= x[:power_used]
                 puts "  #{x[:name]} (#{x[:power_used]})"
               }
  puts "  ------------------------------"
  puts "  Total power: #{total}"
  puts ''
end

# get the current stack of USB devices
pre = grab_items

# tell the user hit a button when the new device has been inserted
puts 'hit a key once you insert the device'
gets # just hit a key tada don't really care just basicly a sleep(?)
#TODO: at some point it would be nice to listen for a usbdevice input if that's possible

# get the current stack of USB devices
post = grab_items

# output what has changed
report_devices "REMOVED", pre - post
report_devices "ADDED", post - pre
