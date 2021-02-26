# Basic example for writing metrics to InfluxDB. To use, replace the
# constants with the appropriate values for your system. This will
# write two measurements, "usage" and "summation", to your database
# when new ones are available.

require 'emu_power'
require 'influxdb-client'

SERIAL_PORT = '<YOUR PORT HERE>'
HOST = "<INFLUXDB HOST URL>"
TOKEN = "<YOUR AUTH TOKEN>"
BUCKET = '<YOUR BUCKET>'
ORGANIZATION = '<YOUR ORGANIZATION>'

api = EmuPower::Api.new(SERIAL_PORT)
client = InfluxDB2::Client.new(HOST, TOKEN, bucket: BUCKET, org: ORGANIZATION, use_ssl: false, precision: InfluxDB2::WritePrecision::SECOND)
write_api = client.create_write_api

# Send data to InfluxDB on usage notification
api.callback(EmuPower::Types::InstantaneousDemand) do |notification|

	next if notification.demand.nil?
	
	data = {
		name: 'usage',
		fields: { demand: notification.demand },
		time: notification.timestamp
	}

	write_api.write(data: data)

end

api.callback(EmuPower::Types::CurrentSummationDelivered) do |notification|

	next if notification.delivered.nil? && notification.received.nil?

	data = {
		name: 'summation',
		fields: {
			delivered: notification.delivered,
			received: notification.received
		},
		time: notification.timestamp
	}

	write_api.write(data: data)

end

api.start_serial
