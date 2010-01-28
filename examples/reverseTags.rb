#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#
# Using the tree parser, this script prints an XML document with all
# tags under the root tag in reverse order. We achieve this by adding a
# method to the NQXML::Document class that traverses the node tree
# depth-first but reversed.
#
# usage:
#
#	reverseTags.rb <file.xml>
#

# Start looking for NQXML classes in the directory above this one.
# This forces us to use the local copy of NQXML, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = '..'

require 'nqxml/info'		# For version string
require 'nqxml/treeparser'

# Modify the Text class for our own nefarious purposes.
module NQXML

    class Document

	# This method, called by each_depthfirst_reversed(), calls a proc
	# for the entity in this node and then for all of its children in
	# reverse order. If the node's entity is a tag, call the proc again
	# after temporarily making the entity an end tag.
	def recurse(node, proc)
	    return if node.nil?

	    e = node.entity
	    proc.call(e)
	    node.children.reverse.each { | n | recurse(n, proc) }

	    # If it's a tag, print the tag end.
	    if e.instance_of?(Tag)
		e.makeTagEnd(true)
		proc.call(e)
		e.makeTagEnd(false)
	    end
	end

	# Yield each entity, starting at the root, with all children
	# in reverse order.
	def each_depthfirst_reversed(&block)
	    node = @rootNode
	    recurse(node, block)
	end
    end

    class Tag
	# Allow tags to change their end state.
	def makeTagEnd(bool)
	    @isTagEnd = bool
	end

	# If this tag is an end tag, return the normalized end tag version.
	def to_s
	    return "</#{@name}>" if @isTagEnd
	    return super
	end
    end

    class Text
	# Instead of returning the text with entities substituted,
	# return the original source if we have it.
	def to_s
	    return @source if @source
	    return NQXML.encode(@text)
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

doc = nil
begin
    # Create the tree parser (which reads and parses the XML) and retrieve
    # the document object.
    doc = NQXML::TreeParser.new(File.new(ARGV[0])).document

    # First print the prolog in order.
    doc.prolog.each { | entity |
	print entity.to_s
    }

    # Now print each body tag with its children in reverse order.
    doc.each_depthfirst_reversed { | entity |
	print entity.to_s
    }
    puts
rescue NQXML::ParserError => ex
    # Handle parser errors by printing the input line number and error
    # message.
    puts "\n  NQXML parser error, line #{ex.line} column #{ex.column}: #{$!}"
end
