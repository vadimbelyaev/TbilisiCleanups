# Shared constants
TASK_ID_REGEX = /^EX-(\d+) .+/

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn "PR is classed as Work in Progress" if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
# warn "PR is more than 500 lines of code, it may be difficult to review" if git.lines_of_code > 500

# PR title must start with a task ID
failure "PR title doesn't begin with a task ID" unless github.pr_title.match? TASK_ID_REGEX

# PR body must contain a link to the task
failure "PR description doesn't contain a link to the task" unless github.pr_body.include? "https://example.com"

# PR should not contain merge commits
if git.commits.any? { |c| c.parents.length > 1 }
  warn "PR contains merge commits. To get rid of this warning, rebase the branch `#{github.branch_for_head}` onto `{github.branch_for_base}`."
end

# All commits in a PR must contain a task ID unless they are in the exempt list
EXEMPT_COMMIT_MESSAGE_REGEXES = [/Change version number/]
unless git.commits.all? { |c| (c.message.match? TASK_ID_REGEX) | (EXEMPT_COMMIT_MESSAGE_REGEXES.any? { |msg| c.message.match? msg }) }
  failure "PR contains commits with messages that don't begin with a task ID. To get rid of this warning, use interactive rebase to change commit messages."
end
