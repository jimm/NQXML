#! /usr/bin/env ruby
#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#
# I was going to use NQXML to parse README.sgml, but I can't because SGML
# is not XML. For example, the DOCTYPE tag's PUBLIC identifier takes one
# argument in SGML but two arguments in XML, and the Docbook <xref> tag
# has no end tag. Therefore, README.sgml is not a legal XML document.
#

FILL_COLUMN = 75
SCREEN_PREFIX = "\t    "
PROGRAM_PREFIX = "\t"

titleCounters = Array.new(6, 0)
exampleXrefs = Hash.new()
exampleCounter = 0

def fillParagraph(prefix, txt)
    para = Array.new()
    txt = txt.gsub(/\s+/m, ' ') # turn whitespace into single spaces and dup
    fillColumn = FILL_COLUMN - prefix.length
    regex = /^(.{0,#{fillColumn}})[ \n]/m

    while txt.length > fillColumn
	if txt =~ regex
	    para << $1
	    txt = $'
	else
	    para << txt
	    txt = ''
	end
    end
    para << txt unless txt.empty?

    return "\n" + prefix + para.join("\n" + prefix.gsub(/\S/, ' ')) + "\n"
end

# Slurp the whole file into `text'.
text = File.open(ARGV[0], 'r').read()

# Read ENTITY substitutions and replace them in the text. Must do this
# before we delete the entire DOCTYPE tag below.
text.scan(/<!ENTITY\s+(\w+)\s+"([^"]*)">/) { | name, value |
    value.gsub!(/<.*?>/, '')
    text.gsub!(/&#{name};/, value)
}

# Erase entire sections of the document.
text.gsub!(/\<artheader>.*<\/artheader>/m, '')
text.gsub!(/<!--(.*?)-->/m, '')
text.gsub!(/<!DOCTYPE.*?]>/m, '')

# Special entity substitutions.
text.gsub!(/&lt;/, '<')
text.gsub!(/&gt;/, '>')
text.gsub!(/&quot;/, '"')
text.gsub!(/&apos;/, '\'')
text.gsub!(/&copy;/, '(c)')
text.gsub!(/&amp;/, '&')

# Replace ordered list listitems with numbers
text.gsub!(/<orderedlist>(.*?)<\/orderedlist>/m) {
    items = $1
    i = 0
    items.gsub!(/<listitem>\s*<para>/m) { i += 1; "    <para>#{i}. " }
    items
}

# Miscellaneous tag replacement.
# FIX: replace <listitem> with number inside <orderedlist>.
text.gsub!(/<listitem>/, '    * ')
text.gsub!(/<replaceable>(.*?)<\/replaceable>/, '<\1>')
text.gsub!(/<email>(.*?)<\/email>/, '<\1>')
text.gsub!(/<firstterm>(.*?)<\/firstterm>/, '``\1\'\'')

# Example headings. Do this before generating cross-references.
text.gsub!(/<example(.*?)<title>(.*?)<\/title>/m) { |t|
    id, title = $1, $2
    exampleCounter += 1
    if id =~ /id\s*=\s*"(.*)"/
	exampleXrefs[$1] = exampleCounter
    end
    "Example #{exampleCounter}. #{title}"
}

# Cross-references.
text.gsub!(/<xref\s+linkend\s*=\s*"([^"]+)">/m) { |t|
    if exampleXrefs[$1]
	"Example #{exampleXrefs[$1]}" 
    else
	"``#{$1}''"
    end
}

# URLs.
text.gsub!(/<ulink\s+url="([^"]*)">(.*?)<\/ulink>/m, '\2 (\1)')

# Program and screen listings: put whitespace at the beginning of each line.
text.gsub!(/<(screen|programlisting)>(.*?)<\/\1>/m) { |t|
    t.gsub(/\n/m, "\n" + ($1 == 'screen' ? SCREEN_PREFIX : PROGRAM_PREFIX))
}

# Citetitle. Put it in quotes.
text.gsub!(/<citetitle.*?>(.*?)<\/citetitle>/m, '"\1"')

# Delete start and end tags of a bunch of tags.
tags = %w(article classname filename(\s+class="directory")? function
    itemizedlist application acronym literal screen programlisting token
    markup option command)
text.gsub!(/<\/?(#{tags.join('|')})>/, '')

# Delete only the ends of these tags.
text.gsub!(/<\/(listitem|sect\d+|example)>/, '')

# Warnings.
text.gsub!(/\s*<warning>\s*/, "\n\n======== WARNING ========\n\n    ")
text.gsub!(/\s*<\/warning>\s*/, "\n\n======== WARNING ========\n\n")

# Section headings
text.gsub!(/<sect(\d).*?<title>(.*?)<\/title>/m) { |t|
    sect, title = $1.to_i, $2
    case sect
    when 1
	titleCounters[1] += 1
	titleCounters[2] = titleCounters[3] = titleCounters[4] = 0
	title = "#{titleCounters[1]}. #{title.upcase()}"
	title += "\n" + ('=' * title.length)
    when 2
	titleCounters[2] += 1
	titleCounters[3] = 0
	title = "#{titleCounters[1]}.#{titleCounters[2]}. #{title}"
	title += "\n" + ('-' * title.length)
    when 3
	titleCounters[3] += 1
	titleCounters[4] = 0
	title = "#{titleCounters[1]}.#{titleCounters[2]}.#{titleCounters[3]}."+
	    " #{title}"
    when 4
	titleCounters[4] += 1
	title = "#{titleCounters[1]}.#{titleCounters[2]}.#{titleCounters[3]}."+
	    "#{titleCounters[4]}. #{title}"
    end
    title + "\n"
}

# Wrap paragraphs.
text.gsub!(/\n([^\n]*?)<para>\s*(.*?)\s*<\/para>/m) { | txt |
    fillParagraph($1, $2)
}

text.gsub!(/^\s+$/, '')		# get rid of spaces in spaces-only lines
text.gsub!(/\n\n+/m, "\n\n")	# multiple newlines

print text
