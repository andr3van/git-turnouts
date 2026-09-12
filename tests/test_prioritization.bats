#!/usr/bin/env bats
load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "PR title search: prioritizes exact match over partial even if partial is first in list" {
  local mock_gh_dir="$TEST_TEMP_DIR/.mock/bin"
  mkdir -p "$mock_gh_dir"

  cat > "$mock_gh_dir/gh" << 'MOCK_GH_EOF'
#!/bin/bash
if [[ "$*" == *"pr list"* ]]; then
  echo '[
    {"number": 2, "title": "My Title Extended", "headRefName": "branch-2"},
    {"number": 1, "title": "My Title", "headRefName": "branch-1"}
  ]'
fi
MOCK_GH_EOF
  chmod +x "$mock_gh_dir/gh"
  export PATH="$mock_gh_dir:$PATH"

  # Search for "My Title". 
  # Without prioritization, head -n1 would pick branch-2.
  # With prioritization, it should pick branch-1.
  run "$GIT_TURNOUTS_SCRIPT" add "My Title"
  
  assert_output_contains "📋 Found PR matching title 'My Title', using branch: branch-1"
}
