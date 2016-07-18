#!/opt/chef/embedded/bin/ruby

class String
  def to_bool
    if self == "true" then true else false end
  end
end

def format_key(k)
  # Replace spaces with underscores
  k.gsub!(/\s/, "_")
  # Replace parens with in_
  k.gsub!(/\((\w+)\)/, "in_\\1")
  # Downcase
  # Convert to symbol
  k.downcase.to_sym
end

def get_number(str)
  if str == "NaN" || str.empty?
    nil
  elsif str[/\d+\.\d+/]
    str[/\d+\.\d+/].to_f
  else
    str[/\d+/].to_i
  end
end

def puts_metric_line(name, value, value_type=nil)
  unless value_type
    case value
    when String, TrueClass, FalseClass
      value_type = "string"
    when Fixnum, Bignum
      value_type = "int64"
    when Float
      value_type = "double"
    end
  end
  puts "metric #{name} #{value_type} #{value}"
end

nodetool_path = ARGV.shift
if nodetool_path.nil?
  puts "status must specify a path to nodetool"
  exit(1)
end
command = ARGV.shift || "general"
hostname = ARGV.shift
port = ARGV.shift

begin
  cmd = nodetool_path
  cmd << "-h #{hostname}" if hostname
  cmd << "-p #{port}" if port
  info = `#{cmd} info 2>&1`
rescue Errno::ENOENT
  puts "status nodetool command not found"
  exit(1)
end

unless $?.success?
  puts "status #{info}"
  exit(1)
end

lines = info.split("\n")

results = {
  :general => [],
  :key_cache => [],
  :row_cache => [],
  :heap_memory_in_mb => []
}
lines.each do |line|
  k,v = line.split(":").map(&:strip)
  k = format_key(k)
  case k
  when :load
    results[:general] << [:load_in_kb, get_number(v)]
  when :gossip_active, :thrift_active
    results[:general] << [k, v.to_bool]
  when :heap_memory_in_mb
    used, available = v.split("/").map { |i| i.strip.to_f }
    results[k] << ["#{k}_used", used]
    results[k] << ["#{k}_available", available]
  when :key_cache, :row_cache
    vals = v.split(", ")
    [
      :size_in_bytes,
      :capacity_in_bytes,
      :hits,
      :requests,
      :recent_hit_rate,
      :save_period_in_seconds
    ].each_with_index do |subkey, i|
      results[k] << ["#{k}_#{subkey}", get_number(vals[i])]
    end
  when :exceptions, :generation_no, :uptime_in_seconds
    results[:general] << [k, v.to_i, "gauge"]
  when :token
    # Do nothing with the token line
  else
  results[:general] << [k,v]
  end
end

case command
when "key_cache", "row_cache", "heap_memory_in_mb", "general"
  puts "status cassandra #{command} metrics gathered successfully"
  results[command.to_sym].each do |res|
    puts_metric_line(res[0], res[1], res[2])
  end
else
  puts "status invalid command chosen entered"
end
