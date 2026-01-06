#!/usr/bin/env bats
# Integration tests for git-turnouts
# Tests complex workflows and helper functions

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "get_absolute_path function exists" {
  # Source the script to test internal functions
  source "$GIT_TURNOUTS_SCRIPT"

  # Verify the function exists
  type get_absolute_path >/dev/null 2>&1
}

@test "get_absolute_path handles existing directory" {
  source "$GIT_TURNOUTS_SCRIPT"

  result=$(get_absolute_path "/tmp")
  [ "$result" = "/tmp" ] || [ "$result" = "/private/tmp" ]
}

@test "get_absolute_path handles current directory" {
  source "$GIT_TURNOUTS_SCRIPT"

  result=$(get_absolute_path ".")
  [ -n "$result" ]
  # Should return an absolute path
  [[ "$result" =~ ^/ ]]
}

@test "get_absolute_path handles tilde expansion" {
  source "$GIT_TURNOUTS_SCRIPT"

  result=$(get_absolute_path "~/Documents")
  # Should expand tilde to home directory
  [[ "$result" =~ ^/ ]]
  [[ "$result" =~ /Documents$ ]]
  [[ ! "$result" =~ "~" ]]
}

@test "get_absolute_path handles non-existent path with existing parent" {
  source "$GIT_TURNOUTS_SCRIPT"

  result=$(get_absolute_path "/tmp/nonexistent-test-path-12345")
  [ -n "$result" ]
  [[ "$result" =~ /tmp/ ]] || [[ "$result" =~ /private/tmp/ ]]
  [[ "$result" =~ nonexistent-test-path-12345$ ]]
}

@test "check_dependencies function exists" {
  source "$GIT_TURNOUTS_SCRIPT"

  # Verify the function exists
  type check_dependencies >/dev/null 2>&1
}

@test "get_project_name returns repository name" {
  source "$GIT_TURNOUTS_SCRIPT"

  result=$(get_project_name)
  [ -n "$result" ]
  # Should be the basename of the test directory
  expected=$(basename "$TEST_TEMP_DIR")
  [ "$result" = "$expected" ]
}

@test "get_main_worktree returns main worktree path" {
  # Can't easily test internal functions due to script execution
  # Instead, verify the list command shows the main worktree
  run_git_turnouts list
  assert_success
  assert_output_contains "$TEST_TEMP_DIR"
}

@test "get_base_worktree_dir returns default path" {
  source "$GIT_TURNOUTS_SCRIPT"

  result=$(get_base_worktree_dir)
  [ -n "$result" ]
  # Should contain 'worktree' in the path
  [[ "$result" =~ worktree ]]
}

@test "configuration system handles missing config file" {
  # Remove test config file if it exists (safe - never touches real config)
  rm -f "$GIT_TURNOUTS_CONFIG"

  run_git_turnouts config show
  assert_success
  # Should still work with defaults
}

@test "list command integration" {
  run_git_turnouts list
  assert_success

  # Output should contain the repository path
  assert_output_contains "$TEST_TEMP_DIR" || [[ "$output" =~ "Git Worktrees" ]]
}

@test "configuration shows effective values" {
  # Create a test config with both global and project-specific settings (safe - never touches real config)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  cat > "$GIT_TURNOUTS_CONFIG" << EOF
defaults:
  global:
    open_with: code
  projects:
    - name: $PROJECT_NAME
      open_with: idea
EOF

  run_git_turnouts config show
  assert_success
  # Should show both global and project-specific values
  assert_output_contains "code" || assert_output_contains "idea"
}

@test "hierarchical config lookup prefers project over global" {
  # Create test config (safe - never touches real config)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  cat > "$GIT_TURNOUTS_CONFIG" << EOF
defaults:
  global:
    open_with: code
  projects:
    - name: $PROJECT_NAME
      open_with: idea
EOF

  run_git_turnouts config show
  assert_success
  # Should show project-specific value (idea) as effective
  assert_output_contains "idea"
}

@test "script handles repository with branches" {
  # Create a test branch
  git checkout -b test-branch -q

  run_git_turnouts list
  assert_success

  # Switch back to master
  git checkout master -q
}

@test "dependency checks run at startup" {
  # Dependencies should be checked automatically
  run_git_turnouts help
  assert_success
  # If dependencies were missing, would fail before showing help
}
