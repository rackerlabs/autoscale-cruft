#!/opt/chef/embedded/bin/ruby
require "json"
require "rest-client"
require "mixlib/cli"

class EsCLI
  include Mixlib::CLI

  option :server,
    :short => "-s HOSTNAME",
    :long => "--server HOSTNAME",
    :description => "Hostname or IP of server to query",
    :default => `ifconfig eth2 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`.chomp

  option :port,
    :short => "-p PORT",
    :long => "--port PORT",
    :default => 9200,
    :description => "Port to connect to"

  option :help,
    :short => "-h",
    :long => "--help",
    :description => "Show this message",
    :on => :tail,
    :boolean => true,
    :show_options => true,
    :exit => 0
end

cli = EsCLI.new
cli.parse_options

base_url = "http://#{cli.config[:server]}:#{cli.config[:port]}"

cluster_url = File.join(base_url, "_cluster", "health")
res = RestClient.get cluster_url
if res.code == 200
  cluster = JSON.parse(res.body)
else
  puts "status cluster returned #{res.code}"
  exit 1
end

node_url = File.join(base_url, "_nodes", cli.config[:server])
node_url = "#{node_url}?jvm=true"
res = RestClient.get node_url
if res.code == 200
  nodes = JSON.parse(res.body)
  node_id = nodes["nodes"].keys.first
  node_info = nodes["nodes"][node_id]
else
  puts "status node returned #{res.code}"
  exit 1
end

puts "status elasticsearch info collected"
puts "metric cluster_status string #{cluster["status"]}"
puts "metric number_of_nodes int #{cluster["number_of_nodes"]}"
puts "metric active_shards int #{cluster["active_shards"]}"
puts "metric relocating_shards int #{cluster["relocating_shards"]}"
puts "metric initializing_shards int #{cluster["initializing_shards"]}"
puts "metric unassigned_shards int #{cluster["unassigned_shards"]}"

# Test that Elasticsearch is running using the latest Java version available on
# the server
output = `java -version 2>&1`
available_java_version = $1 if output =~ /java version "(.*)"/
running_java_version = node_info["jvm"]["version"]
puts "metric available_java string #{available_java_version}"
puts "metric running_java string #{running_java_version}"
