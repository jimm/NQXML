#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'singleton'

# This class holds resources that are read-only, and therefore only
# need to be created once.
class TestResource
    include Singleton

    attr_reader :xml, :newlineTok, :xmlDecl, :piWithArgs, :piNoArgs,
	:entityTag, :element, :attlist, :notation, :doctype, :comment,
	:outerStart, :textDataWithSub, :simpleTagStart, :simpleTextData,
	:simpleTagEnd, :innerTagStart, :innerTagEnd, :pTagStart, :pTagEnd,
	:bTagStart, :bTagEnd, :textText, :boldText, :moreTextText, :cdata,
	:outerEnd
    attr_reader :tricky_substitution_xml

    # Each test that uses this data expects the data to be returned from a
    # tokenizer or parser differently, or in a slightly different order.
    # Therefore we can't set up one single array containing the expected
    # result objects in order.
    def initialize
	@xml = '<?xml version="1.0"?>
<?misc:processingInstruction "with arguments"?>
<?other:piNoArgs ?>
<!DOCTYPE outer PUBLIC "public id" "foobar" [
  <!ENTITY foo "bletch">
  <!ELEMENT el>
  <!ATTLIST el EMPTY>
  <!NOTATION notation ignored>
]>
<!-- comment -->
<outer>
  data&amp;&foo;
more on next line<simpleTag>text</simpleTag>
<inner:tag a="tabs	to	spaces&foo;"/><![CDATA[xx<z&xx</
newline in cdata
]]>
<p>text <b>bold café coffee</b> more text</p>
</outer>'

	emptyAttrs = Hash.new()
	@newlineTok = NQXML::Text.new("\n")

	attrs = Hash.new()
	attrs['version'] = '1.0'
	@xmlDecl = NQXML::XMLDecl.new('xml', attrs, '<?xml version="1.0"?>')

	src = '<?misc:processingInstruction "with arguments"?>'
	@piWithArgs =
	    NQXML::ProcessingInstruction.new('misc:processingInstruction',
					     '"with arguments"', src)

	@piNoArgs = NQXML::ProcessingInstruction.new('other:piNoArgs', '',
						     '<?other:piNoArgs ?>')

	@entityTag =
	    NQXML::GeneralEntityTag.new('foo', 'bletch', nil, nil,
					'<!ENTITY foo "bletch">')
	@element = NQXML::Element.new('el', '', '<!ELEMENT el>')
	@attlist = NQXML::Attlist.new('el', 'EMPTY', '<!ATTLIST el EMPTY>')
	@notation = NQXML::Notation.new('notation', 'ignored',
					'<!NOTATION notation ignored>')
	@doctypePubid =
	    NQXML::PublicExternalID.new('"public id"', '"foobar"',
					'PUBLIC "public id" "foobar"')
	@doctype =
	    NQXML::Doctype.new('outer', @doctypePubid,
			       [@entityTag, @element, @attlist, @notation],
			       "<!DOCTYPE outer PUBLIC \"public id\" \"foobar\" [\n" +
			       "  <!ENTITY foo \"bletch\">\n" +
			       "  <!ELEMENT el>\n" +
			       "  <!ATTLIST el EMPTY>\n" +
			       "  <!NOTATION notation ignored>\n" +
			       "]>")

	@comment = NQXML::Comment.new('<!-- comment -->')
	@outerStart = NQXML::Tag.new('outer', emptyAttrs, false, '<outer>')
	@textDataWithSub = NQXML::Text.new("\n  data&bletch\nmore on next line")
	@simpleTagStart = NQXML::Tag.new('simpleTag', emptyAttrs, false,
					 '<simpleTag>')
	@simpleTextData = NQXML::Text.new('text')
	@simpleTagEnd = NQXML::Tag.new('simpleTag', nil, true, '</simpleTag>')

	attrs = Hash.new()
	attrs['a'] = 'tabs to spacesbletch'
	@innerTagStart = NQXML::Tag.new('inner:tag', attrs, false,
					'<inner:tag a="tabs	to	spaces&foo;"/>')

	@innerTagEnd = NQXML::Tag.new('inner:tag', nil, true,
					'<inner:tag a="tabs	to	spaces&foo;"/>')
	@pTagStart = NQXML::Tag.new('p', emptyAttrs, false, '<p>')
	@pTagEnd = NQXML::Tag.new('p', nil, true, '</p>')
	@bTagStart = NQXML::Tag.new('b', emptyAttrs, false, '<b>')
	@bTagEnd = NQXML::Tag.new('b', nil, true, '</b>')
	@textText = NQXML::Text.new('text ')
	@boldText = NQXML::Text.new('bold café coffee')
	@moreTextText = NQXML::Text.new(' more text')

	@cdata = NQXML::Text.new("xx<z&xx</\nnewline in cdata\n",
				 "<![CDATA[xx<z&xx</\nnewline in cdata\n]]>")
	@outerEnd = NQXML::Tag.new('outer', nil, true, '</outer>')

	@sub1_xml = '<?xml version="1.0"?>
<!DOCTYPE outer SYSTEM "foobar" [
  <!ENTITY example "<p>An ampersand (&#38;#38;) may be escaped numerically (&#38;#38;#38;) or with a general entity (&amp;amp;).</p>" >
]>
'
	src = '<!ENTITY example "<p>An ampersand (&#38;#38;) may be' +
	    ' escaped numerically (&#38;#38;#38;) or with a general entity' +
	    ' (&amp;amp;).</p> >'
	val = "<p>An ampersand (&#38;) may be escaped numerically" +
	    " (&#38;#38;) or with a general entity (&amp;amp;).</p>"
	@sub1Entity = NQXML::GeneralEntityTag.new('example', val, nil, nil,
						  src)
						
	@sub2_xml = '<?xml version="1.0"?>
<!DOCTYPE test [
<!ELEMENT test (#PCDATA) >
<!ENTITY % xx \'&#37;zz;\'>
<!ENTITY % zz \'&#60;!ENTITY tricky "error-prone" >\' >
%xx;
]>
<test>This sample shows a &tricky; method.</test>
'
	@xxEntity =
	    NQXML::ParameterEntityTag.new('xx', '%zz;', nil,
					  '<!ENTITY % zz \'&#37;zz;\'>')

	src = '<!ENTITY % zz \'&#60;!ENTITY tricky "error-prone" >\' >'
	val = '<!ENTITY tricky "error-prone" >'
	@zzEntity = NQXML::ParameterEntityTag.new('zz', val, nil, src)
    end

end
