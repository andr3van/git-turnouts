#!/usr/bin/env bats

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
    {"number": 1, "title": "feature-x", "headRefName": "feature-x"},
    {"number": 2, "title": "feature-y", "headRefName": "feature-y"}
  ]'
elif [[ "$1" == "pr" && "$2" == "view" ]]; then
  # For PR number check
  num=$(echo "$@" | grep -oE '[0-9]+' | head -1)
  echo "{\"number\": $num, \"title\": \"Mock PR\", \"headRefName\": \"branch-$num\", \"state\": \"OPEN\", \"baseRefName\": \"master\"}"
fi
MOCK_GH_EOF

  chmod +x "$mock_gh_dir/gh"
  export PATH="$mock_gh_dir:$PATH"
}

@test "copy_files feature automatically copies files to new worktree" {
  mock_gh_pr_list
  # 1. Create some files in the main worktree
  echo "global config" > .global-config
  echo "project config" > .project-config
  mkdir -p .idea
  echo "xml content" > .idea/workspace.xml
  
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  # 2. Configure copy_files in global and project
  create_test_config "
global:
  copy_files:
    - .global-config
projects:
  - name: $PROJECT_NAME
    copy_files:
      - .project-config
      - .idea/workspace.xml
"
  
  # 3. Create a new worktree
  run_git_turnouts add feature-x
  assert_success
  
  # 4. Verify files are copied to the new worktree
  # The default worktree location is ../worktree/{project}/{branch}
  local wt_path="../worktree/$PROJECT_NAME/feature-x"
  
  [ -f "$wt_path/.global-config" ]
  [ "$(cat "$wt_path/.global-config")" = "global config" ]
  
  [ -f "$wt_path/.project-config" ]
  [ "$(cat "$wt_path/.project-config")" = "project config" ]
  
  [ -f "$wt_path/.idea/workspace.xml" ]
  [ "$(cat "$wt_path/.idea/workspace.xml")" = "xml content" ]
}

@test "copy_files handles non-existent files gracefully" {
  mock_gh_pr_list
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
global:
  copy_files:
    - .non-existent-file
"
  
  # Ensure branch exists
  # Actually, don't pre-create to avoid git worktree add -b failure
  # But we need to make sure the PR search works
  run_git_turnouts add feature-y
  assert_success
  
  # Should show warning but succeed
  assert_output_contains "Not found: \.non-existent-file \(skipped\)"
}
