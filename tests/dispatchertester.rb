#
# Copyright (c) 2001 by Jim Menard <jimm@io.com>
#
# Released under the same license as Ruby. See
# http://www.ruby-lang.org/en/LICENSE.txt.
#

require 'nqxml/dispatcher'

class DispatcherTester < RUNIT::TestCase

    @@xml = nil

    def setup
	if @@xml.nil?
	    @@xml =
'<?xml version="1.0"?>
<!DOCTYPE book SYSTEM "foo.bar">
<book>My Book
  <!-- My Book, which is mine, is a book. That is mine. -->
  <intro>
    <p>This is the intro to my book,which has<bold>bold ideas</bold>
    </p>
  </intro>
  <chapter>
  <p>This is the first chapter.  It has <bold>bold text</bold></p>
  <note>Should match chapter/*</note>
  </chapter>
  <appendix>
    <chapter>a chapter in the appendix
      <figure>Should match chapter/*</figure>
    </chapter>
  </appendix>
</book>

<chapter>
  <p>Should match chapter/*</p>
</chapter>
'
	end
	@xml = @@xml
    end

    def test_dispatcher
	nd = NQXML::Dispatcher.new(@xml)

	chapterCount = 0

	nd.handle(:start_element, ['chapter']) { |e| chapterCount += 1 }
	nd.handle(:text, %w(book intro p bold)) { |e|
	    assert_equal('bold ideas', e.text)
	}
	nd.handle(:text, %w(bold)) { |e|
	    assert_equal('bold text', e.text)
	}
	nd.handle(:text, :book, :chapter, :p) { |e|
	    assert_equal('This is the first chapter.  It has ', e.text)
	}
	nd.handle(:text, 'chapter', '*') { |e|
	    assert_equal('Should match chapter/*', e.text)
	}

	nd.start()

	assert_equal(3, chapterCount)
    end

    def test_missing_code_block
	nd = NQXML::Dispatcher.new(@xml)
	assert_exception(ArgumentError) { nd.handle(:comment) }
	assert_exception(ArgumentError) { nd.handle(:text, %w(a b c)) }
	assert_exception(ArgumentError) { nd.handle(:text, :foo) }
    end

    def no_match_test(token, argList)
	nd = NQXML::Dispatcher.new(@xml)
	found = false
	nd.handle(token, argList) { found = true }
	nd.start()
	assert_equal(false, found)
    end

    def test_no_match
	no_match_test(:start_element, %w(foo chapter))
	no_match_test(:start_element, %w(foo *))
	no_match_test(:start_element, %w(xyzzy))
    end

    def star_test(*args)
	nd = NQXML::Dispatcher.new(@xml)
	found = false
	nd.handle(*args) { | e |
	    found = true
	    assert_equal(e.text,
			 'My Book, which is mine, is a book. That is mine.')
	}
	nd.start()
	assert_equal(true, found)
    end

    def test_star
	star_test(:comment)
	star_test(:comment, :*)
    end

end
