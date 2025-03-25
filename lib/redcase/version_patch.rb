# This patch adds Execution Suite linkage to Version
module Redcase
  module VersionPatch

    def self.included(base)
      base.class_eval do
        # One-to-many relationship: (1)Version <=> (*)ExecutionJournal
        has_many :execution_journals, :dependent => :destroy
        has_and_belongs_to_many :execution_suites
      end
    end

  end
end
