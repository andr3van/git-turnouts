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
  
  # Should find PR #1 via partial match (picks first one matching)
  assert_output_contains "🔍 Checking for matching PR title 'Match'..."
  assert_output_contains "📋 Found PR matching title 'Match', using branch: branch-1"
}

@test "PR title search: exact match requires literal quotes for explicit exact match" {
  mock_gh_pr_list
  
  # Run git-turnouts add '"Exact Match Title"'
  run "$GIT_TURNOUTS_SCRIPT" add '"Exact Match Title"'
  
  assert_output_contains "🔍 Checking for PR with exact title 'Exact Match Title'..."
  assert_output_contains "📋 Found PR with exact title 'Exact Match Title', using branch: branch-1"
}

@test "PR title search: forced exact match fails if only partial match exists" {
  mock_gh_pr_list
  
  # Run git-turnouts add '"Partial Match"' (there is no PR with EXACT title "Partial Match")
  # It should fall back to standard branch resolution, which will fail if branch doesn't exist
  run "$GIT_TURNOUTS_SCRIPT" add '"Partial Match"'
  
  # Should NOT find it because we forced exact match
  assert_output_not_contains "📋 Found PR"
  assert_output_contains "No PR found with exact title 'Partial Match', using standard branch resolution"
}

@test "PR title search: shell quotes prefer exact match (Smart Match)" {
  mock_gh_pr_list
  
  # This simulates: git-turnouts add "Exact Match Title"
  # Even though "Match" is also in the partial match title, 
  # the script should prioritize the exact match.
  run "$GIT_TURNOUTS_SCRIPT" add "Exact Match Title"
  
  assert_output_contains "🔍 Checking for matching PR title 'Exact Match Title'..."
  assert_output_contains "📋 Found PR matching title 'Exact Match Title', using branch: branch-1"
}

@test "PR title search: fallback to partial match when no exact match" {
  mock_gh_pr_list
  
  # Search for something that only matches partially
  run "$GIT_TURNOUTS_SCRIPT" add "Partial"
  
  assert_output_contains "🔍 Checking for matching PR title 'Partial'..."
  assert_output_contains "📋 Found PR matching title 'Partial', using branch: branch-2"
}

@test "PR number search works" {
  mock_gh_pr_list
  
  # Ensure branch exists locally to avoid fetch error
  git checkout -b branch-1 -q
  git checkout master -q

  # Run git-turnouts add 1
  run "$GIT_TURNOUTS_SCRIPT" add 1
  
  assert_output_contains "Detected PR number: #1"
  assert_output_contains "📋 Found PR #1.*using branch: branch-1"
}
