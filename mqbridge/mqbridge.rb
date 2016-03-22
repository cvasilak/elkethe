require 'rubygems'
require 'bundler/setup'

require 'mqtt'
require 'hawkular_all'

HAWKULAR_CREDS = {username: "#{ENV["HAWKULAR_USER"]}", password: "#{ENV["HAWKULAR_PASS"]}"}
MQTT_CREDS = {username: "#{ENV["MQTT_USER"]}", password: "#{ENV["MQTT_PASS"]}"}

TENANT= {tenant: 'elkethe'}

METRICS_BASE = 'http://hawkular:8080/hawkular/metrics'
MQTT_BROKER = "mqtt://#{MQTT_CREDS[:username]}:#{MQTT_CREDS[:password]}@mosquitto"

@queue = []

@metrics_client = Hawkular::Metrics::Client.new(METRICS_BASE, HAWKULAR_CREDS, TENANT)

def process_metric(message)
  return if message.nil? || message.empty?

  # data format is : 2 Tank-A5 3 0 1 90
  fields = message.split(' ')

  if fields.size < 6
    puts 'invalid record detected, ignoring'
    return
  end

  data = [{ id: "#{fields[1]}_voltage", data: [{:value => fields[2]}]},
          { id: "#{fields[1]}_knocks",  data: [{:value => fields[3]}]},
          { id: "#{fields[1]}_errors",  data: [{:value => fields[4]}]}]

  begin
    @metrics_client.push_data(gauges: data)

    # There was data queued, send it now
    if @queue.size > 0
      @queue.each do |_entry|
        data = @queue.pop
        @metrics_client.push_data(gauges: data)
      end
    end
  rescue
    # Pushing failed -> we need to pool and try later
    @queue.push data
  end

end

# subscribe to MQTT and listen..
MQTT::Client.connect(MQTT_BROKER) do |c|
  c.subscribe('/elkethe/tanks/+')

  puts 'subscribed to MQTT, ready.'

  c.get('/elkethe/tanks/+') do |topic,message|
    puts "#{topic}: #{message}"

    Thread.new { process_metric(message) }
  end

end


