#!/usr/bin/env bats
# Command tests for git-turnouts
# Tests list, config, and other basic commands

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "list command works in empty repository" {
  run_git_turnouts list
  assert_success
  assert_output_contains "Git Worktrees"
}

@test "list command shows main worktree" {
  run_git_turnouts list
  assert_success
  # Should show at least the main worktree
  assert_output_contains "$TEST_TEMP_DIR"
}

@test "list command with ls alias works" {
  run_git_turnouts ls
  assert_success
  assert_output_contains "Git Worktrees"
}

@test "config show command works" {
  run_git_turnouts config show
  assert_success
  assert_output_contains "Configuration"
}

@test "config show displays current project" {
  run_git_turnouts config show
  assert_success
  assert_output_contains "Current Project"
}

@test "config show displays worktree configuration" {
  run_git_turnouts config show
  assert_success
  assert_output_contains "Worktree Configuration"
}

@test "config show displays default behavior" {
  run_git_turnouts config show
  assert_success
  assert_output_contains "Default Behavior"
}

@test "config show displays branch protection" {
  run_git_turnouts config show
  assert_success
  assert_output_contains "Branch Protection"
}

@test "config show displays removal behavior" {
  run_git_turnouts config show
  assert_success
  assert_output_contains "Removal Behavior"
}

@test "config command without subcommand defaults to show" {
  run_git_turnouts config
  assert_success
  assert_output_contains "Configuration"
}

@test "config with invalid subcommand shows usage" {
  run_git_turnouts config invalid
  assert_success  # Shows usage, doesn't fail
  assert_output_contains "Usage"
}

@test "add command without arguments shows usage" {
  run_git_turnouts add
  assert_failure
  assert_output_contains "Usage" || assert_output_contains "Error"
}

@test "remove command without arguments shows usage" {
  run_git_turnouts remove
  assert_failure
  assert_output_contains "Usage"
}

@test "remove command with rm alias shows usage when no args" {
  run_git_turnouts rm
  assert_failure
  assert_output_contains "Usage"
}
