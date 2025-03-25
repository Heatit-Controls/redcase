require 'redmine'
require_relative 'lib/issue_patch'
require_relative 'lib/project_patch'
require_relative 'lib/version_patch'
require_relative 'lib/user_patch'
require_relative 'lib/redcase_override'
require_relative 'lib/issue_test_case_hook'
require_relative 'lib/redcase/engine'

Redmine::Plugin.register :redcase do

	name 'Redcase'
	description 'Test cases management plugin for Redmine'
	author 'Bugzinga Team'
	version '1.0'

	permission :view_test_cases, {
		:redcase => [
			:index,
			:get_attachment_urls
		],
		'redcase/environments' => [
			:index
		],
		'redcase/testsuites' => [
			:index
		],
		'redcase/testcases' => [
			:index
		],
		'redcase/executionjournals' => [
			:index
		],
		'redcase/export' => [
			:index
		],
		'redcase/executionsuites' => [
			:index,
			:show
		],
		'redcase/graph' => [
			:show
		],
		'redcase/combos' => [
			:index
		]
	}

	permission :edit_test_cases, {
		:redcase => [
			:index,
			:get_attachment_urls
		],
		'redcase/environments' => [
			:index,
			:update,
			:destroy,
			:create
		],
		'redcase/testsuites' => [
			:index,
			:update,
			:destroy,
			:create
		],
		'redcase/testcases' => [
			:index,
			:update,
			:destroy,
			:copy
		],
		'redcase/executionjournals' => [
			:index
		],
		'redcase/export' => [
			:index
		],
		'redcase/executionsuites' => [
			:index,
			:update,
			:destroy,
			:create,
			:show
		],
		'redcase/graph' => [
			:show
		],
		'redcase/combos' => [
			:index
		]
	}

	permission :execute_test_cases, {
		:redcase => [
			:index,
			:get_attachment_urls
		],
		'redcase/environments' => [
			:index
		],
		'redcase/testsuites' => [
			:index
		],
		'redcase/testcases' => [
			:index,
			:update
		],
		'redcase/executionjournals' => [
			:index
		],
		'redcase/export' => [
			:index
		],
		'redcase/executionsuites' => [
			:index
		]
	}

	menu :project_menu,
		:redcase, {
			:controller => 'redcase',
			:action => 'index'
		}, {
			:if => proc { |p|
				can_view = User.current.allowed_to?(:view_test_cases, p)
				can_edit = User.current.allowed_to?(:edit_test_cases, p)
				tracker_exists = p.trackers.any? { |t| (t.name == 'Test case') }
				(can_view || can_edit) && tracker_exists
			},
			:caption => 'Test cases',
			:after => :new_issue
		}

end

# Initialize the plugin
Rails.application.config.to_prepare do
  Issue.include(IssuePatch) unless Issue.included_modules.include?(IssuePatch)
  Project.include(ProjectPatch) unless Project.included_modules.include?(ProjectPatch)
  Version.include(VersionPatch) unless Version.included_modules.include?(VersionPatch)
  User.include(UserPatch) unless User.included_modules.include?(UserPatch)
end

