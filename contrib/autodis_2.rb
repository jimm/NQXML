=begin
From: David Alan Black <dblack@candle.superlink.net>
To: <jimm@io.com>
Subject: a tidier way
Date: Wed, 1 Aug 2001 09:27:49 -0400 (EDT)

Hello again --

Of course the way to do it is to use the Dispatcher itself!

With, ummmm, a slight modification or two.  I have added a "context"
attribute to class Entity, and then set this attribute to the current
context.  This means I can get at the context (for purposes of
outputting callback strings) without having to piece it together
manually, as per the last version.

So, if you want to play, drop in the following changed thing to
dispatcher.rb (local copy, at least as the 'require' in autodis.rb is
worded):

  class Entity
    attr_accessor :context
    def event_key
    end
  end

    def dispatch(entity,context,jump_table)
      entity.context = context
      cdup = context.dup
      jump_table ||= {}
      until jump_table[cdup] || cdup.empty?
	cdup.shift
      end
      if jump_table[cdup]
	jump_table[cdup].call(entity)
      else
	wild = star_match(context,jump_table)
	if wild
	  wild.call(entity)
	end
      end
    end


and run the program below.


David

-----------------------------------------------------------------
=end
# $Id: autodis.rb,v 1.3 2001/08/01 13:18:29 dblack Exp $
# $Author: dblack $
#
# autodis.rb -- tool for generating NQXML::Dispatcher-ready code from XML
#
# See example at end.
#
# For start tags, attributes "action" and "end" are the callbacks
# for starting and ending, respectively.
#
# In text areas, the text itself is the callback.
#
# David Alan Black, August 1, 2001
#

require 'dispatcher'

module NQXML
  class DispatcherTool
    def output(event, context, action)
      return unless /\S/.match action
      print "nd.handle(:#{event}, :"
      print context.join ", :"
      print ") #{action}\n"
    end

    def metahandle(s)
      nd = NQXML::Dispatcher.new(s)

      @ends = {}
      nd.handle(:start_element) {|e|
	c = e.context
	output(e.event_key, c, e.attrs["action"])
	@ends[c] = e.attrs["end"]
      }

      nd.handle(:end_element) {|e|
	c = e.context
	output(e.event_key, c, @ends[c])
      }

      nd.handle(:text) {|e|
	output(e.event_key, e.context, e.text)
      }

      nd.start
    end
  end
end

if __FILE__ == $0
  def test
    NQXML::DispatcherTool.new.metahandle %q{
      <book>
	<chapter>
	  <title action="{|e| puts 'starting title'}"
		 end="{|e| puts 'ending title'}">
	    {|e| puts "Title is #{e.text}"}
	  </title>
	  <p action="{puts 'starting paragraph'}">
	    {|e| puts "paragraph text: #{e.text}"}
	  </p>
	</chapter>
      </book>
  }
  end

  test

end
