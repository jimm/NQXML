#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'runit/testcase'
require 'runit/cui/testrunner'
require 'singleton'
require 'tempfile'
require 'ftools'

# Start looking for NQXML classes in the directory above this one.
# This forces us to use the local copy of NQXML, even if there is
# a previously installed version out there somewhere.
$LOAD_PATH[0, 0] = '..'

require 'testresource'

class NQXMLTester < RUNIT::TestCase

    @@rsrc = nil

    # This method is called at the beginning of each test.
    def setup
	super
	@@rsrc = TestResource.instance() unless @@rsrc
	@rsrc = @@rsrc
    end

end

if $0 == __FILE__

    class TestAll
	def TestAll.suite
	    suite = RUNIT::TestSuite.new
	    %w(Tokenizer StreamingParser TreeParser Writer Dispatcher).each {
		| klass |
		require "#{klass.downcase}tester"
		suite.add_test(eval("#{klass}Tester.suite"))
	    }
	    suite
	end
    end

    RUNIT::CUI::TestRunner.run(TestAll.suite)
end
