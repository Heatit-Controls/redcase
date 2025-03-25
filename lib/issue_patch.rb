# This patch adds TestCase linkage to Issue
# Ensure compatibility with Redmine 6.0
module IssuePatch
  extend ActiveSupport::Concern
  
  included do
    # One-to-one relationship: (1)Issue <=> (1)TestCase
    has_one :test_case, dependent: :destroy, class_name: 'TestCase', foreign_key: 'issue_id'
  end
end
