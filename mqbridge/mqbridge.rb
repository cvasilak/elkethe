require 'rubygems'
require 'bundler/setup'

require 'mqtt'
require 'influxdb'

MQTT_CREDS = {username: "#{ENV["MQTT_USER"]}", password: "#{ENV["MQTT_PASS"]}"}
INFLUXDB_CREDS = {username: "#{ENV["INFLUXDB_USER"]}", password: "#{ENV["INFLUXDB_PASS"]}"}

MQTT_BROKER = "mqtt://#{MQTT_CREDS[:username]}:#{MQTT_CREDS[:password]}@mosquitto"

def process_metric(message)
  return if message.nil? || message.empty?

  # data format is : 2 Tank-A5 3 0 1 90
  fields = message.split(' ')

  if fields.size < 6 || !fields[1].start_with?('Tank-')
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

  @influxdb_client.write_points(data)
end

# attempt to connect to db
@influxdb_client = InfluxDB::Client.new 'elkethe', {host: 'influxdb', retry: false}.merge(INFLUXDB_CREDS)
# do an initial ping to verify  connection, exit eager upon failure can't do much
@influxdb_client.list_databases

# subscribe to MQTT and listen..
MQTT::Client.connect(MQTT_BROKER) do |c|
  c.subscribe('/elkethe/tanks/+')

  puts 'subscribed to MQTT, ready.'

  c.get('/elkethe/tanks/+') do |topic, message|
    puts "#{topic}: #{message}"

    Thread.new { process_metric(message) }
  end

end


