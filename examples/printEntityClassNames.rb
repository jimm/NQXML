#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#
# This script is a complete version of the example given in the README
# file. It overrides NQXML::Entity.to_s to print the entity's class
# name and uses an NQXML::StreamingParser to print the class name of
# each entity seen.
#
# If an NQXML::ParserError is seen, the error message is printed and
# parsing is halted.
#

# Start looking for NQXML classes in the directory above this one.
# This forces us to use the local copy of NQXML, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = '..'

require 'nqxml/streamingparser'

# Override the `to_s()' method of all Entity classes that
# have one.
module NQXML
    class Entity; def to_s; return "I'm an #{self.class}."; end; end
    class Text; def to_s; return "I'm an #{self.class}."; end; end
end

# Here's where the fun begins.
begin
    # Create a parser.
    puts "PARSING FILE #{ARGV[0]}"
    parser = NQXML::StreamingParser.new(File.open(ARGV[0], 'r'))
    # Start parsing and returning entities.
    parser.each { | entity | puts entity.to_s }
rescue NQXML::ParserError => ex
    puts "parser error on line #{ex.line()}, col #{ex.column()}: #{$!}"
end
