require 'rubygems'
require 'bundler/setup'

require 'influxdb'

INFLUXDB_CREDS = {username: "#{ENV["INFLUXDB_USER"]}", password: "#{ENV["INFLUXDB_PASS"]}"}
@influxdb_client = InfluxDB::Client.new 'behaviour', {host: 'influxdb', retry: false, time_precision: 'ms'}.merge(INFLUXDB_CREDS)

(1423194517000..1460332800000).step(1000) do |timestamp|

  data = [
      {
          series: 'voltage',
          tags: {tank: 'Tank-A99'},
          values: {value: rand(2.70..3.30)},
          timestamp: timestamp
      },
      {
          series: 'knocks',
          tags: {tank: 'Tank-A99'},
          values: {value: rand(1..20)},
          timestamp: timestamp
      },
      {
          series: 'errors',
          tags: {tank: 'Tank-A99'},
          values: {value: rand(0..5)},
          timestamp: timestamp
      }
  ]

  puts "--> #{data}"
  @influxdb_client.write_points(data)

end
