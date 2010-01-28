#! /usr/bin/env ruby
#
# Dump an XML file as text, using the streaming parser. This script uses
# one of the nice features of Ruby: it adds methods to the pre-existing
# Entity classes to add additional behavior.
#
# usage:
#
#	dumpXML <file.xml>
#

# Start looking for NQXML classes in the directory above this one.
# This forces us to use the local copy of NQXML, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = '..'

require 'nqxml/info'		# For version string
require 'nqxml/streamingparser'

# Number of spaces to indent for each start tag
SPACES_PER_INDENT = 2

# Returns indentation string of `level' spaces (using tabs and spaces).
def indentationString(level)
    return ("\t" * (level >> 3)) + (' ' * (level & 7))
end

# Modify the entity classes for our own nefarious purposes.
# This is why I love Ruby.
module NQXML

    # We add methods that let us modify the indentation level.
    # There is already an Entity#to_s method that prints the original
    # XML source code. We will override that method in the following
    # subclasses of Entity.
    class Entity

	# Return the indentation level to use before printing this tag.
	def preModifyIndent(currentLevel)
	    return currentLevel
	end

	# Return the indentation level to use after printing this tag.
	def postModifyIndent(currentLevel)
	    return currentLevel
	end
    end

    # Tags modify the indentation level
    class Tag

	# Before an end tag, decrease the indentation level.
	def preModifyIndent(currentLevel)
	    return currentLevel - SPACES_PER_INDENT if @isTagEnd
	    return currentLevel
	end

	# After a start tag, increase the indentation level.
	def postModifyIndent(currentLevel)
	    return currentLevel + SPACES_PER_INDENT if !@isTagEnd
	    return currentLevel
	end

	# Return a print string for this tag.
	def to_s
	    return "#{@name} end" if @isTagEnd
	    str = "#{@name}: "
	    @attrs.each { | k, v | str += "#{k}=\"#{v}\"" }
	    return str
	end
    end

    # Override Entity#to_s.
    class ProcessingInstruction

	# Return a print string.
	def to_s
	    str = "#{@name}: "
	    @attrs.each { | k, v | str += "#{k}=\"#{v}\"" }
	    return str
	end
    end

    # Override Entity#to_s.
    class Comment

	# Return a new print string.
	def to_s
	    return "comment: #{text()}"
	end
    end

    # Override Entity#to_s.
    class Text

	# Return the text string, or nil if the text is empty or is all
	# whitespace.
	def to_s
#	    return nil if @text == "\n" || @text =~ /\n\s+/m
	    return "text: \"#{@text}\""
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

parser = nil
indentLevel = 0
begin
    # Create the parser.
    parser = NQXML::StreamingParser.new(File.new(ARGV[0]))

    # Start parsing and returning individual Entities.
    parser.each { | entity |

	# Let the entity modify the indent level.
	indentLevel = entity.preModifyIndent(indentLevel)

	# Get the entity's print string.
	str = entity.to_s

	# Print the string, unless it is nil. Text#to_s will return nil
	# if it's text is empty or all whitespace.
	puts indentationString(indentLevel) + str if str

	# Let the entity modify the indent level.
	indentLevel = entity.postModifyIndent(indentLevel)
    }
rescue NQXML::ParserError => ex
    # Handle parser errors by printing the input line number and error
    # message.
    puts "parser error, line #{ex.line} column #{ex.column}: #{$!}"
end
