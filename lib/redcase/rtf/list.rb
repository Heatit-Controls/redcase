#!/usr/bin/env ruby
module Redcase
  module Rtf
    class ListTable
      def initialize
        @templates = []
      end

      def new_template
        @templates.push ListTemplate.new(next_template_id)
        @templates.last
      end

      def to_rtf(indent = 0)
        return '' if @templates.empty?

        prefix = indent > 0 ? ' ' * indent : ''

        text = "#{prefix}{\\*\\listtable"
        @templates.each { |tpl| text << tpl.to_rtf }
        text << "}"

        text << "#{prefix}{\\*\\listoverridetable"
        @templates.each do |tpl|
          text << "{\\listoverride\\listid#{tpl.id}\\listoverridecount0\\ls#{tpl.id}}"
        end
        text << "}\n"
        text
      end

      protected

      def next_template_id
        @templates.size + 1
      end
    end

    # Alias the constant so that Redcase::Rtf::List points to ListTable
    List = ListTable

    class ListMarker
      def initialize(name, codepoint = nil)
        @name = name
        @codepoint = codepoint
      end

      def bullet?
        !@codepoint.nil?
      end

      def type
        bullet? ? :bullet : :decimal
      end

      def number_type
        # 23: bullet, 0: arabic
        bullet? ? 23 : 0
      end

      def name
        n = "\\{#@name\\}"
        n << '.' unless bullet?
        n
      end

      def template_format
        if bullet?
          "\\'01\\uc0\\u#@codepoint"
        else
          "\\'02\\'00. "
        end
      end

      def text_format(n = nil)
        txt = bullet? ? "\\uc0\\u#@codepoint" : "#{n}."
        "\t#{txt}\t"
      end
    end

    class ListTemplate
      attr_reader :id

      Markers = {
        disc:    ListMarker.new('disc',    0x2022),
        hyphen:  ListMarker.new('hyphen',  0x2043),
        decimal: ListMarker.new('decimal')
      }

      def initialize(id)
        @levels = []
        @id = id
      end

      def level_for(level, kind = :bullets)
        @levels[level - 1] ||= begin
          marker = Markers[kind == :bullets ? :disc : :decimal]
          ListLevel.new(self, marker, level)
        end
      end

      def to_rtf(indent = 0)
        prefix = indent > 0 ? ' ' * indent : ''
        text = "#{prefix}{\\list\\listtemplate#{id}\\listhybrid"
        @levels.each { |lvl| text << lvl.to_rtf }
        text << "{\\listname;}\\listid#{id}}\n"
        text
      end
    end

    class ListLevel
      ValidLevels = (1..9)
      LevelTabs = [
        220, 720, 1133, 1700, 2267,
        2834, 3401, 3968, 4535, 5102,
        5669, 6236, 6803
      ].freeze
      ResetTabs = [560].concat(LevelTabs[2..-1]).freeze

      attr_reader :level, :marker

      def initialize(template, marker, level)
        unless marker.is_a?(ListMarker)
          Redcase::Rtf::RTFError.fire("Invalid marker #{marker.inspect}")
        end

        unless ValidLevels.include?(level)
          Redcase::Rtf::RTFError.fire("Invalid list level: #{level}")
        end

        @template = template
        @level = level
        @marker = marker
      end

      def type
        @marker.type
      end

      def reset_tabs
        ResetTabs
      end

      def tabs
        @tabs ||= begin
          tabs = LevelTabs.dup
          (@level - 1).times do
            a, = tabs.shift(3)
            a, b = a + 720, a + 1220
            tabs.shift while tabs.first < b
            tabs.unshift a, b
          end
          tabs
        end
      end

      def id
        @id ||= @template.id * 10 + level
      end

      def indent
        @indent ||= level * 720
      end

      def to_rtf(indent = 0)
        prefix = indent > 0 ? ' ' * indent : ''
        text = "#{prefix}{\\listlevel\\levelstartat1"
        nfc = @marker.number_type
        text << "\\levelnfc#{nfc}\\levelnfcn#{nfc}"
        text << '\leveljc0\leveljcn0'
        text << '\levelfollow0'
        text << '\levelindent0\levelspace360'
        text << "{\\*\\levelmarker #{@marker.name}}"
        text << "{\\leveltext\\leveltemplateid#{id}#{@marker.template_format};}"
        text << '{\levelnumbers;}'
        text << "\\fi-360\\li#{indent}\\lin#{indent}}\n"
        text
      end
    end
  end
end
