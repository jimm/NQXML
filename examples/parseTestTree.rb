#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#
# usage: parseTestTree.rb file_or_directory
#
# This script runs the streaming parser over the specified file, or all
# .xml files within the specified directory.
#
# If an NQXML::ParserError is seen, an error message is printed and parsing
# continues with the next file.
#

# Start looking for NQXML classes in the directory above this one.
# This forces us to use the local copy of NQXML, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = '..'

require 'nqxml/treeparser'

DIR = ARGV[0] ? ARGV[0].gsub(/\/$/, '') : '.'

def testParser(file)
    print "Parsing file #{file}..."
    $stdout.flush()
    begin
	# The document is parsed when the tree parser's `initialize' method
	# is called at construction time. To do anything with the results,
	# you would use the parser's :document attribute.
	parser = NQXML::TreeParser.new(File.open(file, 'r'))
    rescue NQXML::ParserError => ex
  	puts "\n  NQXML parser error, line #{ex.line} column #{ex.column}:" +
	    " #{$!}"
	return
    rescue
	puts "\n  Non-parser error: #{$!}"
	return
    end
    puts 'OK'
end

if File.directory?(DIR)
    Dir.entries(DIR).each { | f |
	testParser("#{DIR}/#{f}") if f =~ /\.xml$/
    }
else
    testParser(DIR)
end
