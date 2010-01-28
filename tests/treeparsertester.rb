#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/treeparser'

class TreeParserTester < NQXMLTester

    # Tokenizes @rsrc.xml and compares the entities returned with a list
    # of expected values.
    def test_parser
	# Build expected entities
	expectedPrologEntities = [
	    @rsrc.xmlDecl, @rsrc.newlineTok,
	    @rsrc.piWithArgs, @rsrc.newlineTok,
	    @rsrc.piNoArgs, @rsrc.newlineTok,
	    @rsrc.doctype, @rsrc.newlineTok, @rsrc.comment,
	    @rsrc.newlineTok
	]
	expectedBodyEntities = [
	    @rsrc.outerStart, @rsrc.textDataWithSub, @rsrc.simpleTagStart,
	    @rsrc.simpleTextData, @rsrc.newlineTok, @rsrc.innerTagStart,
	    @rsrc.cdata, @rsrc.newlineTok, @rsrc.pTagStart, @rsrc.textText,
	    @rsrc.bTagStart, @rsrc.boldText, @rsrc.moreTextText,
	    @rsrc.newlineTok
	]

	parser = NQXML::TreeParser.new(@rsrc.xml)
	doc = parser.document

	assert(parser.eof?())

	assert_equal(doc.doctype, @rsrc.doctype)
	assert_equal(doc.rootNode.entity, @rsrc.outerStart)

	# Compare document prolog with expected prolog.
	assert_equal(expectedPrologEntities.length, doc.prolog.length)
	expectedPrologEntities.each_with_index { | e, i |
	    assert_equal(e, doc.prolog[i])
	}

	# Compare document body with expected entities. We traverse the
	# document's tree depth-first.
	i = 0
	node = doc.rootNode
	while !node.nil?
	    assert_equal(expectedBodyEntities[i], node.entity)
	    i += 1

	    # Get next node using depth-first search.
	    if node.children.length > 0
		node = node.firstChild
	    elsif node.nextSibling() != nil
		node = node.nextSibling()
	    elsif node.parent.nextSibling() != nil
		node = node.parent.nextSibling()
	    else
		node = nil
	    end
	end
	assert_equal(expectedBodyEntities.length, i)
    end

    # Make sure the tree parser gathers entities into a document as
    # expected, and that we can get to them through the appropriate
    # Document methods.
    def test_access
	doc = NQXML::TreeParser.new(@rsrc.xml).document

	root = doc.rootNode
	assert_nil(root.parent)
	assert_equal('outer', root.entity.name)
  	assert_equal(8, root.children.length)
	assert_instance_of(NQXML::Text, root.firstChild().entity)
	assert_instance_of(NQXML::Text, root.lastChild().entity)

	node = root.firstChild().nextSibling()
	assert_equal(node.parent, root)
	assert_equal('<simpleTag>', node.entity.source)
	assert_equal(1, node.children.length)
	assert_equal('text', node.firstChild().entity.text)
    end

    # Creates a tree parser over the XML and sets it to parsing.
    # Expect a parser error that matches `regex'. If line is not nil,
    # expect the error to occur in the specified position(s)
    def expect_error(xml, regex, line = nil, col = nil, pos = nil)
	parser = nil
	begin
	    parser = NQXML::TreeParser.new(xml)
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
		     /end tag 'end:without:start' without opening tag/,
		     1)
    end

    # Make sure tags must be balanced.
    def test_bad_nesting
	expect_error("<line1>\n<bad>\n<nesting></bad>",
		     /end tag 'bad' does not match last-seen start tag named 'nesting'/,
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

end
