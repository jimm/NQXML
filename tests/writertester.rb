#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/writer'

class WriterTester < NQXMLTester

    def test_prettify
	compare_test_prettify(true)
    end

    def test_no_prettify
	compare_test_prettify(false)
    end

    # NOTE: this test will break if we add so many nested tags that the
    # writer would start replacing leading spaces with tabs. Since we only
    # have one indentation level, all is well.
    def compare_test_prettify(prettify)
	f_xml = f_answer = nil
	begin
	    suffix = prettify ? "\n" : ''

	    f_xml = Tempfile.new('xml_writer')
	    f_answer = Tempfile.new('xml_writer_answer')

	    w = NQXML::Writer.new(f_xml, prettify)

	    f_answer.print("<?xml version=\"1.0\"?>#{suffix}")
	    w.processingInstruction('xml', 'version="1.0"')

	    f_answer.print("<tag1>#{suffix}")
	    w.startElement('tag1')

	    f_answer.print(' ' * NQXML::Writer::INDENT_OFFSET) if prettify
	    f_answer.print("<tag2 attr1=\"foo\" attr2=\"b&amp;r\">#{suffix}")
	    w.startElement('tag2')
	    w.attribute('attr1', 'foo')
	    w.attribute('attr2', 'b&r')

	    f_answer.print("data &amp; &lt;stuff&gt;\n")
	    w.write("data & <stuff>\n")

	    f_answer.print(' '* NQXML::Writer::INDENT_OFFSET) if prettify
	    f_answer.print("</tag2>#{suffix}")
	    w.endElement('tag2')

	    f_answer.print(' ' * NQXML::Writer::INDENT_OFFSET) if prettify
	    f_answer.print("<empty-tag/>#{suffix}")
	    w.startElement('empty-tag')
	    w.endElement('empty-tag')

	    f_answer.print("</tag1>#{suffix}")
	    w.endElement('tag1')

	    f_answer.close()
	    f_xml.close()

	    assert(File.compare(f_answer.path(), f_xml.path()))
	rescue NQXML::WriterError
	    assert_fail($!)
	ensure
	    f_answer.close(true)
	    f_xml.close(true)
	end
    end

    # Makes sure that writers can accept strings.
    def test_string_arg
	str = ''
	w = NQXML::Writer.new(str)

	w.write('data')
	assert_equals('data', str)

	w.comment('foo')
	assert_equals('data<!--foo-->', str)
    end

    # Makes sure that writers can accept arrays. Not sure when this would
    # be useful, but what the heck. Arrays respond to '<<', so why not?
    def test_array_arg
	array = Array.new
	w = NQXML::Writer.new(array)

	w.write('data')
	assert_equals(['data'], array)

	w.comment('foo')
	assert_equals(['data', '<!--foo-->'], array)
    end

    # Creates a writer and passes it in to a block. Expect a parser error
    # that matches `regex'. If line is not nil, expect the error to occur
    # in the specified position(s)
    def expect_error(regex)
	io = Tempfile.new('writer_error')
	begin
	    writer = NQXML::Writer.new(io)
	    yield writer
	    assert_fail("expected exception '#{regex.source}'")
	rescue NQXML::WriterError => ex
	    assert_match($!, regex)
	ensure
	    io.close(true)
	end
    end

    def test_writer_errors
	expect_error(/attribute outside of tag start/) { | w |
	    w.attribute('illegal', 'because no tag yet')
	}
	expect_error(/end element without start element/) { | w |
	    w.endElement('illegal because no tag yet')
	}
	expect_error(/does not match open element name/) { | w |
	    w.startElement('foo')
	    w.endElement('bar')
	}
    end

    # Compares the text read from the IO object to a normalized version of
    # @rsrc.xml.
    def compare_to_rsrc_xml(io, sourceFooToBletch)
	writtenLines = io.read()

	# What we expect is slightly different than the original XML
	# because entities have been replaced and the output tags and
	# attribute values have been normalized.
	normalizedXml = @rsrc.xml.dup()
	normalizedXml.gsub!(/&foo;/, 'bletch')
	normalizedXml.gsub!('/>', '></inner:tag>')
	normalizedXml.gsub!("tabs\tto\tspaces", "tabs to spaces")

	# The writer's output won't have the same whitespace.
	normalizedXml.gsub!(/^\s+\<(!ENTITY|!ELEMENT|!ATTLIST|!NOTATION|\?|!--)/,
			    '<\1')
	# Get rid of one newline that the writer doesn't output.
	normalizedXml.gsub!(/(<!DOCTYPE(.+?))[\n]]>/m, '\1]>')

	assert_equal(normalizedXml, writtenLines)
    end

    # Makes sure that a writer writes what a tree parser parses, except
    # for tag and text differences because of normalization. For example,
    # the tag '<foo/>' will be written as '<foo></foo>'.
    def test_writing_document
	io = nil
	begin
	    doc = NQXML::TreeParser.new(@rsrc.xml).document

	    io = Tempfile.new('writer_document')
	    writer = NQXML::Writer.new(io)
	    writer.writeDocument(doc)

	    io.open()		# closes, then opens for reading
	    compare_to_rsrc_xml(io, true)
	ensure
	    io.close(true) if io
	end
    end

    # Reconstructs @rsrc.xml from document and node objects and compares
    # the result with the tree-parsed version of the origial @rsrc.xml
    # text. Since we already have the entities we need inside @rsrc,
    # lets be lazy and use them. We're really exercising the document
    # object here.
    def test_creating_document
	doc = NQXML::Document.new()

	prologEntities = [
	    @rsrc.xmlDecl, @rsrc.newlineTok,
	    @rsrc.piWithArgs, @rsrc.newlineTok,
	    @rsrc.piNoArgs, @rsrc.newlineTok,
	    @rsrc.doctype, @rsrc.newlineTok, @rsrc.comment,
	    @rsrc.newlineTok
	]
	rootChildren = [
	    @rsrc.textDataWithSub, @rsrc.simpleTagStart,
	    @rsrc.newlineTok, @rsrc.innerTagStart,
	    @rsrc.cdata, @rsrc.newlineTok, @rsrc.pTagStart, @rsrc.newlineTok
	]
	paragraphChildren = [
	    @rsrc.textText, @rsrc.bTagStart, # bold text here
	    @rsrc.moreTextText
	]
	# @rsrc.boldText inside bold tag

	# Add prolog entities to document.
	prologEntities.each { | entity | doc.addToProlog(entity) }

	# Set root node.
	doc.setRoot(@rsrc.outerStart)
	assert_equal(@rsrc.outerStart, doc.rootNode.entity)
	assert_nil(doc.rootNode.parent)

	# Add children of root node.
	rootChildren.each { | entity | doc.rootNode.addChild(entity) }
	assert_equal(rootChildren.length, doc.rootNode.children.length)

	# Find simpleTag and add child.
	node = doc.rootNode.children.detect { | n |
	    n.entity.instance_of?(NQXML::Tag) && n.entity.name == 'simpleTag'
	}
	assert_not_nil(node)
	node.addChild(@rsrc.simpleTextData)
	assert_equal(1, node.children.length)

	# Find paragraph node and add children.
	node = doc.rootNode.children.detect { | n |
	    n.entity.instance_of?(NQXML::Tag) && n.entity.name == 'p'
	}
	assert_not_nil(node)
	paragraphChildren.each { | entity | node.addChild(entity) }
	assert_equal(paragraphChildren.length, node.children.length)

	# Find bold node and add text child.
	node = node.children.detect { | n |
	    n.entity.instance_of?(NQXML::Tag) && n.entity.name == 'b'
	}
	assert_not_nil(node)
	node.addChild(@rsrc.boldText)

	# Now write this document and compare it to writing out
	# the document created by parsing @rsrc.xml.
	io = nil
	begin
	    io = Tempfile.new('writer_document')
	    writer = NQXML::Writer.new(io)
	    writer.writeDocument(doc)
	    io.open()		# closes, then opens for reading
	    compare_to_rsrc_xml(io, false)
	ensure
	    io.close(true) if io
	end
    end

    def test_entity_substitution
    end

end
