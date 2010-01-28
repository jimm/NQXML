#!/usr/bin/env ruby
#
# The original version of this script was by TAKAHASHI Masayoshi
# <maki@inac.co.jp> and can be found at
# http://www.jin.gr.jp/~nahi/RWiki/?cmd=view;name=xmlconftest
#

base = File.dirname($0)
# Ensure loading this version of NQXML, not a previously installed version.
$LOAD_PATH[0,0] = File.join(base, '..')

require 'getoptlong'
require 'nqxml/streamingparser'

# Specific to my system. Change to your liking.
XMLCONFDIR = File.join(base, '..', '..', 'xmlconf/')

$verbose = false

class XMLConf
    def initialize(); @result = Hash.new(); end
    attr_reader :result
    def clear();      @result.clear;        end
    def check(file)
	check = true
	File.open(file){|f|
	    str = f.read
	    begin
		parse(str)
	    rescue NQXML::ParserError => ex
		if $verbose
		    puts "#{file}:#{ex.line}:#{$!}"
		    puts $@.join("\n")
		end
		check = false
	    rescue Exception
		if $verbose
		    puts "#{file}:1:#{$!}"
#  		    puts $!,"(#{file})"
		    puts $@.join("\n")
		end
		check = false
	    end
	}
	@result[file] = check
    end

    def parse(str); NQXML::StreamingParser.new(str).each{|e| e}; end
end

### main

g = GetoptLong.new(['--verbose', '-v', GetoptLong::NO_ARGUMENT])
g.each { | name, opt |
    case name
    when '--verbose'
	$verbose = true
    end
}

wf_files = Dir.glob(XMLCONFDIR+"*/valid/*/*.xml")
wf_files.concat(Dir.glob(XMLCONFDIR+"oasis/p*pass*.xml"))

def success_num(result)
    result.find_all{|key,value| value == true}.length
end

def fail_num(result)
    result.find_all{|key,value| value == false}.length
end

nqxmlconf = XMLConf.new()
wf_files.each{ |file|
    nqxmlconf.check(file)
}

## end

total = nqxmlconf.result.length
result_list = [
    ["NQXML", nqxmlconf.result],
]

result_list.each{ |name, result|
    puts "*** #{name} ***"
    printf("total   ...%3d\n",total)
    printf("success ...%3d (%2.1f%%)\n",
	   success_num(result),
	   Float(success_num(result)*100)/total)
    printf("failure ...%3d (%2.1f%%)\n",
	   fail_num(result),
	   Float(fail_num(result)*100)/total)
}
