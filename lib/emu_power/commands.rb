# Collection of command types for controlling various functions on the EMU
# device. These should be constructed and passed as arguments to the API
# object's issue_command method.

class EmuPower::Commands

	# Base class that all commands inherit from
	class Command

		def initialize(name)
			@data = { name: name }
		end

		def to_command

			tags = @data.map do |k, v|
				tag = k.to_s.capitalize
				next "<#{tag}>#{v}</#{tag}>"
			end

			return "<Command>#{tags.join}</Command>"
		end

		# Convert bool to Y or N
		def to_yn(bool)
			return bool ? 'Y' : 'N'
		end

		# Convert int to 0xABCD hex
		def to_hex(i, width = 8)
			return "0x%0#{width}x" % i
		end

	end

	class GetNetworkInfo < Command
		def initialize
			super('get_network_info')
		end
	end

	class GetNetworkStatus < Command
		def initialize
			super('get_network_status')
		end
	end

	class GetInstantaneousDemand < Command
		def initialize
			super('get_instantaneous_demand')
		end
	end

	class GetPrice < Command
		def initialize
			super('get_price')
		end
	end

	class GetMessage < Command
		def initialize
			super('get_message')
		end
	end

	# TODO: Confirm Message

	class GetCurrentSummation < Command
		def initialize
			super('get_current_summation')
		end
	end

	# TODO: Get History Data

	# Note: This doesn't seem to work. The command is issued successfully, but
	# the EMU does not update any schedule info. This may be disallowed by the
	# meter or something.
	class SetSchedule < Command

		EVENTS = %w[time message price summation demand scheduled_prices profile_data billing_period block_period]

		def initialize(event, frequency, enabled)
			super('set_schedule')
			raise ArgumentError.new("Event must be one of #{EVENTS.join(', ')}") unless EVENTS.include?(event)
			@data[:event] = event
			@data[:frequency] = to_hex(frequency, 4)
			@data[:enabled] = to_yn(enabled)
		end

	end

	# TODO: Add event field
	class GetSchedule < Command

		EVENTS = %w[time message price summation demand scheduled_prices profile_data billing_period block_period]

		def initialize(event = nil)

			super('get_schedule')

			unless event.nil?
				raise ArgumentError.new("Event must be one of #{EVENTS.join(', ')}") unless EVENTS.include?(event)
				@data[:event] = event
			end

		end
	end

	# TODO: Reboot

end
