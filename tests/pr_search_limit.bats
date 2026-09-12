#!/usr/bin/env bats
# Tests for PR search with large limit

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

mock_gh_pagination() {
  local mock_gh_dir="$TEST_TEMP_DIR/.mock/bin"
  mkdir -p "$mock_gh_dir"

  cat > "$mock_gh_dir/gh" << 'MOCK_GH_EOF'
#!/bin/bash
if [[ "$*" == *"pr list"* ]]; then
  if [[ "$*" == *"--limit 1000"* ]]; then
    # Return a list containing the target
    echo '[
      {"number": 1, "title": "First PR", "headRefName": "branch-1"},
      {"number": 101, "title": "Target PR", "headRefName": "target-branch"}
    ]'
  else
    # Should not be called with other limits now
    echo '[]'
  fi
elif [[ "$1" == "pr" && "$2" == "view" ]]; then
  echo '{"number": 1, "title": "Mock", "headRefName": "mock", "state": "OPEN", "baseRefName": "master"}'
fi
MOCK_GH_EOF

  chmod +x "$mock_gh_dir/gh"
  export PATH="$mock_gh_dir:$PATH"
}

@test "PR search: finds PR deep in the list with unified fetch" {
  mock_gh_pagination
  
  # Search for "Target PR"
  # It should be found in the single fetch with limit 1000.
  run "$GIT_TURNOUTS_SCRIPT" add "Target PR"
  
  assert_success
  assert_output_contains "🔍 Checking for matching PR title 'Target PR'..."
  assert_output_contains "📋 Found PR matching title 'Target PR', using branch: target-branch"
}

@test "PR search: finds PR at beginning of list with unified fetch" {
  mock_gh_pagination
  
  run "$GIT_TURNOUTS_SCRIPT" add "First PR"
  
  assert_success
  assert_output_contains "📋 Found PR matching title 'First PR', using branch: branch-1"
}
