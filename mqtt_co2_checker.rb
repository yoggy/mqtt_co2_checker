#!/usr/bin/ruby
require 'mqtt'
require 'json'
require 'yaml'
require 'ostruct'
require 'pp'

$stdout.sync = true
Dir.chdir(File.dirname($0))
$current_dir = Dir.pwd

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

$conf = OpenStruct.new(YAML.load_file("config.yaml"))

$conn_opts = {
  remote_host: $conf.mqtt_host
}

if !$conf.mqtt_port.nil? 
  $conn_opts["remote_port"] = $conf.mqtt_port
end

if $conf.mqtt_use_auth == true
  $conn_opts["username"] = $conf.mqtt_username
  $conn_opts["password"] = $conf.mqtt_password
end

MQTT::Client.connect($conn_opts) do |mqtt|
  $log.info "connected..."
  $log.info "subscribe topic=" + $conf.mqtt_subscribe_topic
  mqtt.subscribe($conf.mqtt_subscribe_topic)

  mqtt.get do |t, m|
    json = JSON.parse(m)
    $log.info "received message = " + m
    if json["co2"] >= 1000
      msg = "室内のCO2濃度が1000ppmを超えています。換気することをお勧めします"
      $log.info "publish message : " + msg
      mqtt.publish($conf.mqtt_publish_topic, msg)
	end
    exit(0)
  end
end

