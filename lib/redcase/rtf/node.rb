#!/usr/bin/env ruby

require 'stringio'

module Redcase
   module Rtf
      # This class represents an element within an RTF document. The class provides
      # a base class for more specific node types.
      class Node
         # Node parent.
         attr_accessor :parent
         
         # Constructor for the Node class.
         #
         # ==== Parameters
         # parent::  A reference to the Node that owns the new Node. May be nil
         #           to indicate a base or root node.
         def initialize(parent)
            @parent = parent
         end

         # This method retrieves a Node objects previous peer node, returning nil
         # if the Node has no previous peer.
         def previous_node
            peer = nil
            if !parent.nil? and parent.respond_to?(:children)
               index = parent.children.index(self)
               peer  = index > 0 ? parent.children[index - 1] : nil
            end
            peer
         end

         # This method retrieves a Node objects next peer node, returning nil
         # if the Node has no previous peer.
         def next_node
            peer = nil
            if !parent.nil? and parent.respond_to?(:children)
               index = parent.children.index(self)
               peer  = parent.children[index + 1]
            end
            peer
         end

         # This method is used to determine whether a Node object represents a
         # root or base element. The method returns true if the Nodes parent is
         # nil, false otherwise.
         def is_root?
            @parent.nil?
         end

         # This method traverses a Node tree to locate the root element.
         def root
            node = self
            node = node.parent while !node.parent.nil?
            node
         end
      end # End of the Node class.


      # This class represents a specialisation of the Node class to refer to a Node
      # that simply contains text.
      class TextNode < Node
        # Actual text
         attr_accessor :text

         # This is the constructor for the TextNode class.
         #
         # ==== Parameters
         # parent::  A reference to the Node that owns the TextNode. Must not be
         #           nil.
         # text::    A String containing the node text. Defaults to nil.
         #
         # ==== Exceptions
         # RTFError::  Generated whenever an nil parent object is specified to
         #             the method.
         def initialize(parent, text=nil)
            super(parent)
            if parent.nil?
               Redcase::Rtf::RTFError.fire("Nil parent specified for text node.")
            end
            @parent = parent
            @text   = text
         end

         # This method concatenates a String on to the end of the existing text
         # within a TextNode object.
         #
         # ==== Parameters
         # text::  The String to be added to the end of the text node.
         def append(text)
           @text = (@text.nil?) ? text.to_s : @text + text.to_s
         end

         # This method inserts a String into the existing text within a TextNode
         # object. If the TextNode contains no text then it is simply set to the
         # text passed in. If the offset specified is past the end of the nodes
         # text then it is simply appended to the end.
         #
         # ==== Parameters
         # text::    A String containing the text to be added.
         # offset::  The numbers of characters from the first character to insert
         #           the new text at.
         def insert(text, offset)
            if !@text.nil?
               @text = @text[0, offset] + text.to_s + @text[offset, @text.length]
            else
               @text = text.to_s
            end
         end

         # This method generates the RTF equivalent for a TextNode object. This
         # method escapes any special sequences that appear in the text.
         def to_rtf
           rtf=(@text.nil? ? '' : @text.gsub("{", "\\{").gsub("}", "\\}").gsub("\\", "\\\\"))
           # This is from lfarcy / rtf-extensions
           # I don't see the point of coding different 128<n<256 range

           #f1=lambda { |n| n < 128 ? n.chr : n < 256 ? "\\'#{n.to_s(16)}" : "\\u#{n}\\'3f" }
           # Encode as Unicode.

           f=lambda { |n| n < 128 ? n.chr : "\\u#{n}\\'3f" }
           # Ruby 1.9 is safe, cause detect original encoding
           # and convert text to utf-16 first
           if RUBY_VERSION>"1.9.0"
             return rtf.encode("UTF-16LE", :undef=>:replace).each_codepoint.map(&f).join('')
           else
             # You SHOULD use UTF-8 as input, ok?
             return rtf.unpack('U*').map(&f).join('')
           end
         end
      end # End of the TextNode class.


      # This class represents a Node that can contain other Node objects. Its a
      # base class for more specific Node types.
      class ContainerNode < Node
         include Enumerable

         # Children elements of the node
         attr_accessor :children

         # This is the constructor for the ContainerNode class.
         #
         # ==== Parameters
         # parent::     A reference to the parent node that owners the new
         #              ContainerNode object.
         def initialize(parent)
            super(parent)
            @children = []
            @children.concat(yield) if block_given?
         end

         # This method adds a new node element to the end of the list of nodes
         # maintained by a ContainerNode object. Nil objects are ignored.
         #
         # ==== Parameters
         # node::  A reference to the Node object to be added.
         def store(node)
            if !node.nil?
               @children.push(node) if !@children.include?(Node)
               node.parent = self if node.parent != self
            end
            node
         end

         # This method fetches the first node child for a ContainerNode object. If
         # a container contains no children this method returns nil.
         def first
            @children[0]
         end

         # This method fetches the last node child for a ContainerNode object. If
         # a container contains no children this method returns nil.
         def last
            @children.last
         end

         # This method provides for iteration over the contents of a ContainerNode
         # object.
         def each
            @children.each {|child| yield child}
         end

         # This method returns a count of the number of children a ContainerNode
         # object contains.
         def size
            @children.size
         end

         # This method overloads the array dereference operator to allow for
         # access to the child elements of a ContainerNode object.
         #
         # ==== Parameters
         # index::  The offset from the first child of the child object to be
         #          returned. Negative index values work from the back of the
         #          list of children. An invalid index will cause a nil value
         #          to be returned.
         def [](index)
            @children[index]
         end

         # This method generates the RTF text for a ContainerNode object.
         def to_rtf
            Redcase::Rtf::RTFError.fire("#{self.class.name}.to_rtf method not yet implemented.")
         end
      end # End of the ContainerNode class.


      # This class represents a RTF command element within a document. This class
      # is concrete enough to be used on its own but will also be used as the
      # base class for some specific command node types.
      class CommandNode < ContainerNode
         # String containing the prefix text for the command
         attr_accessor :prefix
         # String containing the suffix text for the command
         attr_accessor :suffix
         # A boolean to indicate whether the prefix and suffix should
         # be written to separate lines whether the node is converted
         # to RTF. Defaults to true
         attr_accessor :split
         # A boolean to indicate whether the prefix and suffix should
         # be wrapped in curly braces. Defaults to true.
         attr_accessor :wrap

         # This is the constructor for the CommandNode class.
         #
         # ==== Parameters
         # parent::  A reference to the node that owns the new node.
         # prefix::  A String containing the prefix text for the command.
         # suffix::  A String containing the suffix text for the command. Defaults
         #           to nil.
         # split::   A boolean to indicate whether the prefix and suffix should
         #           be written to separate lines whether the node is converted
         #           to RTF. Defaults to true.
         # wrap::    A boolean to indicate whether the prefix and suffix should
         #           be wrapped in curly braces. Defaults to true.
         def initialize(parent, prefix, suffix=nil, split=true, wrap=true)
            super(parent)
            @prefix = prefix
            @suffix = suffix
            @split  = split
            @wrap   = wrap
         end

         # This method adds text to a command node. If the last child node of the
         # target node is a TextNode then the text is appended to that. Otherwise
         # a new TextNode is created and append to the node.
         #
         # ==== Parameters
         # text::  The String of text to be written to the node.
         def <<(text)
            if !last.nil? and last.respond_to?(:text=)
               last.append(text)
            else
               self.store(TextNode.new(self, text))
            end
         end

         # This method generates the RTF text for a CommandNode object.
         def to_rtf
            text = StringIO.new

            text << '{'       if wrap?
            text << @prefix   if @prefix

            self.each do |entry|
               text << "\n" if split?
               text << entry.to_rtf
            end

            text << "\n"    if split?
            text << @suffix if @suffix
            text << '}'     if wrap?

            text.string
         end

         # This method provides a short cut means of creating a paragraph command
         # node. The method accepts a block that will be passed a single parameter
         # which will be a reference to the paragraph node created. After the
         # block is complete the paragraph node is appended to the end of the child
         # nodes on the object that the method is called against.
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

         # This method provides a short cut means of creating a new ordered or
         # unordered list. The method requires a block that will be passed a
         # single parameter that'll be a reference to the first level of the
         # list. See the +ListLevelNode+ doc for more information.
         #
         # Example usage:
         #
         #   rtf.list do |level1|
         #     level1.item do |li|
         #       li << 'some text'
         #       li.apply(some_style) {|x| x << 'some styled text'}
         #     end
         #
         #     level1.list(:decimal) do |level2|
         #       level2.item {|li| li << 'some other text in a decimal list'}
         #       level2.item {|li| li << 'and here we go'}
         #     end
         #   end
         #
         def list(kind=:bullets)
           node = ListNode.new(self)
           yield node.list(kind)
           self.store(node)
         end

         def link(url, text=nil)
           node = LinkNode.new(self, url)
           node << text if text
           yield node   if block_given?
           self.store(node)
         end

         # This method provides a short cut means of creating a line break command
         # node. This command node does not take a block and may possess no other
         # content.
         def line_break
            self.store(CommandNode.new(self, '\line', nil, false))
            nil
         end

         # This method inserts a footnote at the current position in a node.
         #
         # ==== Parameters
         # text::  A string containing the text for the footnote.
         def footnote(text)
            if !text.nil? and text != ''
               mark = CommandNode.new(self, '\fs16\up6\chftn', nil, false)
               note = CommandNode.new(self, '\footnote {\fs16\up6\chftn}', nil, false)
               note.paragraph << text
               self.store(mark)
               self.store(note)
            end
         end

         # This method inserts a new image at the current position in a node.
         #
         # ==== Parameters
         # source::  Either a string containing the path and name of a file or a
         #           File object for the image file to be inserted.
         #
         # ==== Exceptions
         # RTFError::  Generated whenever an invalid or inaccessible file is
         #             specified or the image file type is not supported.
         def image(source)
            self.store(ImageNode.new(self, source, root.get_id))
         end

         # This method provides a short cut means for applying multiple styles via
         # single command node. The method accepts a block that will be passed a
         # reference to the node created. Once the block is complete the new node
         # will be append as the last child of the CommandNode the method is called
         # on.
         #
         # ==== Parameters
         # style::  A reference to a CharacterStyle object that contains the style
         #          settings to be applied.
         #
         # ==== Exceptions
         # RTFError::  Generated whenever a non-character style is specified to
         #             the method.
         def apply(style)
            # Check the input style.
            if !style.is_character_style?
               Redcase::Rtf::RTFError.fire("Non-character style specified to the "\
                             "CommandNode#apply() method.")
            end

            # Store fonts and colours.
            root.colours << style.foreground unless style.foreground.nil?
            root.colours << style.background unless style.background.nil?
            root.fonts << style.font unless style.font.nil?

            # Generate the command node.
            node = CommandNode.new(self, style.prefix(root.fonts, root.colours))
            yield node if block_given?
            self.store(node)
         end

         # This method provides a short cut means of creating a bold command node.
         # The method accepts a block that will be passed a single parameter which
         # will be a reference to the bold node created. After the block is
         # complete the bold node is appended to the end of the child nodes on
         # the object that the method is call against.
         def bold
            style      = CharacterStyle.new
            style.bold = true
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method provides a short cut means of creating an italic command
         # node. The method accepts a block that will be passed a single parameter
         # which will be a reference to the italic node created. After the block is
         # complete the italic node is appended to the end of the child nodes on
         # the object that the method is call against.
         def italic
            style        = CharacterStyle.new
            style.italic = true
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method provides a short cut means of creating an underline command
         # node. The method accepts a block that will be passed a single parameter
         # which will be a reference to the underline node created. After the block
         # is complete the underline node is appended to the end of the child nodes
         # on the object that the method is call against.
         def underline
            style           = CharacterStyle.new
            style.underline = true
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method provides a short cut means of creating a subscript command
         # node. The method accepts a block that will be passed a single parameter
         # which will be a reference to the subscript node created. After the
         # block is complete the subscript node is appended to the end of the
         # child nodes on the object that the method is call against.
         def subscript
            style           = CharacterStyle.new
            style.subscript = true
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method provides a short cut means of creating a superscript command
         # node. The method accepts a block that will be passed a single parameter
         # which will be a reference to the superscript node created. After the
         # block is complete the superscript node is appended to the end of the
         # child nodes on the object that the method is call against.
         def superscript
            style             = CharacterStyle.new
            style.superscript = true
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method provides a short cut means of creating a strike command
         # node. The method accepts a block that will be passed a single parameter
         # which will be a reference to the strike node created. After the
         # block is complete the strike node is appended to the end of the
         # child nodes on the object that the method is call against.
         def strike
            style        = CharacterStyle.new
            style.strike = true
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method provides a short cut means of creating a font command node.
         # The method accepts a block that will be passed a single parameter which
         # will be a reference to the font node created. After the block is
         # complete the font node is appended to the end of the child nodes on the
         # object that the method is called against.
         #
         # ==== Parameters
         # font::  A reference to font object that represents the font to be used
         #         within the node.
         # size::  An integer size setting for the font. Defaults to nil to
         #         indicate that the current font size should be used.
         def font(font, size=nil)
            style           = CharacterStyle.new
            style.font      = font
            style.font_size = size
            root.fonts << font
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method provides a short cut means of creating a foreground colour
         # command node. The method accepts a block that will be passed a single
         # parameter which will be a reference to the foreground colour node
         # created. After the block is complete the foreground colour node is
         # appended to the end of the child nodes on the object that the method
         # is called against.
         #
         # ==== Parameters
         # colour::  The foreground colour to be applied by the command.
         def foreground(colour)
            style            = CharacterStyle.new
            style.foreground = colour
            root.colours << colour
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method provides a short cut means of creating a background colour
         # command node. The method accepts a block that will be passed a single
         # parameter which will be a reference to the background colour node
         # created. After the block is complete the background colour node is
         # appended to the end of the child nodes on the object that the method
         # is called against.
         #
         # ==== Parameters
         # colour::  The background colour to be applied by the command.
         def background(colour)
            style            = CharacterStyle.new
            style.background = colour
            root.colours << colour
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method provides a short cut menas of creating a colour node that
         # deals with foreground and background colours. The method accepts a
         # block that will be passed a single parameter which will be a reference
         # to the colour node created. After the block is complete the colour node
         # is append to the end of the child nodes on the object that the method
         # is called against.
         #
         # ==== Parameters
         # fore::  The foreground colour to be applied by the command.
         # back::  The background colour to be applied by the command.
         def colour(fore, back)
            style            = CharacterStyle.new
            style.foreground = fore
            style.background = back
            root.colours << fore
            root.colours << back
            if block_given?
               apply(style) {|node| yield node}
            else
               apply(style)
            end
         end

         # This method creates a new table node and returns it. The method accepts
         # a block that will be passed the table as a parameter. The node is added
         # to the node the method is called upon after the block is complete.
         #
         # ==== Parameters
         # rows::     The number of rows that the table contains.
         # columns::  The number of columns that the table contains.
         # *widths::  One or more integers representing the widths for the table
         #            columns.
         def table(rows, columns, *widths)
            node = TableNode.new(self, rows, columns, *widths)
            yield node if block_given?
            store(node)
            node
         end

         alias :write  :<<
         alias :color  :colour
         alias :split? :split
         alias :wrap?  :wrap
      end # End of the CommandNode class.

      # This class represents a paragraph within an RTF document.
      class ParagraphNode < CommandNode
        def initialize(parent, style=nil)
          prefix = '\pard'
          prefix << style.prefix(nil, nil) if style

          super(parent, prefix, '\par')
        end
      end

      # This class represents an ordered/unordered list within an RTF document.
      #
      # Currently list nodes can contain any type of node, but this behaviour
      # will change in future releases. The class overrides the +list+ method
      # to return a +ListLevelNode+.
      #
      class ListNode < CommandNode
        def initialize(parent)
          prefix  = "\\"

          suffix  = '\pard'
          suffix << ListLevel::ResetTabs.map {|tw| "\\tx#{tw}"}.join
          suffix << '\ql\qlnatural\pardirnatural\cf0 \\'

          super(parent, prefix, suffix, true, false)

          @template = root.lists.new_template
        end

        # This method creates a new +ListLevelNode+ of the given kind and
        # stores it in the document tree.
        #
        # ==== Parameters
        # kind::  The kind of this list level, may be either :bullets or :decimal
        def list(kind)
          self.store ListLevelNode.new(self, @template, kind)
        end
      end

      # This class represents a list level, and carries out indenting information
      # and the bullet or number that is prepended to each +ListTextNode+.
      #
      # The class overrides the +list+ method to implement nesting, and provides
      # the +item+ method to add a new list item, the +ListTextNode+.
      class ListLevelNode < CommandNode
        def initialize(parent, template, kind, level=1)
          @template = template
          @kind     = kind
          @level    = template.level_for(level, kind)

          prefix  = '\pard'
          prefix << @level.tabs.map {|tw| "\\tx#{tw}"}.join
          prefix << "\\li#{@level.indent}\\fi-#{@level.indent}"
          prefix << "\\ql\\qlnatural\\pardirnatural\n"
          prefix << "\\ls#{@template.id}\\ilvl#{@level.level-1}\\cf0"

          super(parent, prefix, nil, true, false)
        end

        # Returns the kind of this level, either :bullets or :decimal
        attr_reader :kind

        # Returns the indenting level of this list, from 1 to 9
        def level
          @level.level
        end

        # Creates a new +ListTextNode+ and yields it to the calling block
        def item
          node = ListTextNode.new(self, @level)
          yield node
          self.store(node)
        end

        # Creates a new +ListLevelNode+ to implement nested lists
        def list(kind=@kind)
          node = ListLevelNode.new(self, @template, kind, @level.level+1)
          yield node
          self.store(node)
        end
      end

      # This class represents a list item, that can contain text or
      # other nodes. Currently any type of node is accepted, but after
      # more extensive testing this behaviour may change.
      class ListTextNode < CommandNode
        def initialize(parent, level)
          @level  = level
          @parent = parent

          number = siblings_count + 1 if parent.kind == :decimal
          prefix = "{\\listtext#{@level.marker.text_format(number)}}"
          suffix = '\\'

          super(parent, prefix, suffix, false, false)
        end

        private
          def siblings_count
            parent.children.select {|n| n.kind_of?(self.class)}.size
          end
      end

      class LinkNode < CommandNode
        def initialize(parent, url)
          prefix = "\\field{\\*\\fldinst HYPERLINK \"#{url}\"}{\\fldrslt "
          suffix = "}"

          super(parent, prefix, suffix, false)
        end
      end

      # This class represents a table node within an RTF document. Table nodes are
      # specialised container nodes that contain only TableRowNodes and have their
      # size specified when they are created an cannot be resized after that.
      class TableNode < ContainerNode
         # Cell margin. Default to 100
         attr_accessor :cell_margin

         # This is a constructor for the TableNode class.
         #
         # ==== Parameters
         # parent::   A reference to the node that owns the table.
         # rows::     The number of rows in the tabkle.
         # columns::  The number of columns in the table.
         # *widths::  One or more integers specifying the widths of the table
         #            columns.
         def initialize(parent, *args, &block)
           if args.size>=2
            rows=args.shift
            columns=args.shift
            widths=args
            super(parent) do
               entries = []
               rows.times {entries.push(TableRowNode.new(self, columns, *widths))}
               entries
            end

           elsif block
             block.arity<1 ? self.instance_eval(&block) : block.call(self)
           else
             raise "You should use 0 or >2 args"
           end
            @cell_margin = 100
         end

         # Attribute accessor.
         def rows
            entries.size
         end

         # Attribute accessor.
         def columns
            entries[0].length
         end

         # This method assigns a border width setting to all of the sides on all
         # of the cells within a table.
         #
         # ==== Parameters
         # width::  The border width setting to apply. Negative values are ignored
         #          and zero switches the border off.
         def border_width=(width)
            self.each {|row| row.border_width = width}
         end

         # This method assigns a shading colour to a specified row within a
         # TableNode object.
         #
         # ==== Parameters
         # index::   The offset from the first row of the row to have shading
         #           applied to it.
         # colour::  A reference to a Colour object representing the shading colour
         #           to be used. Set to nil to clear shading.
         def row_shading_colour(index, colour)
            row = self[index]
            row.shading_colour = colour if row != nil
         end

         # This method assigns a shading colour to a specified column within a
         # TableNode object.
         #
         # ==== Parameters
         # index::   The offset from the first column of the column to have shading
         #           applied to it.
         # colour::  A reference to a Colour object representing the shading colour
         #           to be used. Set to nil to clear shading.
         def column_shading_colour(index, colour)
            self.each do |row|
               cell = row[index]
               cell.shading_colour = colour if cell != nil
            end
         end

         # This method provides a means of assigning a shading colour to a
         # selection of cells within a table. The method accepts a block that
         # takes three parameters - a TableCellNode representing a cell within the
         # table, an integer representing the x offset of the cell and an integer
         # representing the y offset of the cell. If the block returns true then
         # shading will be applied to the cell.
         #
         # ==== Parameters
         # colour::  A reference to a Colour object representing the shading colour
         #           to be applied. Set to nil to remove shading.
         def shading_colour(colour)
            if block_given?
               0.upto(self.size - 1) do |x|
                  row = self[x]
                  0.upto(row.size - 1) do |y|
                     apply = yield row[y], x, y
                     row[y].shading_colour = colour if apply
                  end
               end
            end
         end

         # This method overloads the store method inherited from the ContainerNode
         # class to forbid addition of further nodes.
         #
         # ==== Parameters
         # node::  A reference to the node to be added.
         def store(node)
            Redcase::Rtf::RTFError.fire("Table nodes cannot have nodes added to.")
         end

         # This method generates the RTF document text for a TableCellNode object.
         def to_rtf
            text = StringIO.new
            size = 0

            self.each do |row|
               if size > 0
                  text << "\n"
               else
                  size = 1
               end
               text << row.to_rtf
            end

            text.string.sub(/\\row(?!.*\\row)/m, "\\lastrow\n\\row")
         end

         alias :column_shading_color :column_shading_colour
         alias :row_shading_color :row_shading_colour
         alias :shading_color :shading_colour
      end # End of the TableNode class.


      # This class represents a row within an RTF table. The TableRowNode is a
      # specialised container node that can hold only TableCellNodes and, once
      # created, cannot be resized. Its also not possible to change the parent
      # of a TableRowNode object.
      class TableRowNode < ContainerNode
         # This is the constructor for the TableRowNode class.
         #
         # ===== Parameters
         # table::   A reference to table that owns the row.
         # cells::   The number of cells that the row will contain.
         # widths::  One or more integers specifying the widths for the table
         #           columns
         def initialize(table, cells, *widths)
            super(table) do
               entries = []
               cells.times do |index|
                  entries.push(TableCellNode.new(self, widths[index]))
               end
               entries
            end
         end

         # Attribute accessors
         def length
            entries.size
         end

         # This method assigns a border width setting to all of the sides on all
         # of the cells within a table row.
         #
         # ==== Parameters
         # width::  The border width setting to apply. Negative values are ignored
         #          and zero switches the border off.
         def border_width=(width)
            self.each {|cell| cell.border_width = width}
         end

         # This method overloads the parent= method inherited from the Node class
         # to forbid the alteration of the cells parent.
         #
         # ==== Parameters
         # parent::  A reference to the new node parent.
         def parent=(parent)
            Redcase::Rtf::RTFError.fire("Table row nodes cannot have their parent changed.")
         end

         # This method sets the shading colour for a row.
         #
         # ==== Parameters
         # colour::  A reference to the Colour object that represents the new
         #           shading colour. Set to nil to switch shading off.
         def shading_colour=(colour)
            self.each {|cell| cell.shading_colour = colour}
         end

         # This method generates the RTF document text for a TableCellNode object.
         def to_rtf
            text   = StringIO.new
            temp   = StringIO.new
            offset = 0

            text << "\\trowd\\tgraph#{parent.cell_margin}"
            self.each do |entry|
               widths = entry.border_widths
               colour = entry.shading_colour

               text << "\n"
               text << "\\clbrdrt\\brdrw#{widths[0]}\\brdrs" if widths[0] != 0
               text << "\\clbrdrl\\brdrw#{widths[3]}\\brdrs" if widths[3] != 0
               text << "\\clbrdrb\\brdrw#{widths[2]}\\brdrs" if widths[2] != 0
               text << "\\clbrdrr\\brdrw#{widths[1]}\\brdrs" if widths[1] != 0
               text << "\\clcbpat#{root.colours.index(colour)}" if colour != nil
               text << "\\cellx#{entry.width + offset}"
               temp << "\n#{entry.to_rtf}"
               offset += entry.width
            end
            text << "#{temp.string}\n\\row"

            text.string
         end
      end # End of the TableRowNode class.


      # This class represents a cell within an RTF table. The TableCellNode is a
      # specialised command node that is forbidden from creating tables or having
      # its parent changed.
      class TableCellNode < CommandNode
         # A definition for the default width for the cell.
         DEFAULT_WIDTH                              = 300
         # Top border
         TOP = 0
         # Right border
         RIGHT = 1
         # Bottom border
         BOTTOM = 2
         # Left border
         LEFT = 3
         # Width of cell
         attr_accessor :width
         # Attribute accessor.
         attr_reader :shading_colour, :style

         # This is the constructor for the TableCellNode class.
         #
         # ==== Parameters
         # row::     The row that the cell belongs to.
         # width::   The width to be assigned to the cell. This defaults to
         #           TableCellNode::DEFAULT_WIDTH.
         # style::   The style that is applied to the cell. This must be a
         #           ParagraphStyle class. Defaults to nil.
         # top::     The border width for the cells top border. Defaults to nil.
         # right::   The border width for the cells right hand border. Defaults to
         #           nil.
         # bottom::  The border width for the cells bottom border. Defaults to nil.
         # left::    The border width for the cells left hand border. Defaults to
         #           nil.
         #
         # ==== Exceptions
         # RTFError::  Generated whenever an invalid style setting is specified.
         def initialize(row, width=DEFAULT_WIDTH, style=nil, top=nil, right=nil,
                        bottom=nil, left=nil)
            super(row, nil)
            if !style.nil? and !style.is_paragraph_style?
               Redcase::Rtf::RTFError.fire("Non-paragraph style specified for TableCellNode "\
                             "constructor.")
            end

            @width          = (width != nil && width > 0) ? width : DEFAULT_WIDTH
            @borders        = [(top != nil && top > 0) ? top : nil,
                               (right != nil && right > 0) ? right : nil,
                               (bottom != nil && bottom > 0) ? bottom : nil,
                               (left != nil && left > 0) ? left : nil]
            @shading_colour = nil
            @style          = style
         end

         # Attribute mutator.
         #
         # ==== Parameters
         # style::  A reference to the style object to be applied to the cell.
         #          Must be an instance of the ParagraphStyle class. Set to nil
         #          to clear style settings.
         #
         # ==== Exceptions
         # RTFError::  Generated whenever an invalid style setting is specified.
         def style=(style)
            if !style.nil? and !style.is_paragraph_style?
               Redcase::Rtf::RTFError.fire("Non-paragraph style specified for TableCellNode "\
                             "constructor.")
            end
            @style = style
         end

         # This method assigns a width, in twips, for the borders on all sides of
         # the cell. Negative widths will be ignored and a width of zero will
         # switch the border off.
         #
         # ==== Parameters
         # width::  The setting for the width of the border.
         def border_width=(width)
            size = width.nil? ? 0 : width
            if size > 0
               @borders[TOP] = @borders[RIGHT] = @borders[BOTTOM] = @borders[LEFT] = size.to_i
            else
               @borders = [nil, nil, nil, nil]
            end
         end

         # This method assigns a border width to the top side of a table cell.
         # Negative values are ignored and a value of 0 switches the border off.
         #
         # ==== Parameters
         # width::  The new border width setting.
         def top_border_width=(width)
            size = width.nil? ? 0 : width
            if size > 0
               @borders[TOP] = size.to_i
            else
               @borders[TOP] = nil
            end
         end

         # This method assigns a border width to the right side of a table cell.
         # Negative values are ignored and a value of 0 switches the border off.
         #
         # ==== Parameters
         # width::  The new border width setting.
         def right_border_width=(width)
            size = width.nil? ? 0 : width
            if size > 0
               @borders[RIGHT] = size.to_i
            else
               @borders[RIGHT] = nil
            end
         end

         # This method assigns a border width to the bottom side of a table cell.
         # Negative values are ignored and a value of 0 switches the border off.
         #
         # ==== Parameters
         # width::  The new border width setting.
         def bottom_border_width=(width)
            size = width.nil? ? 0 : width
            if size > 0
               @borders[BOTTOM] = size.to_i
            else
               @borders[BOTTOM] = nil
            end
         end

         # This method assigns a border width to the left side of a table cell.
         # Negative values are ignored and a value of 0 switches the border off.
         #
         # ==== Parameters
         # width::  The new border width setting.
         def left_border_width=(width)
            size = width.nil? ? 0 : width
            if size > 0
               @borders[LEFT] = size.to_i
            else
               @borders[LEFT] = nil
            end
         end

         # This method alters the shading colour associated with a TableCellNode
         # object.
         #
         # ==== Parameters
         # colour::  A reference to the Colour object to use in shading the cell.
         #           Assign nil to clear cell shading.
         def shading_colour=(colour)
            root.colours << colour
            @shading_colour = colour
         end

         # This method retrieves an array with the cell border width settings.
         # The values are inserted in top, right, bottom, left order.
         def border_widths
            widths = []
            @borders.each {|entry| widths.push(entry.nil? ? 0 : entry)}
            widths
         end

         # This method fetches the width for top border of a cell.
         def top_border_width
            @borders[TOP].nil? ? 0 : @borders[TOP]
         end

         # This method fetches the width for right border of a cell.
         def right_border_width
            @borders[RIGHT].nil? ? 0 : @borders[RIGHT]
         end

         # This method fetches the width for bottom border of a cell.
         def bottom_border_width
            @borders[BOTTOM].nil? ? 0 : @borders[BOTTOM]
         end

         # This method fetches the width for left border of a cell.
         def left_border_width
            @borders[LEFT].nil? ? 0 : @borders[LEFT]
         end

         # This method overloads the paragraph method inherited from the
         # ComamndNode class to forbid the creation of paragraphs.
         #
         # ==== Parameters
         # style::  The paragraph style, ignored
         def paragraph(style=nil)
            Redcase::Rtf::RTFError.fire("TableCellNode#paragraph() called. Table cells cannot "\
                          "contain paragraphs.")
         end

         # This method overloads the parent= method inherited from the Node class
         # to forbid the alteration of the cells parent.
         #
         # ==== Parameters
         # parent::  A reference to the new node parent.
         def parent=(parent)
            Redcase::Rtf::RTFError.fire("Table cell nodes cannot have their parent changed.")
         end

         # This method overrides the table method inherited from CommandNode to
         # forbid its use in table cells.
         #
         # ==== Parameters
         # rows::     The number of rows for the table.
         # columns::  The number of columns for the table.
         # *widths::  One or more integers representing the widths for the table
         #            columns.
         def table(rows, columns, *widths)
            Redcase::Rtf::RTFError.fire("TableCellNode#table() called. Nested tables not allowed.")
         end

         # This method generates the RTF document text for a TableCellNode object.
         def to_rtf
            text      = StringIO.new
            separator = split? ? "\n" : " "
            line      = (separator == " ")

            text << "\\pard\\intbl"
            text << @style.prefix(nil, nil) if @style != nil
            text << separator
            self.each do |entry|
               text << "\n" if line
               line = true
               text << entry.to_rtf
            end
            text << (split? ? "\n" : " ")
            text << "\\cell"

            text.string
         end
      end # End of the TableCellNode class.


      # This class represents a document header.
      class HeaderNode < CommandNode
         # A definition for a header type.
         UNIVERSAL                                  = :header

         # A definition for a header type.
         LEFT_PAGE                                  = :headerl

         # A definition for a header type.
         RIGHT_PAGE                                 = :headerr

         # A definition for a header type.
         FIRST_PAGE                                 = :headerf

         # Attribute accessor.
         attr_reader :type

         # Attribute mutator.
         attr_writer :type


         # This is the constructor for the HeaderNode class.
         #
         # ==== Parameters
         # document::  A reference to the Document object that will own the new
         #             header.
         # type::      The style type for the new header. Defaults to a value of
         #             HeaderNode::UNIVERSAL.
         def initialize(document, type=UNIVERSAL)
            super(document, "\\#{type.id2name}", nil, false)
            @type = type
         end

         # This method overloads the footnote method inherited from the CommandNode
         # class to prevent footnotes being added to headers.
         #
         # ==== Parameters
         # text::  Not used.
         #
         # ==== Exceptions
         # RTFError::  Always generated whenever this method is called.
         def footnote(text)
            Redcase::Rtf::RTFError.fire("Footnotes are not permitted in page headers.")
         end
      end # End of the HeaderNode class.


      # This class represents a document footer.
      class FooterNode < CommandNode
         # A definition for a header type.
         UNIVERSAL                                  = :footer

         # A definition for a header type.
         LEFT_PAGE                                  = :footerl

         # A definition for a header type.
         RIGHT_PAGE                                 = :footerr

         # A definition for a header type.
         FIRST_PAGE                                 = :footerf

         # Attribute accessor.
         attr_reader :type

         # Attribute mutator.
         attr_writer :type

         # This is the constructor for the FooterNode class.
         #
         # ==== Parameters
         # document::  A reference to the Document object that will own the new
         #             footer.
         # type::      The style type for the new footer. Defaults to a value of
         #             FooterNode::UNIVERSAL.
         def initialize(document, type=UNIVERSAL)
            super(document, "\\#{type.id2name}", nil, false)
            @type = type
         end

         # This method overloads the footnote method inherited from the CommandNode
         # class to prevent footnotes being added to footers.
         #
         # ==== Parameters
         # text::  Not used.
         #
         # ==== Exceptions
         # RTFError::  Always generated whenever this method is called.
         def footnote(text)
            Redcase::Rtf::RTFError.fire("Footnotes are not permitted in page footers.")
         end

         def type=(type)
            @type = type
         end
      end # End of the FooterNode class.
   end # End of the Rtf module
end # End of the Redcase module
