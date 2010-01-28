#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#
# This script creates an XML file by creating it manually and passing the
# resulting document object to a writer.
#

# Start looking for NQXML classes in the directory above this one.
# This forces us to use the local copy of NQXML, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = '..'

require 'nqxml/document'
require 'nqxml/writer'

# Create a document object.
doc = NQXML::Document.new()
doc.addToProlog(NQXML::ProcessingInstruction.new('xml', {'version' => '1.0'}))
doc.setRoot(NQXML::Tag.new('root', {'type' => 'manual'}))

# Add two sub-nodes of the root node. We save one node but will find
# the other later.
thing1Node = doc.rootNode.addChild(NQXML::Tag.new('thing', {'id' => '1'}))
doc.rootNode.addChild(NQXML::Tag.new('thing', {'id' => '2'}))

# Add a child to thing1.
thing1Node.addChild(NQXML::Text.new('this is some text'))

# Find thing2 under root.
thing2Node = doc.rootNode.children.detect { | n |
    n.entity.instance_of?(NQXML::Tag) && n.entity.name == 'thing' &&
	n.entity.attrs['id'] == '2'
}

# Debug code:
# This shouldn't happen.
if thing2Node.nil?
    $stderr.puts "oops: couldn't find thing2Node!"
    exit
end
# Neither should this.
if thing2Node == thing1Node
    $stderr.puts "oops: couldn't find thing2Node!"
    exit
end

# Add a child to thing2.
thing2Node.addChild(NQXML::Text.new('thing 2 node text'))

# Create a writer and point it to a string.
str = ''
writer = NQXML::Writer.new(str)
writer.prettify = true		# May also specify in constructor

# Write the document to the string.
writer.writeDocument(doc)

print str

