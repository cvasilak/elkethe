require 'rubygems'
require 'bundler/setup'

require 'mqtt'
require 'influxdb'

MQTT_CREDS = {username: "#{ENV["MQTT_USER"]}", password: "#{ENV["MQTT_PASS"]}"}
MQTT_BROKER = "mqtt://#{MQTT_CREDS[:username]}:#{MQTT_CREDS[:password]}@mosquitto"

INFLUXDB_CREDS = {username: "#{ENV["INFLUXDB_USER"]}", password: "#{ENV["INFLUXDB_PASS"]}"}
@influxdb_client = InfluxDB::Client.new 'elkethe', {host: 'influxdb'}.merge(INFLUXDB_CREDS)

@queue = []

def process_metric(message)
  return if message.nil? || message.empty?

  # data format is : 2 Tank-A5 3 0 1 90
  fields = message.split(' ')

  if fields.size < 6
    puts 'invalid record detected, ignoring'
    return
  end

  data = [
      {
          series: 'voltage',
          tags: {tank: fields[1]},
          values: {value: fields[2].to_f}
      },
      {
          series: 'knocks',
          tags: {tank: fields[1]},
          values: {value: fields[3].to_f}
      },
      {
          series: 'errors',
          tags: {tank: fields[1]},
          values: {value: fields[4].to_f}
      }
  ]

  begin
    @influxdb_client.write_points(data)

    # There was data queued, send it now
    if @queue.size > 0
      @queue.each do |_entry|
        data = @queue.pop
        influxdb.write_points(data)
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

  c.get('/elkethe/tanks/+') do |topic, message|
    puts "#{topic}: #{message}"

    Thread.new { process_metric(message) }
  end

end


