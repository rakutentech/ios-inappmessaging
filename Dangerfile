declared_trivial = git.lines_of_code <= 2

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 1000

if defined?(github)
  warn "This PR does not have any assignees yet" unless github.pr_json["assignee"]
  
  # Branch name should be properly formatted
  type_pattern = /(fix|feat|refactor|improve|build|ci|docs|chore|test|tests|revert)/
  ticket_pattern = /(MAG|SDKCF)-\d{3,5}/ # Main single ticket in capital letters that can connect this branch to a board tracker ID
  desc_pattern = /[a-z0-9]+(?:-+[a-z0-9]+)*$/ # Short description in small letters and separated by dashes to easily identify the purpose of branch at a glance
  branch_name_pattern_1 = /^#{type_pattern}\/#{ticket_pattern}_#{desc_pattern}/
  branch_name_pattern_2 =  /^#{type_pattern}\/#{desc_pattern}/
  branch_name_pattern_3 = /^release\/[\w]+/ # Less stricter check for release branches (can contain special releases not only using version name)

  branch_name = github.branch_for_head
  is_branch_compliant = branch_name.match(branch_name_pattern_1) || branch_name.match(branch_name_pattern_2) || branch_name.match(branch_name_pattern_3)
  warn("Branch name \"#{branch_name}\" should match format: `<type>/<ticket-no>_<short-desc>` or `<type>/<short-desc>` or `release/<version or desc>`") if !is_branch_compliant
end

has_app_changes = !git.modified_files.grep(/Sources/).empty?
has_test_changes = !git.modified_files.grep(/Tests/).empty?

if has_app_changes && !has_test_changes
  warn('Tests were not updated')
end

# Commit message must be properly formatted
git.commits.each do |commit|
  next if commit.message =~ /Merge branch /

  if /^(?<type>(fix|feat|refactor|improve|build|ci|docs|chore|test|tests|revert)): (?<subject>[\w\W]+)$/ =~ commit.message
    if /^(?<nonimperativeword>(\w+(ed|es)))/ =~ subject
      warn "Verb \"#{nonimperativeword}\" in the commit message must be in imperative tense"
    end
    if /\((?<ticketnos>((MAG|SDKCF)-\d{3,5}(,\s)?)+)\)$/ =~ subject
      if !git.modified_files.include?("CHANGELOG.md") && has_app_changes
        warn "Should include a CHANGELOG entry for #{ticketnos}"
      end
    else
      warn "Commit message \"#{commit.message}\" should append ticket number(s) e.g. (SDKCF-1234, SDKCF-1235)"
    end
  else
    fail "Commit message \"#{commit.message}\" must match format: `type: subject (SDKCF-1234)`"
    message "`type` must be one of `fix|feat|refactor|improve|build|ci|docs|chore|test|tests|revert`"
  end
end

# Delete any existing coverage files due to
# https://github.com/fastlane-community/danger-xcov/issues/33
system('rm -rf artifacts/unit-tests/coverage')
xcov.report(
  workspace: 'RInAppMessaging.xcworkspace',
  scheme: 'AllTests',
  output_directory: 'artifacts/unit-tests/coverage',
  json_report: true,
  include_targets: 'RInAppMessaging.framework',
  include_test_targets: false,
  minimum_coverage_percentage: 70.0,
  skip_slack: true
)
