# This patch adds ExecutionJournal linkage to User
# Ensure compatibility with Redmine 6.0
module UserPatch
  extend ActiveSupport::Concern

  included do
    # One-to-many relationship: (1)User <=> (*)ExecutionJournal
    has_many :execution_journals, foreign_key: 'executor_id', dependent: :nullify
  end
end
