#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/streamingparser'

class StreamingParserTester < NQXMLTester

    # Tokenizes @rsrc.xml and compares the entities returned with a list
    # of expected values.
    def test_parser
	# Build expected entities
	expectedEntities = [
	    @rsrc.xmlDecl, @rsrc.newlineTok,
	    @rsrc.piWithArgs, @rsrc.newlineTok,
	    @rsrc.piNoArgs, @rsrc.newlineTok,
	    @rsrc.doctype, @rsrc.entityTag, @rsrc.element, @rsrc.attlist,
	    @rsrc.notation, @rsrc.newlineTok, @rsrc.comment,
	    @rsrc.newlineTok, @rsrc.outerStart, @rsrc.textDataWithSub,
	    @rsrc.simpleTagStart, @rsrc.simpleTextData, @rsrc.simpleTagEnd,
	    @rsrc.newlineTok, @rsrc.innerTagStart, @rsrc.innerTagEnd,
	    @rsrc.cdata, @rsrc.newlineTok, @rsrc.pTagStart, @rsrc.textText,
	    @rsrc.bTagStart, @rsrc.boldText, @rsrc.bTagEnd,
	    @rsrc.moreTextText, @rsrc.pTagEnd, @rsrc.newlineTok,
	    @rsrc.outerEnd
	]

	parser = NQXML::StreamingParser.new(@rsrc.xml)
	i = 0
	prevTagNameStack = Array.new()
	begin
	    parser.each { | entity |
		resultTok = expectedEntities[i]
		i += 1
		assert_equal(resultTok, entity)
	    }
	    assert(parser.eof?())
	    assert(i == expectedEntities.length,
		   'more expected results than XML data;' +
		   " i == #{i}, results length = #{expectedEntities.length};" +
		   " wanted to see #{expectedEntities[i].class}")
	rescue NQXML::ParserError => ex
	    assert_fail("unexpected parser error on line #{ex.line}: #{$!}")
	end
    end

    # Creates a streaming parser over the XML and sets it to parsing.
    # Expect a parser error that matches `regex'. If line is not nil,
    # expect the error to occur in the specified position(s)
    def expect_error(xml, regex, line = nil, col = nil, pos = nil)
	parser = NQXML::StreamingParser.new(xml)
	begin
	    parser.each { | entity | }
	    assert_fail("expected exception '#{regex.source}'")
	rescue NQXML::ParserError => ex
	    assert_match($!, regex)
	    assert_equal(line, ex.line()) if line
	    assert_equal(col, ex.column()) if col
	    assert_equal(pos, ex.pos()) if pos
	end
    end

    # Prove that end tags must appear after the correspond start tag.
    def test_end_without_start
	expect_error('</end:without:start>',
		     /end tag <\/end:without:start> without opening tag/,
		     1)
    end

    # Make sure tags must be balanced.
    def test_bad_nesting
	expect_error("<line1>\n<bad>\n<nesting></bad>",
		     /end tag <\/bad> does not match last-seen start tag name nesting/,
		     3)
    end

    # Same as tokenizer test. This test is probably not necessary.
    def test_missing_qmark
	expect_error('<?xml version="1.0">', /missing '?'/, 1)
    end

    # Same as tokenizer test. This test is probably not necessary.
    def test_two_slashes
	expect_error('</badTag/>', # on two lines due to rubymode.el
		     /slash appears at both beginning and end/, 1)
    end

    def test_attr_with_amp
	xml = '<variable name="$&amp;">'
	h = {'name' => "\$\&"}
	tag = NQXML::Tag.new('variable', h, false, xml)

	t = NQXML::Tokenizer.new(xml)
	i = 0
	t.each { | e |
	    assert_equal(tag, e)
	    i += 1
	}
	assert_equal(1, i)
	assert(t.eof?)
    end

end
