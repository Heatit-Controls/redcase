#!/usr/bin/env ruby

require 'stringio'

module Redcase
  module Rtf
    # This class represents an RTF document. This is the root class for RTF document generation.
    class Document < CommandNode
      # Attribute accessor.
      attr_reader :fonts, :colours, :information, :style, :lists

      # This is the constructor for the Document class.
      #
      # ==== Parameters
      # font::  The default font to be used in the document. Defaults to
      #         Font::SWISS, "Arial".
      def initialize(font=nil)
        super(nil, '\rtf1\ansi\deff0', nil)

        @fonts       = FontTable.new
        @colours     = ColourTable.new
        @information = Information.new
        @style      = DocumentStyle.new
        @lists      = ListTable.new

        # Add the default font if one hasn't been specified.
        font = Font.new(Font::SWISS, 'Arial') if font.nil?
        @fonts << font
      end

      # This method provides a shortcut for creating a paragraph node within a
      # Document object.
      #
      # ==== Parameters
      # style::  A reference to a ParagraphStyle object that defines the style
      #          for the new paragraph. Defaults to nil to indicate that the
      #          currently applied paragraph styling should be used.
      def paragraph(style=nil)
        node = ParagraphNode.new(self, style)
        yield node if block_given?
        self.store(node)
      end

      # This method generates the RTF text for a Document object.
      def to_rtf
        text = StringIO.new

        # Output the header, font table, colour table and information group.
        text << "{#{@prefix}\n"
        text << @fonts.to_rtf(3)
        text << "\n"
        text << @colours.to_rtf(3)
        text << "\n"
        text << @information.to_rtf(3)
        text << "\n"
        text << @lists.to_rtf(3)
        text << "\n"

        # Output the document style settings.
        text << @style.prefix(nil, nil)
        text << "\n"

        # Output the document contents.
        self.each do |entry|
          text << entry.to_rtf
          text << "\n"
        end

        # Output the closing brace.
        text << "}"

        text.string
      end
    end # End of the Document class.
  end # End of the Rtf module.
end # End of the Redcase module. 