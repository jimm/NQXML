NAME = README
DOCBOOK = $(NAME).sgml
DVI = $(NAME).dvi
TEXT = ../$(NAME)
HTML = $(NAME)
PDF = $(NAME).pdf
RTF = $(NAME).rtf

# Define DBTOOL_PREFIX as "db2" for SuSE 6.3, "docbook2" for RedHat 7.1.
# (Actually, "db2" also works under RedHat.)
#
# DBTOOL_PREFIX = db2
DBTOOL_PREFIX = docbook2

TO_TEXT = sgml2text.rb

# Flags added to the HTML conversion process. For some reason, the RedHat
# 7.1 version of the docbook tools don't accept the --quiet flag. Also,
# the default behavior of creating the HTML files in the current directory
# is undesirable so we use the --output flag.
#
#TO_HTML_FLAGS = --quiet
TO_HTML_FLAGS = --output $(NAME)

TO_HTML = $(DBTOOL_PREFIX)html
TO_DVI = $(DBTOOL_PREFIX)dvi
TO_PDF = $(DBTOOL_PREFIX)pdf
TO_RTF = $(DBTOOL_PREFIX)rtf

# You may want to define NO_DTDDECL_WARNING if your system spews an
# excessive amount of these unnecessary warnings. My SuSE 6.3 system did.
#
# NO_DTDDECL_WARNING = 2>&1 | grep -v 'DTDDECL catalog entries are not supported'

# Make text (../README) and html. We don't need the DVI, PDF, or RTF.
# Create them as you wish by typing "make dvi", "make pdf", or "make rtf".
all:		text html

text:		$(TEXT)

$(TEXT):	$(DOCBOOK) $(TO_TEXT)
	$(TO_TEXT) $(DOCBOOK) >$(TEXT)

html:		$(HTML)

$(HTML):	$(DOCBOOK)
	rm -fr $(NAME)
	$(TO_HTML) $(TO_HTML_FLAGS) $(DOCBOOK) $(NO_DTDDECL_WARNING)
	mkdir $(NAME)/stylesheet-images
	cp /usr/share/sgml/docbook/dsssl-stylesheets-1.59/images/warning.gif \
		$(NAME)/stylesheet-images

# Not used when releasing NQXML, but useful for viewing and printing.
# To create, type "make dvi".
dvi:		$(DVI)

$(DVI):		$(DOCBOOK)
	$(TO_DVI) $(DOCBOOK) $(NO_DTDDECL_WARNING)

# Not used when releasing NQXML, but useful for viewing and printing.
# To create, type "make pdf".
pdf:		$(PDF)

$(PDF):		$(DOCBOOK)
	$(TO_PDF) $(DOCBOOK) $(NO_DTDDECL_WARNING)

# Not used when releasing NQXML, but useful for viewing and printing.
# To create, type "make rtf".
rtf:		$(RTF)

$(RTF):		$(DOCBOOK)
	$(TO_RTF) $(DOCBOOK) $(NO_DTDDECL_WARNING)

# Kryten's favorite.
clean:
	rm -fr $(NAME) $(NAME).{dvi,aux,log,tex,rtf,pdf,junk,out}
