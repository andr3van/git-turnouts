#!/usr/bin/env bats
# Tests for PR title search behavior

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

mock_gh_pr_list() {
  local mock_gh_dir="$TEST_TEMP_DIR/.mock/bin"
  mkdir -p "$mock_gh_dir"

  cat > "$mock_gh_dir/gh" << 'MOCK_GH_EOF'
#!/bin/bash
if [[ "$*" == "pr list --json number,title,headRefName" ]]; then
  echo '[
    {"number": 1, "title": "Exact Match Title", "headRefName": "branch-1"},
    {"number": 2, "title": "Partial Match Title", "headRefName": "branch-2"}
  ]'
elif [[ "$1" == "pr" && "$2" == "view" ]]; then
  # For PR number check
  if [[ "$3" == "1" ]]; then
    echo '{"number": 1, "title": "Exact Match Title", "headRefName": "branch-1", "state": "OPEN", "baseRefName": "master"}'
  fi
fi
MOCK_GH_EOF

  chmod +x "$mock_gh_dir/gh"
  export PATH="$mock_gh_dir:$PATH"
}

@test "PR title search: partial match with unquoted shell argument" {
  mock_gh_pr_list
  
  # Run git-turnouts add "Match"
  run "$GIT_TURNOUTS_SCRIPT" add "Match"
  
  # Should find PR #2 via partial match (since "Match" is in both titles, picks first one matching)
  # But here it will log matching PR title
  assert_output_contains "🔍 Checking for matching PR title 'Match'..."
  assert_output_contains "📋 Found PR matching title 'Match', using branch: branch-1"
}

@test "PR title search: exact match requires literal quotes for explicit exact match" {
  mock_gh_pr_list
  
  # Run git-turnouts add '"Exact Match Title"'
  run "$GIT_TURNOUTS_SCRIPT" add '"Exact Match Title"'
  
  assert_output_contains "🔍 Checking for PR with exact title 'Exact Match Title'..."
}

@test "PR title search: shell quotes prefer exact match (improved behavior)" {
  mock_gh_pr_list
  
  # This simulates: git-turnouts add "Exact Match Title"
  # The shell strips the double quotes, so the script receives the raw string.
  # The "improved behavior" ensures that even without literal quotes, 
  # an exact match is prioritized over a partial one (Smart Match).
  run "$GIT_TURNOUTS_SCRIPT" add "Exact Match Title"
  
  # IT LOGS matching PR title and finds the exact one
  assert_output_contains "🔍 Checking for matching PR title 'Exact Match Title'..."
  assert_output_contains "📋 Found PR matching title 'Exact Match Title', using branch: branch-1"
}
