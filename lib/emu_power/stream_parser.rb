# SAX parser implementation for processing a stream of
# XML fragments.

require 'nokogiri'

class EmuPower::StreamParser < Nokogiri::XML::SAX::Document

	FAKEROOT = 'FAKEROOT'

	def initialize(io, line_terminator, roots, &block)

		@line_terminator = line_terminator
		@io = io

		# Use a push parser so we can fake a single root element
		@parser = Nokogiri::XML::SAX::PushParser.new(Parser.new(FAKEROOT, roots, &block))

		# This is the "root" of the document. We intentionally never close this
		# so that the parser doesn't get mad when it encounters multiple real
		# root elements.
		@parser << "<#{FAKEROOT}>"

	end

	# Push all new lines from the io into the parser. The parser
	# will fire the callback given on construction once a whole
	# object has been processed.
	def parse
		lines = @io.readlines(@line_terminator)
		lines.each { |l| @parser << l }
	end

	# Nokogiri parser definition. Processes a flat XML
	# stream with multiple roots.
	class Parser < Nokogiri::XML::SAX::Document

		# Initialize the set of root tags to consider
		def initialize(fakeroot, roots, &block)

			@roots = roots

			@current_object = nil
			@current_property = nil
			@current_root = nil

			@callback = block

			# All element parsers ignore this tag. This is only
			# used to persuade Nokogiri to parse multiple roots
			# in a single stream without getting mad.
			@fakeroot = fakeroot

		end

		# For each tag, initialize a root element if we don't already have
		# one. Otherwise, consider it a property of the current element.
		def start_element(name, attrs = [])

			return if name == @fakeroot
			return if @current_object == nil && !@roots.include?(name)

			if @current_object == nil
				@current_root = name
				@current_object = { "MessageType" => name }
			else
				@current_property = name
			end

		end

		# Populate the content of the current element
		def characters(str)
			if @current_object != nil && @current_property != nil

				#cur = @current_object[@current_property]
				#return if cur == str

				# Wrap into array if we already have a value (XML permits duplicates)
				#cur = [cur] unless cur == nil
				
				#if cur.kind_of?(Array)
				#	cur << str
				#else
				#	cur = str
				#end

				#@current_object[@current_property] = cur

				@current_object[@current_property] = str

			end
		end

		# Close out the current tag and clear context
		def end_element(name, attrs = [])

			return if name == @fakeroot
			
			if @current_root == name

				if @callback != nil
					@callback.call(@current_object)
				else
					puts "DEBUG: #{@current_object}"
				end
				
				@current_object = nil
				@current_root = nil

			elsif @current_object != nil
				@current_property = nil
			end

		end

	end

end
