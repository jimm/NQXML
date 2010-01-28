#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#
# This script creates an XML file by parsing an XML file with a tree parser
# and passing the resulting document object to a writer.
#

# Start looking for NQXML classes in the directory above this one.
# This forces us to use the local copy of NQXML, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = '..'

require 'nqxml/treeparser'
require 'nqxml/writer'

# Open a file, create a tree parser and give it the file, and retrieve
# the parsed document. Gee, this comment is longer than the code.
doc = NQXML::TreeParser.new(File.open('doc.xml')).document

# Create a writer and point it to stdout. We don't have to use the
# newline-inserting "prettify" argument here since the document
# itself contains newlines that will be output by the writer.
writer = NQXML::Writer.new($stdout)
writer.writeDocument(doc)

# The last newline, since it is outside the root entity of the document
# and is purely whitespace, is ignored by the NQXML::TreeParser. Let's
# add a newline to our output.
writer.write("\n")
