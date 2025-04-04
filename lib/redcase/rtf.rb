#!/usr/bin/env ruby

require 'stringio'
require_relative 'rtf/font'
require_relative 'rtf/colour'
require_relative 'rtf/style'
require_relative 'rtf/information'
require_relative 'rtf/paper'
require_relative 'rtf/node'
require_relative 'rtf/list'
require_relative 'rtf/document'

module Redcase
  # This module encapsulates all the classes and definitions relating to the RTF
  # library.
  module Rtf
    VERSION="0.5.0"
     # This is the exception class used by the RTF library code to indicate
     # errors.
     class RTFError < StandardError
        # This is the constructor for the RTFError class.
        #
        # ==== Parameters
        # message::  A reference to a string containing the error message for
        #            the exception defaults to nil.
        def initialize(message=nil)
           super(message == nil ? 'No error message available.' : message)
        end

        # This method provides a short cut for raising RTFErrors.
        #
        # ==== Parameters
        # message::  A string containing the exception message. Defaults to nil.
        def RTFError.fire(message=nil)
           raise RTFError.new(message)
        end
     end # End of the RTFError class.
  end # End of the Rtf module.
end # End of the Redcase module.
