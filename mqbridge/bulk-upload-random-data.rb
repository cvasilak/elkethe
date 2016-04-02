require 'rubygems'
require 'bundler/setup'

require 'influxdb'

INFLUXDB_CREDS = {username: "#{ENV["INFLUXDB_USER"]}", password: "#{ENV["INFLUXDB_PASS"]}"}
@influxdb_client = InfluxDB::Client.new 'elkethe', {host: 'influxdb'}.merge(INFLUXDB_CREDS)

(1420070400000..1461974400000).step(60000) do |timestamp|

  data = [
      {
          series: 'voltage',
          tags: {tank: 'Tank-A3'},
          values: {value: rand(0.1..90.0)},
          timestamp: timestamp
      },
      {
          series: 'knocks',
          tags: {tank: 'Tank-A3'},
          values: {value: rand(0.1..40.0)},
          timestamp: timestamp
      },
      {
          series: 'errors',
          tags: {tank: 'Tank-A3'},
          values: {value: rand(0.1..20.0)},
          timestamp: timestamp
      }
  ]

  puts "--> #{data}"
  @influxdb_client.write_points(data, 'ms')

end
