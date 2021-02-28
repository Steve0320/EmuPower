# Notification types. Provides convenience calculators and
# accessors for the notifications sent by the EMU device.

require 'nori'

class EmuPower::Notifications

	# Base class for notifications
	class Notification

		# Timestamp of Jan 1st 2000. Used to shift epoch to standard timestamp.
		UNIX_TIME_OFFSET = 946684800

		attr_accessor :raw
		attr_accessor :device_mac
		attr_accessor :meter_mac
		attr_accessor :timestamp

		def initialize(hash)

			@raw = hash

			# All messages may contain this metadata
			@device_mac = @raw['DeviceMacId']
			@meter_mac = @raw['MeterMacId']

			# The EMU sets timestamps relative to Jan 1st 2000 UTC. We convert
			# these into more standard Unix epoch timestamps by adding the
			# appropriate offset.
			@timestamp = parse_timestamp('TimeStamp')

			# Build out type-specific fields
			build(hash)

		end

		def build(hash)
			# Overridden by subclasses
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

		# Calculate real total from divisors and multipliers
		def parse_amount(prop)

			multiplier = parse_hex('Multiplier')
			divisor = parse_hex('Divisor')
			v = parse_hex(prop)

			return 0.0 if v.nil? || multiplier.nil? || divisor.nil?
			return multiplier * v / Float(divisor)

		end

		def to_s
			"#{self.class.root_name} Notification: #{@raw.to_s}"
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

	class NetworkInfo < Notification

		attr_accessor :coordinator_mac
		attr_accessor :status
		attr_accessor :description
		attr_accessor :pan_id
		attr_accessor :channel
		attr_accessor :short_address
		attr_accessor :link_strength

		def build(hash)
			self.coordinator_mac = parse_hex('CoordMacId')
			self.status = hash['Status']
			self.description = hash['Description']
			self.pan_id = hash['ExtPanId']
			self.channel = hash['Channel']
			self.short_address = hash['ShortAddr']
			self.link_strength = parse_hex('LinkStrength')
		end

	end

	class ConnectionStatus < Notification

		attr_accessor :status
		attr_accessor :description
		attr_accessor :pan_id
		attr_accessor :channel
		attr_accessor :short_address
		attr_accessor :link_strength

		def build(hash)
			self.status = hash['Status']
			self.description = hash['Description']
			self.pan_id = hash['ExtPanId']
			self.channel = hash['Channel']
			self.short_address = hash['ShortAddr']
			self.link_strength = parse_hex('LinkStrength')
		end

	end

	# TODO
	class MeterList < Notification
	end

	class MeterInfo < Notification

		attr_accessor :type
		attr_accessor :nickname
		attr_accessor :account
		attr_accessor :auth
		attr_accessor :host
		attr_accessor :enabled

		def build(hash)
			self.type = parse_hex('Type')
			self.nickname = hash['Nickname']
			self.account = hash['Account']
			self.auth = hash['Auth']
			self.host = hash['Host']
			self.enabled = parse_bool('Enabled')
		end

	end

	class DeviceInfo < Notification

		attr_accessor :install_code
		attr_accessor :link_key
		attr_accessor :firmware_version
		attr_accessor :hardware_version
		attr_accessor :image_type
		attr_accessor :manufacturer
		attr_accessor :model
		attr_accessor :date_code

		def build(hash)
			self.install_code = hash['InstallCode']
			self.link_key = hash['LinkKey']
			self.firmware_version = hash['FWVersion']
			self.hardware_version = hash['HWVersion']
			self.image_type = hash['ImageType']
			self.manufacturer = hash['Manufacturer']
			self.model = hash['ModelId']
			self.date_code = hash['DateCode']
		end

	end

	# TODO
	class FastPollStatus < Notification
	end

	# TODO: Billing periods

	class CurrentPeriodUsage < Notification

		attr_accessor :usage
		attr_accessor :digits_right
		attr_accessor :digits_left
		attr_accessor :suppress_leading_zeroes
		attr_accessor :start_date

		def build(hash)
			self.usage = parse_amount('CurrentUsage')
			self.digits_right = parse_hex('DigitsRight')
			self.digits_left = parse_hex('DigitsLeft')
			self.suppress_leading_zeroes = parse_bool('SuppressLeadingZero')
			self.start_date = parse_timestamp('StartDate')

		end

	end

	# TODO
	class LastPeriodUsage < Notification
	end

	class InstantaneousDemand < Notification

		attr_accessor :demand
		attr_accessor :digits_right
		attr_accessor :digits_left
		attr_accessor :suppress_leading_zeroes

		def build(hash)
			self.demand = parse_amount('Demand')
			self.digits_right = parse_hex('DigitsRight')
			self.digits_left = parse_hex('DigitsLeft')
			self.suppress_leading_zeroes = parse_bool('SuppressLeadingZero')
		end

	end

	class CurrentSummationDelivered < Notification

		attr_accessor :delivered
		attr_accessor :received
		attr_accessor :digits_right
		attr_accessor :digits_left
		attr_accessor :suppress_leading_zeroes

		def build(hash)
			self.delivered = parse_amount('SummationDelivered')
			self.received = parse_amount('SummationReceived')
			self.digits_right = parse_hex('DigitsRight')
			self.digits_left = parse_hex('DigitsLeft')
			self.suppress_leading_zeroes = parse_bool('SuppressLeadingZero')
		end

	end

	# TODO
	class PriceCluster < Notification

		attr_accessor :price
		attr_accessor :currency_code		# This is an ISO 3-digit currency code. 840 is USD
		attr_accessor :trailing_digits
		attr_accessor :tier
		attr_accessor :start_time
		attr_accessor :duration
		attr_accessor :label

		def build(hash)
			self.price = parse_hex('Price')
			self.currency_code = parse_hex('Currency')
			self.trailing_digits = parse_hex('TrailingDigits')
			self.tier = parse_hex('Tier')
			self.start_time = parse_timestamp('StartTime')
			self.duration = parse_hex('Duration')
			self.label = hash['RateLabel']
		end

	end

	# TODO
	class BlockPriceDetail < Notification
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

	# Dispatch to the appropriate container class based
	# on the type. Expects a data hash. Returns nil on
	# bad message.
	def self.construct(xml)

		hash = Nori.new.parse(xml)

		# Extract the root of the hash and dispatch to the appropriate
		# container class.
		type, data = hash.first

		return nil unless notify_roots.include?(type)

		klass = self.const_get(type)
		return klass.new(data)

	end

	# Helper to get the element names of all types
	def self.notify_roots
		return Notification.subclasses.map(&:root_name)
	end

end
