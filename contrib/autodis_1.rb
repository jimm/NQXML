=begin
Hi --

Thought you might enjoy this.  It's a bit hackerly at the moment, but
perhaps not far from being very useful.  I'd probably want to find a
way to have it cooperate with, not semi-duplicate, the loop from
Dispatcher#start.  Anyway, see what you think.


David

=end

# $Id: autodis.rb,v 1.2 2001/08/01 12:34:27 dblack Exp $
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
  class Dispatcher

    def output(event, context, action)
      return unless /\S/.match action
      print "nd.handle(:#{event}, :"
      print context.join ", :"
      print ") #{action}\n"
    end

    def metahandle
      puts <<-'EOM'
# Automatically generated NQXML::Dispatcher code.
# Tweak as needed.

require 'nqxml/dispatcher'
nd = NQXML::Dispatcher.new(str)

EOM
      ends = {}
      context = []

      each do |e|
	k = e.event_key
	if k
	  if e.respond_to? :tagStart?
	    if e.tagStart?
	      context.push(e.name)
	      output(e.event_key, context, e.attrs["action"])
	      ends[context] =  e.attrs["end"]
	    end
	  end
	  if e.respond_to? :text
	    output(e.event_key, context, e.text)
	  end
	  if e.respond_to? :tagEnd?
	    if e.tagEnd?
		output(e.event_key, context, ends[context])
	      context.pop
	    end
	  end
	end
      end
    end
  end
end

if __FILE__ == $0

  str = %q{
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

NQXML::Dispatcher.new(str).metahandle
end
