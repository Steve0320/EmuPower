# Notification types. Provides convenience calculators and
# accessors for the notifications sent by the EMU device.
class EmuPower::Types

	# Base class for notifications
	class Notification

		UNIX_TIME_OFFSET = 946684800

		attr_accessor :raw
		attr_accessor :device_mac
		attr_accessor :meter_mac
		attr_accessor :timestamp

		def initialize(hash)
			@raw = hash
			@device_mac = @raw['DeviceMacId']
			@meter_mac = @raw['MeterMacId']
			build(hash)
		end

		def build(hash)
		end

		# The EMU sets timestamps relative to Jan 1st 2000 UTC. We convert
		# these into more standard Unix epoch timestamps by adding the
		# appropriate offset.
		def timestamp
			parse_timestamp('TimeStamp')
		end

		def parse_timestamp(prop)
			v = @raw[prop]
			return nil if v == nil
			return Integer(v) + 946684800
		end

		def parse_hex(prop)
			v = @raw[prop]
			return nil if v.nil?
			return Integer(v)
		end
		
		def parse_bool(prop)
			v = @raw[prop]
			return nil if v.nil?
			return (@raw[prop] == 'Y') ? true : false
		end

		# Name of the XML root object corresponding to this type
		def self.root_name
			return self.name.split('::').last
		end

		def self.subclasses
			return ObjectSpace.each_object(::Class).select do |k|
				k < self
			end
		end

	end

	# TODO
	class ConnectionStatus < Notification
	end

	# TODO
	class DeviceInfo < Notification
	end

	class ScheduleInfo < Notification

		attr_accessor :mode
		attr_accessor :event
		attr_accessor :frequency
		attr_accessor :enabled

		def build(hash)
			self.mode = hash['Mode']
			self.event = hash['Event']
			self.frequency = parse_hex('Frequency')
			self.enabled = parse_bool('Enabled')
		end

	end

	# TODO
	class MeterList < Notification
	end

	# TODO
	class MeterInfo < Notification
	end

	# TODO
	class NetworkInfo < Notification
	end

	class TimeCluster < Notification

		attr_accessor :utc_time
		attr_accessor :local_time

		def build(hash)
			self.utc_time = parse_timestamp('UTCTime')
			self.local_time = parse_timestamp('LocalTime')
		end

	end

	# TODO
	class MessageCluster < Notification
	end

	# TODO
	class PriceCluster < Notification
	end

	class InstantaneousDemand < Notification

		attr_accessor :raw_demand
		attr_accessor :multiplier
		attr_accessor :divisor
		attr_accessor :digits_right
		attr_accessor :digits_left
		attr_accessor :suppress_leading_zeroes

		def build(hash)
			self.raw_demand = parse_hex('Demand')
			self.multiplier = parse_hex('Multiplier')
			self.divisor = parse_hex('Divisor')
			self.digits_right = parse_hex('DigitsRight')
			self.digits_left = parse_hex('DigitsLeft')
			self.suppress_leading_zeroes = parse_bool('SuppressLeadingZero')
		end

		# Return computed demand in KW. This may return nil if data is missing.
		def demand
			return 0 if self.divisor == 0
			return nil if self.multiplier.nil? || self.raw_demand.nil? || self.divisor.nil?
			return self.multiplier * self.raw_demand / Float(self.divisor)
		end

	end

	class CurrentSummationDelivered < Notification

		attr_accessor :raw_delivered
		attr_accessor :raw_received
		attr_accessor :multiplier
		attr_accessor :divisor
		attr_accessor :digits_right
		attr_accessor :digits_left
		attr_accessor :suppress_leading_zeroes

		def build(hash)

			self.raw_delivered = parse_hex('SummationDelivered')
			self.raw_received = parse_hex('SummationReceived')
			self.multiplier = parse_hex('Multiplier')
			self.divisor = parse_hex('Divisor')
			self.digits_right = parse_hex('DigitsRight')
			self.digits_left = parse_hex('DigitsLeft')
			self.suppress_leading_zeroes = parse_bool('SuppressLeadingZero')

		end

		def delivered
			return 0 if self.raw_delivered == 0
			return nil if self.multiplier.nil? || self.raw_delivered.nil? || self.divisor.nil?
			return self.multiplier * self.raw_delivered / Float(self.divisor)
		end

		def received
			return 0 if self.divisor == 0
			return nil if self.multiplier.nil? || self.raw_received.nil? || self.divisor.nil?
			return self.multiplier * self.raw_received / Float(self.divisor)
		end
		
	end

	# TODO
	class CurrentPeriodUsage < Notification
	end

	# TODO
	class LastPeriodUsage < Notification
	end

	# TODO
	class ProfileData < Notification
	end

	# Dispatch to the appropriate container class based
	# on the type. Expects a data hash. Returns nil on
	# bad message.
	def self.construct(data)

		type = data['MessageType']
		return nil if type == nil || !notify_roots.include?(type)

		klass = self.const_get(type)
		return klass.new(data)

	end

	# Helper to get the element names of all types
	def self.notify_roots
		return Notification.subclasses.map(&:root_name)
	end

end
