module Rtf::Converters
  # Empty, for now
end

# Make the HTML converter optional
begin
  require_relative 'converters/html'
rescue LoadError => e
  # Ignore if HTML converter can't be loaded
  warn "RTF HTML converter not available: #{e.message}"
end
