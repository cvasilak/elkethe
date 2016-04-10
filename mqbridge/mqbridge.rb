require 'rubygems'
require 'bundler/setup'

require 'mqtt'
require 'influxdb'
require 'timers'

MQTT_CREDS = {username: "#{ENV["MQTT_USER"]}", password: "#{ENV["MQTT_PASS"]}"}
INFLUXDB_CREDS = {username: "#{ENV["INFLUXDB_USER"]}", password: "#{ENV["INFLUXDB_PASS"]}"}

MQTT_BROKER = "mqtt://#{MQTT_CREDS[:username]}:#{MQTT_CREDS[:password]}@mosquitto"

$timers = Timers::Group.new
$tanks_feeder = Hash.new

def process_metric(message)
  return if message.nil? || message.empty?

  # data format is : 2 Tank-A5 3 0 1 90
  fields = message.split(' ')

  tank = fields[1]

  if fields.size < 6 || !tank.start_with?('Tank-')
    puts 'invalid record detected, ignoring'
    return
  end  

  data = [
      {
          series: 'voltage',
          tags: {tank: tank},
          values: {value: fields[2].to_f}
      },
      {
          series: 'errors',
          tags: {tank: tank},
          values: {value: fields[4].to_f}
      }
  ]

  knocks = fields[3].to_f
  if knocks > 0
    puts "['#{tank}'] knocks > 0 detected, appending it"
    data << {
          series: 'knocks',
          tags: {tank: tank},
          values: {value: knocks}
      }

    if !$tanks_feeder.has_key?(tank)  
      puts "['#{tank}'] knocks > 0 detected, updating 'feeder' and scheduling clearing after 15 secs"
      data << {
        series: 'feeder',
        tags: {tank: tank},
        values: {value: "Feeder-Started"}
      }

      # marker tank feeder 'on transit'
      $tanks_feeder[tank] = "on transit"

      Thread.new {
        feeder = $timers.after(15) do
          data = {
            tags: {tank: tank},
            values: {value: "Feeder-Stopped"}
          }
      
          puts "['#{tank}'] 'clearing feeder'"
          @influxdb_client.write_point('feeder', data)
          $tanks_feeder.delete(tank)
        end    

        $timers.wait
      }  
    end
  end

  @influxdb_client.write_points(data)
end

# attempt to connect to db
@influxdb_client = InfluxDB::Client.new 'elkethe', {host: 'influxdb', retry: false, time_precision: 'ms'}.merge(INFLUXDB_CREDS)
# do an initial ping to verify connection, exit eager upon failure, can't do much either
@influxdb_client.list_databases

# subscribe to MQTT and listen..
MQTT::Client.connect(MQTT_BROKER) do |c|
  c.subscribe('/elkethe/tanks/+')

  c.get('/elkethe/tanks/+') do |topic, message|
    puts "#{topic}: #{message}"

    process_metric(message)
  end
  
  puts "Ready."
end