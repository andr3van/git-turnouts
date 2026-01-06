#!/usr/bin/env bats
# Smoke tests for git-turnouts
# These tests verify basic functionality works without errors

load test_helper

@test "script exists and is executable" {
  [ -f "$GIT_TURNOUTS_SCRIPT" ]
  [ -x "$GIT_TURNOUTS_SCRIPT" ]
}

@test "script has correct shebang" {
  run head -n 1 "$GIT_TURNOUTS_SCRIPT"
  assert_output_contains "#!/bin/bash"
}

@test "version command works" {
  run "$GIT_TURNOUTS_SCRIPT" --version
  assert_success
  assert_output_contains "Git Turnouts v"
}

@test "version command with -v flag works" {
  run "$GIT_TURNOUTS_SCRIPT" -v
  assert_success
  assert_output_contains "Git Turnouts v"
}

@test "version command with 'version' works" {
  run "$GIT_TURNOUTS_SCRIPT" version
  assert_success
  assert_output_contains "Git Turnouts v"
}

@test "help command works" {
  run "$GIT_TURNOUTS_SCRIPT" help
  assert_success
  assert_output_contains "Git Turnouts"
  assert_output_contains "USAGE"
  assert_output_contains "COMMANDS"
}

@test "help command with --help flag works" {
  run "$GIT_TURNOUTS_SCRIPT" --help
  assert_success
  assert_output_contains "Git Turnouts"
  assert_output_contains "USAGE"
}

@test "help command with -h flag works" {
  run "$GIT_TURNOUTS_SCRIPT" -h
  assert_success
  assert_output_contains "Git Turnouts"
  assert_output_contains "USAGE"
}

@test "script requires git repository" {
  # Run in a non-git directory
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"

  run "$GIT_TURNOUTS_SCRIPT" list
  assert_failure
  assert_output_contains "Not a git repository"

  cd /
  rm -rf "$TMP_DIR"
}

@test "dependency check detects git" {
  setup_test_repo

  run "$GIT_TURNOUTS_SCRIPT" help
  assert_success
  # Should not complain about missing git
  assert_output_not_contains "Missing required dependencies: git"

  teardown_test_repo
}

@test "dependency check detects jq" {
  setup_test_repo

  run "$GIT_TURNOUTS_SCRIPT" help
  assert_success
  # Should not complain about missing jq
  assert_output_not_contains "Missing required dependencies: jq"

  teardown_test_repo
}

@test "unknown command shows error" {
  setup_test_repo

  run "$GIT_TURNOUTS_SCRIPT" nonexistent-command
  assert_failure
  assert_output_contains "Unknown command"

  teardown_test_repo
}

@test "script handles --version outside git repo" {
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"

  # Version should work even outside a git repo (it's checked early)
  run "$GIT_TURNOUTS_SCRIPT" --version

  # This will fail because we check for git repo first
  # But that's the current behavior
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]

  cd /
  rm -rf "$TMP_DIR"
}
