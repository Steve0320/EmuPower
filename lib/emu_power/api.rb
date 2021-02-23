# API for communicating with the Rainforest EMU-2 monitoring
# unit. This API is asynchronous, and allows event handlers
# to be registered for the various message types.

require 'emu_power/stream_parser'
require 'emu_power/types'

require 'serialport'
require 'nokogiri'

class EmuPower::Api

	LINE_TERMINATOR = "\r\n"

	# Initialize the serial connection and build notification histories
	def initialize(tty, history_length = 10)

		@port = SerialPort.new(tty, baud: 115200)

		@histories = {}
		@callbacks = {}
		EmuPower::Types::Notification.subclasses.each do |n|
			@histories[n] = Array.new(history_length)
			@callbacks[n] = nil
		end

	end

	# Register the callback for specific notification events. Expects
	# a subclass of Types::Notification. If :global is passed for klass,
	# the callback will be triggered for every event in addition to the
	# normal callback. Note that only one callback may be registered
	# per event - setting another will replace the existing one.
	def callback(klass, &block)
		@callbacks[klass] = block
		return true
	end

	# Send a command to the device. Expects an instance of one of the
	# command classes defined in commands.rb. The serial connection
	# must be started before this can be used.
	def issue_command(obj)
		return false if @thread.nil?
		return false unless obj.respond_to?(:to_command)
		xml = obj.to_command
		@port.write(xml)
		return true
	end

	# Begin polling for serial data. We spawn a new thread to
	# handle this so we don't block input. If blocking is set
	# to true, this method blocks indefinitely. If false, it
	# returns true and expects the caller to handle things.
	def start_serial(interval: 1, blocking: true)

		return false unless @thread.nil?

		parser = construct_parser

		@thread = Thread.new do
			loop do
				begin
					parser.parse
					sleep(interval)
				rescue Nokogiri::XML::SyntaxError
					# This means that we probably connected in the middle
					# of a message, so just reset the parser.
					parser = construct_parser
				end
			end
		end

		if blocking
			@thread.join
		else
			return true
		end

	end

	# Stop polling for data. Already-received objects will
	# remain available.
	def stop_serial
		return false if @thread.nil?
		@thread.terminate
		@thread = nil
		return true
	end

	# Get the full history buffer for a given notify type
	def history_for(klass)
		return @histories[klass].compact
	end

	# Get the most recent object for the given type
	def current(klass)
		return history_for(klass)[0]
	end

	private

	# Handle the completed hash objects when notified by the parser
	def handle_response(obj)

		container = EmuPower::Types.construct(obj)

		if container == nil
			puts "BAD OBJECT #{obj}"
		else
			push_history(container)
			@callbacks[container.class]&.call(container)
			@callbacks[:global]&.call(container)
		end

	end

	# Helper for initializing underlying parser
	def construct_parser
		return EmuPower::StreamParser.new(@port, LINE_TERMINATOR, EmuPower::Types.notify_roots) do |obj|
			handle_response(obj)
		end
	end

	# Helper for inserting object into appropriate history queue
	def push_history(obj)
		
		type = obj.class

		old = @histories[type].pop
		@histories[type].prepend(obj)
		return old

	end

end
