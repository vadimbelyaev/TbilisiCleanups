# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
# warn("PR is more than 500 lines of code, it may be difficult to review") if git.lines_of_code > 500

# PR title must start with a task ID
failure("PR title doesn't start with a task ID") unless github.pr_title.match? "^EX-\d+ .*"

# PR body must contain a link to the task
failure("PR description doesn't contain a link to the task") unless github.pr_body.include? "https://example.com"
