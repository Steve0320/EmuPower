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
		def parse_amount(prop, mul_prop = 'Multiplier', div_prop = 'Divisor')

			multiplier = parse_hex(mul_prop)
			divisor = parse_hex(div_prop)
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

	###
	# Begin notification objects
	###

	class TimeCluster < Notification

		attr_accessor :utc_time
		attr_accessor :local_time

		def build(hash)
			self.utc_time = parse_timestamp('UTCTime')
			self.local_time = parse_timestamp('LocalTime')
		end

	end

	class MessageCluster < Notification

		attr_accessor :id
		attr_accessor :text
		attr_accessor :priority
		attr_accessor :start_time
		attr_accessor :duration
		attr_accessor :confirmation_required
		attr_accessor :confirmed
		attr_accessor :queue

		def build(hash)
			self.id = hash['Id']
			self.text = hash['Text']
			self.priority = hash['Priority']
			self.start_time = parse_timestamp('StartTime')
			self.duration = parse_hex('Duration')
			self.confirmation_required = parse_bool('ConfirmationRequired')
			self.confirmed = parse_bool('Confirmed')
			self.queue = hash['Queue']
		end

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

	# Note: This has no fields except DeviceMacId and MeterMacId
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

	class FastPollStatus < Notification

		attr_accessor :frequency
		attr_accessor :end_time

		def build(hash)
			self.frequency = parse_hex('Frequency')
			self.end_time = parse_timestamp('EndTime')
		end

	end

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

	class LastPeriodUsage < Notification

		attr_accessor :usage
		attr_accessor :digits_right
		attr_accessor :digits_left
		attr_accessor :suppress_leading_zeroes
		attr_accessor :start_date
		attr_accessor :end_date

		def build(hash)
			self.usage = parse_amount('LastUsage')
			self.digits_right = parse_hex('DigitsRight')
			self.digits_left = parse_hex('DigitsLeft')
			self.suppress_leading_zeroes = parse_bool('SuppressLeadingZero')
			self.start_date = parse_timestamp('StartDate')
			self.end_date = parse_timestamp('EndDate')
		end

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

	class BlockPriceDetail < Notification

		attr_accessor :current_start
		attr_accessor :current_duration
		attr_accessor :block_consumption
		attr_accessor :number_of_blocks
		attr_accessor :currency_code
		attr_accessor :trailing_digits

		def build(hash)
			self.current_start = parse_timestamp('CurrentStart')
			self.current_duration = parse_hex('CurrentDuration')
			self.block_consumption = parse_amount(
					'BlockPeriodConsumption',
					'BlockPeriodConsumptionMultiplier',
					'BlockPeriodConsumptionDivisor'
			)

			# Note: Not sure if multiplier/divisor are supposed to tie in here
			self.number_of_blocks = parse_amount('NumberOfBlocks')

			self.currency_code = parse_hex('Currency')
			self.trailing_digits = parse_hex('TrailingDigits')

		end

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

end
