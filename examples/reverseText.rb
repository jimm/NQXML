#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#
# Using the Tokenizer, this script prints an XML document with all
# text reversed. We achieve this by overriding Text#to_s to return its
# text reversed, then using the Tokenizer to step through the document
# so we can print each entity.
#
# usage:
#
#	reverseText.rb <file.xml>
#

# Start looking for NQXML classes in the directory above this one.
# This forces us to use the local copy of NQXML, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = '..'

require 'nqxml/info'		# For version string
require 'nqxml/tokenizer'

# Modify the Text class for our own nefarious purposes.
module NQXML

    # Override Entity#to_s.
    class Text

	# Return the text string reversed. We replace all '<' with '&lt;'
	# so that the result is still legal in an XML document.
	def to_s
	    return @text.reverse.gsub(/\</, '&lt;')
	end
    end
end

# Fail with usage message if there is no command line argument.
if ARGV.length == 0
    $stderr.puts "usage: #$0 <file.xml>"
    exit(1)
end

# Print the current version of NQXML.
puts "NQXML version #{NQXML::Version}"

tokenizer = nil
begin
    # Create the tokenizer.
    tokenizer = NQXML::Tokenizer.new(File.new(ARGV[0]))

    # Print each entity from the XML input stream. Text entities will
    # print reversed.
    tokenizer.each { | entity |
	print entity.to_s
    }
rescue NQXML::ParserError => ex
    # Handle parser errors by printing the input line number and error
    # message.
    puts "\n  NQXML parser error, line #{ex.line} column #{ex.column}: #{$!}"
end
