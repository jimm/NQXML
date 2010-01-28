#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#
# This script creates an XML file. The Writer interface is similar to
# James Clark's com.jclark.xml.output.XMLWriter Java class.
#

# Start looking for NQXML classes in the directory above this one.
# This forces us to use the local copy of NQXML, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = '..'

require 'nqxml/writer'

# Create a writer and hand it an IO object.
writer = NQXML::Writer.new($stdout)
writer.prettify = true

# Write a processing instruction.
writer.processingInstruction('xml', 'version="1.0"')

# Write an open tag and a close tag. This will produce "<tag/>".
writer.startElement('tag1')
writer.attribute('attr1', 'foo')
writer.endElement('tag1')

# Start writing a tag.
writer.startElement('tag2')

# Add two attributes.
writer.attribute('attr1', 'foo')
writer.attribute('attr2', 'b&r')

# Write text. Automatically closes tag first. All '&', '<', '>', and single-
# and double-quote characters are replaced with their markup equivalents.
# (Note that the newline inserted after the previous tag will be part of
# this text. To avoid this, call "writer.prettify = false" to turn off
# this behavior).
writer.write("  data with <funky & groovy chars>\n")

# Writers check to make sure that tags are nested properly. If there is an
# error, an NQXML::WriterError is raised.
writer.startElement('inner:tag')
writer.endElement('inner:tag')
writer.endElement('tag2')
