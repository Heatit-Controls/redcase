# This patch adds ExecutionJournal linkage to Version
# Ensure compatibility with Redmine 6.0
module VersionPatch
  extend ActiveSupport::Concern

  included do
    # One-to-many relationship: (1)Version <=> (*)ExecutionJournal
    has_many :execution_journals, dependent: :destroy
  end
end
