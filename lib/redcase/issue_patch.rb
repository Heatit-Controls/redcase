puts "[Redcase] Loading IssuePatch..."

module Redcase
  module IssuePatch
    def self.apply
      puts "[Redcase] IssuePatch.apply called"

      if defined?(Issue)
        puts "[Redcase] Patching Issue directly"

        unless Issue.reflect_on_association(:test_case)
          puts "[Redcase] Applying has_one :test_case to Issue"
          Issue.class_eval do
            has_one :test_case, dependent: :destroy
          end
        else
          puts "[Redcase] test_case already defined"
        end
      else
        puts "[Redcase] Issue is not defined yet"
      end
    end
  end
end
