#!/opt/chef/embedded/bin/ruby

@host = ARGV.shift
@port = ARGV.shift
queues = ARGV.dup

def redis_command(cmd)
  output = `redis-cli -h #{@host} -p #{@port} #{cmd}`
  if $? != 0
    puts "status #{output}"
    exit(1)
  end
  output
end

queue_lengths = {}
queues.each do |q|
  queue_lengths[q] = redis_command("llen #{q}").chomp
end

metrics = {}
info = redis_command("info")
info = info.split("\r\n").select { |line| line.include? ":" }
info.each do |line|
  name, metric = line.split(":")
  metrics[name] = metric
end

puts "status Redis metrics collected"
queue_lengths.each do |k,v|
  puts "metric queue_#{k} uint32 #{v}"
end

[
  ["redis_version", "string"],
  ["connected_clients", "uint32"],
  ["used_memory", "uint64"],
].each do |m|
  puts "metric #{m[0]} #{m[1]} #{metrics[m[0]]}"
end
