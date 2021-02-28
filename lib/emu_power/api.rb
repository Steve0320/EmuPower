# API for communicating with the Rainforest EMU-2 monitoring
# unit. This API is asynchronous, and allows event handlers
# to be registered for the various message types.

require_relative 'notifications'
require 'serialport'

class EmuPower::Api

	LINE_TERMINATOR = "\r\n"

	attr_accessor :debug_mode

	# Initialize the serial connection and set up internal structures.
	def initialize(tty, debug: false)

		@port = SerialPort.new(tty, 115200, 8, 1, SerialPort::NONE)

		# Get rid of any existing buffered data - we only want to operate on
		# fresh notifications.
		@port.flush_input
		@port.flush_output

		@debug_mode = debug

		reset_callbacks!

	end

	# Register the callback for specific notification events. Expects either an
	# EmuPower::Notifications::Notification subclass, or :global, or :fallback. If :global
	# is passed, the callback will be fired on every notification. If :fallback is
	# passed, the callback will be fired for every notification that does not have
	# a specific callback registered already.
	def callback(klass, &block)

		if klass == :global || klass == 'global'
			@global_callback = block
		elsif klass == :fallback || klass == 'fallback'
			@fallback_callback = block
		elsif EmuPower::Notifications::Notification.subclasses.include?(klass)
			@callbacks[klass] = block
		else
			klass_list = EmuPower::Notifications::Notification.subclasses.map(&:name).join(', ')
			raise ArgumentError.new("Class must be :global, :fallback, or one of #{klass_list}")
		end

		return true

	end

	# Reset all callbacks to the default no-op state.
	def reset_callbacks!
		@global_callback = nil
		@fallback_callback = nil
		@callbacks = {}
	end

	# Send a command to the device. Expects an instance of one of the
	# command classes defined in commands.rb. The serial connection
	# must be started before this can be used.
	def issue_command(obj)

		return false if @thread.nil? || !obj.respond_to?(:to_command)

		xml = obj.to_command
		@port.write(xml)

		return true

	end

	# Begin polling for serial data. We spawn a new thread to handle this so we don't
	# block input. This method blocks until the reader thread terminates, which in most
	# cases is never. This should usually be called at the end of a program after all
	# callbacks are registered.
	def start_serial

		return false unless @thread.nil?

		@thread = Thread.new do

			# Define boundary tags
			root_elements = EmuPower::Notifications.notify_roots
			start_tags = root_elements.map { |v| "<#{v}>" }
			stop_tags = root_elements.map { |v| "</#{v}>" }

			current_notify = ''

			# Build up complete XML fragments line-by-line and dispatch callbacks
			loop do

			  line = @port.readline(LINE_TERMINATOR).strip

				if start_tags.include?(line)
					current_notify = line

				elsif stop_tags.include?(line)

					xml = current_notify + line
					current_notify = ''

					begin
						obj = EmuPower::Notifications.construct(xml)
					rescue StandardError
						puts "Failed to construct object for XML fragment: #{xml}" if @debug_mode
						next
					end

					if obj
						puts obj if @debug_mode
						perform_callbacks(obj)
					else
						puts "Incomplete XML stream: #{xml}" if @debug_mode
					end

				else
					current_notify += line
				end

			end
		end

		# Block until thread is terminated, and ensure we clean up after ourselves.
		begin
			@thread.join
		ensure
			stop_serial if @thread
		end

	end

	# Terminate the reader thread. The start_serial method will return
	# once this is called. This will usually be called from a signal
	# trap or similar, since the main program will usually be blocked
	# by start_serial.
	def stop_serial

		return false if @thread.nil?

		@thread.terminate
		@thread = nil

		return true

	end

	private

	# Dispatch the appropriate callback
	def perform_callbacks(obj)

		klass = obj.class

		# Fire global callback
		@global_callback&.call(obj)

		klass_specific = @callbacks[klass]
		if klass_specific
			klass_specific.call(obj)
		else
			@fallback_callback&.call(obj)
		end

	end

end
