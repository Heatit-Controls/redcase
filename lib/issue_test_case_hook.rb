# Ensure the Issue model always has the test_case association
# This is a fallback in case the patch doesn't work
module IssueTestCaseHook
  def self.apply
    # Directly add the association to the Issue class
    unless Issue.reflect_on_association(:test_case)
      Issue.class_eval do
        has_one :test_case, dependent: :destroy, class_name: 'TestCase', foreign_key: 'issue_id'
      end
      puts "TestCase association added to Issue model via hook"
    end
  end
end

# Apply the hook immediately
Rails.application.config.after_initialize do
  IssueTestCaseHook.apply
end 