#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

=begin

= Introduction

This script installs NQXML into the Ruby site-local library directory.

= Usage

    install.rb

=end

require 'getoptlong'
require 'ftools'
require 'find'

SOURCE_DIR = 'nqxml'
LIBDIR = 'nqxml'

def instdir
    g = GetoptLong.new(['--install-dir', '-i', GetoptLong::REQUIRED_ARGUMENT])
    g.each { | name, arg |
	if name == '--install-dir'
	    return arg
	else
	    $stderr.puts "usage: $0 [--install-dir dir]"
	end
    }

    begin
	require 'rbconfig'
	libdir = Config::CONFIG['sitedir'] + "/" + 
	    Config::CONFIG['MAJOR'] + "." +
	    Config::CONFIG['MINOR']
    rescue ScriptError
	$LOAD_PATH.each do |l|
	    if l =~ /site_ruby/ && l =~ /\d$/ && l !~ /#{PLATFORM}/
		libdir = l
		break
	    end
	end
	STDERR.puts "Can't find required file `rbconfig.rb'."
	STDERR.puts "The `nqxml' files need to be installed manually in" +
	    " #{libdir}"
    end
    return libdir
end

INSTALL_DIR = instdir()
File.makedirs(File.join(INSTALL_DIR, LIBDIR))
Find.find(SOURCE_DIR) { |f|
    File.install(f, File.join(INSTALL_DIR, f), 0644, true) if f =~ /.rb$/
}
