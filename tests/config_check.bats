#!/usr/bin/env bats
# Config check command tests

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "config check command works" {
  run_git_turnouts config check
  assert_success
  assert_output_contains "Tool Dependency Status"
}

@test "config check shows required tools section" {
  run_git_turnouts config check
  assert_success
  assert_output_contains "Required Tools:"
}

@test "config check shows optional tools section" {
  run_git_turnouts config check
  assert_success
  assert_output_contains "Optional Tools:"
}

@test "config check shows purposes in default output" {
  run_git_turnouts config check
  assert_success
  # Purposes should be shown in parentheses in default output
  assert_output_contains "Version control"
  assert_output_contains "Script execution"
  assert_output_contains "JSON parsing"
}

@test "config check with --verbose shows detailed info" {
  run_git_turnouts config check --verbose
  assert_success
  assert_output_contains "Purpose:"
  assert_output_contains "Path:"
}

@test "config check with --required shows only required tools" {
  run_git_turnouts config check --required
  assert_success
  assert_output_contains "Required Tools:"
  [[ ! "$output" =~ "Optional Tools:" ]]
}

@test "config check with --optional shows only optional tools" {
  run_git_turnouts config check --optional
  assert_success
  assert_output_contains "Optional Tools:"
  [[ ! "$output" =~ "Required Tools:" ]]
}

@test "config check fails when both --required and --optional used" {
  run_git_turnouts config check --required --optional
  assert_failure
  assert_output_contains "Cannot use both"
}

@test "config check detects git" {
  run_git_turnouts config check
  assert_success
  assert_output_contains "git"
  assert_output_contains "✅"
}

@test "config check detects jq" {
  run_git_turnouts config check
  assert_success
  assert_output_contains "jq"
}

@test "config check detects bash" {
  run_git_turnouts config check
  assert_success
  assert_output_contains "bash"
}

@test "config check shows gh if available" {
  run_git_turnouts config check
  assert_success
  assert_output_contains "gh"
}

@test "config check with invalid flag shows error" {
  run_git_turnouts config check --invalid
  assert_failure
  assert_output_contains "Unknown option"
}

@test "config check --help shows usage" {
  run_git_turnouts config check --help
  assert_success
  assert_output_contains "Usage"
}

@test "config check shows version numbers" {
  run_git_turnouts config check
  assert_success
  # Should contain version-like patterns
  [[ "$output" =~ [0-9]+\.[0-9]+ ]]
}

@test "config check verbose shows full paths" {
  run_git_turnouts config check --verbose
  assert_success
  # Should contain absolute paths
  assert_output_contains "/"
}

@test "config check shows summary section" {
  run_git_turnouts config check
  assert_success
  assert_output_contains "Status:"
}

@test "config check shows success message for required tools" {
  run_git_turnouts config check
  assert_success
  assert_output_contains "All required tools are installed"
}

@test "config check verbose shows purpose for each tool" {
  run_git_turnouts config check --verbose
  assert_success
  # Should show purposes for git, bash, jq
  assert_output_contains "Version control"
  assert_output_contains "Script execution"
  assert_output_contains "JSON parsing"
}

@test "config check required only shows status complete" {
  run_git_turnouts config check --required
  assert_success
  assert_output_contains "Status:"
}

@test "config check optional only shows optional tools" {
  run_git_turnouts config check --optional
  assert_success
  # Should show optional tools (gh and shellcheck)
  assert_output_contains "gh"
  assert_output_contains "shellcheck"
}
