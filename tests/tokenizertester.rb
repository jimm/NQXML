#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/tokenizer'

# This class is only used in one test to make sure that Tokenizer can
# handle an argument that is a subclass of String.
class StringSubclass < String
end

# Add a method to the tokenizer
module NQXML
    class Tokenzier
	def testOnlySetInternalEntities(h); @internalEntites = h; end
    end
end


class TokenizerTester < NQXMLTester

    # Tests simple predefined entity replacement
    def test_predefined_entity_replacement
	str = 'x &amp; y = &apos;z&apos;'
	assert_equal("x & y = 'z'", NQXML.replacePredefinedEntityRefs(str))
	assert_equal('x A x', NQXML.replaceCharacterRefs('x &#65; x'))
	assert_equal('x A x', NQXML.replaceCharacterRefs('x &#x41; x'))

	# make sure non-predefined refs are left alone
	assert_equal('x &huh; x',
		     NQXML.replacePredefinedEntityRefs('x &huh; x'))
    end

    # Tests the entity replacement routine.
    def test_entity_replacement
	t = NQXML::Tokenizer.new('')

	# add a method that lets us set the internal entity hash
	class << t
	    def testSetInternalEntities(h); @internalEntities = h; end
	end

	t.testSetInternalEntities({ # as if we saw <!ENTITY...> tags
	    'a' => '&b;',
	    'b' => '&foo;',
	    'foo' => '&bar;',
	    'bar' => 'bletch',
	    'ugly' => 'An ampersand (&#38;) may be escaped' +
			' numerically (&#38;#38;) or with a general' +
			' entity (&amp;amp;).'
	})

	assert_equal('x <&> x', t.replaceAllRefsButParams('x &lt;&amp;&gt; x'))
	assert_equal('x "\' x', t.replaceAllRefsButParams('x &quot;&apos; x'))
	assert_equal('x A x', t.replaceAllRefsButParams('x &#65; x'))
	assert_equal('x A x', t.replaceAllRefsButParams('x &#x41; x'))
	assert_equal('&&', t.replaceAllRefsButParams('&amp;&#38;'))

	assert_equal('&amp', t.replaceAllRefsButParams('&amp'))
	assert_equal('&', t.replaceAllRefsButParams('&amp;'))

	assert_equal('bletch', t.replaceAllRefsButParams('&bar;'))
	assert_equal('bletch', t.replaceAllRefsButParams('&foo;'))
	assert_equal('bletch', t.replaceAllRefsButParams('&b;'))
	assert_equal('bletch', t.replaceAllRefsButParams('&a;'))

	assert_equal('An ampersand (&) may be escaped' +
		     ' numerically (&#38;) or with a general' +
		     ' entity (&amp;).', t.replaceAllRefsButParams('&ugly;'))

	# Make sure unknown entities raise an error
	expect_error('x &huh; x', /entity reference '&huh;' is undefined/)
    end

    # Makes sure special character encoding is working
    def test_encoding
	assert_equal('x &amp; x', NQXML.encode('x & x'))
	assert_equal('x &apos; x', NQXML.encode('x \' x'))
	assert_equal('x &lt;&quot;&gt; x', NQXML.encode('x <"> x'))
    end

    # Make sure names are read correctly.
    def test_name_grabbing
	text = 'name   name2 NameSpace:Name-foo_bar remaining>'
	toker = NQXML::Tokenizer.new(text)
	assert_equal('name', toker.nextName())
	toker.skipSpaces()
	assert_equal('name2', toker.nextName())
	toker.skipSpaces()
	assert_equal('NameSpace:Name-foo_bar', toker.nextName())
	assert_equal(' remaining', toker.textUpTo('>', false, false))
	assert_equal('>', toker.nextChar())
	assert(toker.eof?())
    end

    # Make sure the tokenizer can handle here documents.
    def test_heredoc
	begin
	    toker = NQXML::Tokenizer.new <<EOS
<simple>really</simple>
EOS
	    toker.each { | tok | }
	rescue NQXML::ParserError => ex
	    assert_fail("unexpected parser error on line #{ex.line}: #{$!}")
	end
    end

    # Creates a tokenizer over the xml and sets it to tokenizing. Expect
    # a parser error that matches regex. If line, col, or pos is not nil,
    # expect the error to occur in the specified position(s).
    def expect_error(xml, regex, line = nil, col = nil, pos = nil)
	begin
	    toker = NQXML::Tokenizer.new(xml)
	    toker.each { | tok | }
	    assert_fail("expected exception '#{regex.source}'")
	rescue NQXML::ParserError => ex
	    assert_match($!, regex)
	    assert_equal(line, ex.line()) if line
	    assert_equal(col, ex.column()) if col
	    assert_equal(pos, ex.pos()) if pos
	end
    end

    # Make sure we detect missing '?' at the end of processing instructions.
    def test_missing_qmark
	expect_error('<?xml version="1.0">', /missing '?'/, 1)
    end

    # Disallow two slashes in one tag.
    def test_two_slashes
	expect_error("\n\n\n</x/>", # on two lines due to rubymode.el
		     /slash appears at both beginning and end/, 4)
    end

    # Well-formedness check: the same attribute name may not appear twice
    # in the same tag.
    def test_twin_attrs
	expect_error('<tag attr="foo" attr="bar">',
		     /attribute name '(.*)' appears more than once/)
	expect_error('<?xml version="1.0" version="2.0"?>',
		     /attribute name '(.*)' appears more than once/)
    end

    # Make sure the tokenizer rejects or accepts the proper inputs.
    def test_arguments
	expect_error(42, /illegal argument/)
	expect_error([], /illegal argument/)

	begin
	    # We already tested tempfile arguments elsewhere (see
	    # test_from_tempfile).
	    str = StringSubclass.new('abc') # should be OK
	rescue NQXML::ParserError => ex
	    assert_fail("unexpected parser error on line #{ex.line}: #{$!}")
	end
    end

    # Make sure tokenizer rejects illegal public identifier
    def test_public_id_chars
	expect_error('<!DOCTYPE name PUBLIC "illegal < character" "ok" >',
		     /DOCTYPE PUBLIC public id literal contains illegal character/)
    end

    # Make sure entities are tokenized correctly.
    def test_entities
	sourceWithoutPreproc = '<!DOCTYPE x [
<!ENTITY example "<p>An ampersand (&#38;#38;) may be escaped numerically (&#38;#38;#38;) or with a general entity (&amp;amp;).</p>" >
]>'
	body = "\n<x>&example;</x>"

	toker = NQXML::Tokenizer.new("<?xml version=\"1.0\"?>\n" +
				     sourceWithoutPreproc + body)

	newline = NQXML::Text.new("\n", "\n")
	literal = '<p>An ampersand (&#38;) may be escaped numerically' +
	    ' (&#38;#38;) or with a general entity (&amp;amp;).</p>'
	src = '<!ENTITY example "<p>An ampersand (&#38;#38;) may be escaped' +
	    ' numerically (&#38;#38;#38;) or with a general entity' +
	    ' (&amp;amp;).</p>" >'
	exampleEntity = NQXML::GeneralEntityTag.new('example', literal, nil,
						    nil, src)
	doctype = NQXML::Doctype.new('x', nil, [exampleEntity],
				     sourceWithoutPreproc)

	expected = [
	    NQXML::XMLDecl.new('xml', {'version'=>'1.0'},
			       '<?xml version="1.0"?>'),
	    newline,
	    doctype,
	    newline,
	    NQXML::Tag.new('x', {}, false, '<x>'),
	    NQXML::Tag.new('p', {}, false, '<p>'),
	    NQXML::Text.new('An ampersand (&) may be escaped numerically' +
			    ' (&#38;) or with a general entity (&amp;).',
			    'An ampersand (&#38;) may be escaped numerically' +
			    ' (&#38;38;) or with a general entity' +
			    ' (&amp;amp;).'),
	    NQXML::Tag.new('p', nil, true, '</p>'),
	    NQXML::Tag.new('x', nil, true, '</x>'),
	    newline
	]

	i = 0
	toker.each { | entity |
	    assert_equal(expected[i], entity)
	    if entity.instance_of?(NQXML::Doctype)
		assert_equal(1, entity.entities.length)
		assert_equal(exampleEntity, entity.entities[0])
	    end
	    i += 1
	}
    end

    # Make sure entities are tokenized correctly. The example XML is taken
    # almost verbatim from the XML specification.
    def test_param_entities
	toker = NQXML::Tokenizer.new('<?xml version="1.0"?>
<!DOCTYPE test [
<!ENTITY % xx \'&#37;zz;\'>
<!ENTITY % zz \'&#60;!ENTITY tricky "error-prone" >\' >
<!ENTITY % yy \'%zz;\' >
%xx;
]>
<test>This sample shows a &tricky; method.</test>'
	)

	newline = NQXML::Text.new("\n", "\n")
	xx = NQXML::ParameterEntityTag.new('xx', '%zz;', nil,
					   '<!ENTITY % xx \'&#37;zz;\'>')
	zzSrc = '<!ENTITY % zz \'&#60;!ENTITY tricky "error-prone" >\' >'
	zz = NQXML::ParameterEntityTag.new('zz',
					   '<!ENTITY tricky "error-prone" >',
					   nil, zzSrc)
	yySrc = '<!ENTITY % yy \'%zz;\' >'
	yy = NQXML::ParameterEntityTag.new('yy',
					   '<!ENTITY tricky "error-prone" >',
					   nil, yySrc)

	tricky = NQXML::GeneralEntityTag.new('tricky', 'error-prone', nil, nil,
					     '<!ENTITY tricky "error-prone" >')
	
	doctype = NQXML::Doctype.new('test', nil,
				     [xx, zz, yy, tricky],
'<!DOCTYPE test [
<!ENTITY % xx \'&#37;zz;\'>
<!ENTITY % zz \'&#60;!ENTITY tricky "error-prone" >\' >
<!ENTITY % yy \'%zz;\' >
%xx;
]>'
				     )
	expected = [
	    NQXML::XMLDecl.new('xml', {'version'=>'1.0'},
			       '<?xml version="1.0"?>'),
	    newline,
	    doctype,
	    newline,
	    NQXML::Tag.new('test', {}, false, '<test>'),
	    NQXML::Text.new('This sample shows a error-prone method.'),
	    NQXML::Tag.new('test', nil, true, '</test>')
	]

	i = 0
	toker.each { | entity |
	    assert_equal(expected[i], entity)
	    if entity.instance_of?(NQXML::Doctype)
		assert_equal(4, entity.entities.length)
		assert_equal(xx, entity.entities[0])
		assert_equal(zz, entity.entities[1])
		assert_equal(yy, entity.entities[2])
		assert_equal(tricky, entity.entities[3])
	    end
	    i += 1
	}
    end

    # Passes a Tempfile to a Tokenizer. Fails if any parser error is
    # raised.
    def test_from_tempfile
	io = Tempfile.open('nqxml')
	io.write(@rsrc.xml)
	io.close()
	io.open()		# Re-open tempfile for reading

	toker = NQXML::Tokenizer.new(io)
	begin
	    # Don't do anything, just let tokenizer run through the XML
	    toker.each { | entity | }
	rescue NQXML::ParserError => ex
	    assert_fail("Tokenizer parser error thrown on line #{ex.line} : #{$!}")
	ensure
	    io.close()
	end
    end

    def compare_tokens_with_expected(xml)
	# Build expected entities
	expectedEntities = [
	    @rsrc.xmlDecl, @rsrc.newlineTok,
	    @rsrc.piWithArgs, @rsrc.newlineTok,
	    @rsrc.piNoArgs, @rsrc.newlineTok,
	    @rsrc.doctype, @rsrc.newlineTok, @rsrc.comment,
	    @rsrc.newlineTok, @rsrc.outerStart, @rsrc.textDataWithSub,
	    @rsrc.simpleTagStart, @rsrc.simpleTextData, @rsrc.simpleTagEnd,
	    @rsrc.newlineTok, @rsrc.innerTagStart, @rsrc.innerTagEnd,
	    @rsrc.cdata, @rsrc.newlineTok, @rsrc.pTagStart, @rsrc.textText,
	    @rsrc.bTagStart, @rsrc.boldText, @rsrc.bTagEnd,
	    @rsrc.moreTextText, @rsrc.pTagEnd, @rsrc.newlineTok,
	    @rsrc.outerEnd
	]

	toker = NQXML::Tokenizer.new(xml)
	i = 0
	toker.each { | tok |
	    assert_equal(expectedEntities[i], tok)
	    i += 1
	}
	assert(toker.eof?())
	assert(i == expectedEntities.length,
	       'more expected results than XML data')
    end

    # Tokenizes @rsrc.xml and compares the entities returned with a list
    # of expected values.
    def test_tokens
	compare_tokens_with_expected(@rsrc.xml)
    end

    def test_different_newlines
	compare_tokens_with_expected(@rsrc.xml.gsub("\n", "\r\n"))
	compare_tokens_with_expected(@rsrc.xml.gsub("\n", "\r"))
    end

    # This XML fragment made the tokenizer barf because the &lt; was being
    # translated and then seen as a tag open character.
    def test_lt
	xml = '<p/>&lt;= 4'
	expectedEntities = [
	    NQXML::Tag.new('p', {}, false, '<p/>'),
	    NQXML::Tag.new('p', nil, true, '<p/>'),
	    NQXML::Text.new('<= 4')
	]

	t = NQXML::Tokenizer.new(xml)
	i = 0
	t.each { | e |
	    assert_equal(expectedEntities[i], e)
	    i += 1
	}
	assert_equal(expectedEntities.length, i)
	assert(t.eof?)
    end

    def test_attr_val_lt_predefined
	xml = '<variable name="$&lt;" type="Object">'

	h = {'name' => "\$\<", 'type' => 'Object'}
	tag = NQXML::Tag.new('variable', h, false,
			     '<variable name="$&lt;" type="Object">')

	t = NQXML::Tokenizer.new(xml)
	i = 0
	t.each { | e |
	    assert_equal(tag, e)
	    i += 1
	}
	assert_equal(1, i)
	assert(t.eof?)
    end

    def test_attr_val_lt_char
	expect_error('<variable name="$<" type="Object">',
		     /attribute values may not contain '<'/)
    end

    def test_comment_with_newline_bug
	xml = "<!-- comment\n-->"
	comment = NQXML::Comment.new(xml)

	t = NQXML::Tokenizer.new(xml)
	i = 0
	t.each { | e |
	    assert_equal(comment, e)
	    i += 1
	}
	assert_equal(1, i)
	assert(t.eof?)
    end

end
