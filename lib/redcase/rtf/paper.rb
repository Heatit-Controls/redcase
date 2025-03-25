#!/usr/bin/env ruby

module Redcase
   module Rtf
      # This class represents the paper settings within an RTF document.
      class Paper
         # Attribute accessor.
         attr_reader :width, :height
      
         # This is the constructor for the Paper class.
         #
         # ==== Parameters
         # width::   The width of the paper in twips. Defaults to 11906 (A4 paper
         #           size width).
         # height::  The height of the paper in twips. Defaults to 16838 (A4 paper
         #           size height).
         def initialize(width=11906, height=16838)
            @width  = width
            @height = height
         end
         
         # A definition for a paper size setting.
         def self.A4
            new(11906, 16838)
         end
      
         # A definition for a paper size setting.
         def self.A5
            new(8391, 11906)
         end
      
         # A definition for a paper size setting.
         def self.B5
            new(7175, 10075)
         end
      
         # A definition for a paper size setting.
         def self.LETTER
            new(12240, 15840)
         end
      
         # A definition for a paper size setting.
         def self.LEGAL
            new(12240, 20163)
         end
      
         # A definition for a paper size setting.
         def self.EXECUTIVE
            new(10440, 14220)
         end
      
         # A definition for a paper size setting.
         def self.COM10
            new(5220, 11880)
         end
      
         # A definition for a paper size setting.
         def self.MONARCH
            new(5220, 9840)
         end
      end # End of the Paper class.
   end # End of the Rtf module.
end # End of the Redcase module.