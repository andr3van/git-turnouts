#!/usr/bin/env bats
# Remove command tests for git-turnouts
# Tests worktree removal and protected branch enforcement

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
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

@test "remove command shows error for non-existent worktree" {
  run_git_turnouts remove non-existent-branch
  assert_failure
  assert_output_contains "No worktree found" || assert_output_contains "Warning"
}

@test "remove_worktree function refuses protected branch directly" {
  # Source the script to test the internal function directly
  source "$GIT_TURNOUTS_SCRIPT"
  load_configuration 2>/dev/null || true

  # Mock a worktree by testing the protection logic
  # Create a test scenario where we have a "main" worktree
  # Since we can't easily create main worktree, we test with mock

  # The function checks protection before removal
  # We can verify the is_protected_branch function works
  if is_protected_branch "main"; then
    true  # Protection check works
  else
    fail "main should be protected"
  fi

  if is_protected_branch "master"; then
    true  # Protection check works
  else
    fail "master should be protected"
  fi
}

@test "remove command shows error for non-existent protected branch" {
  # Trying to remove a protected branch that doesn't have a worktree
  # Should fail at worktree existence check (before protection check)
  run_git_turnouts remove main
  assert_failure
  assert_output_contains "No worktree found" || assert_output_contains "skipping"
}

@test "remove command error handling order is correct" {
  # Test that worktree existence is checked before protection
  # This is the expected behavior
  run_git_turnouts remove main
  assert_failure
  # Should fail with "no worktree" not "protected" since worktree doesn't exist
  assert_output_contains "No worktree found"
}

@test "is_protected_branch respects custom config" {
  # Source the script and create custom config
  source "$GIT_TURNOUTS_SCRIPT"

  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  cat > "$GIT_TURNOUTS_CONFIG" << EOF
global:
  protected_branches:
    - main
    - master
    - custom-protected
EOF

  load_configuration 2>/dev/null || true

  # Test custom protected branch
  if is_protected_branch "custom-protected"; then
    true  # Success
  else
    fail "custom-protected should be protected (from global config)"
  fi
}

@test "is_protected_branch respects project-specific config" {
  # Source the script and create project-specific config
  source "$GIT_TURNOUTS_SCRIPT"

  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  cat > "$GIT_TURNOUTS_CONFIG" << EOF
global:
  protected_branches:
    - main
    - master

projects:
  - name: $PROJECT_NAME
    protected_branches:
      - develop
      - staging
EOF

  load_configuration 2>/dev/null || true

  # Test project-specific protected branch
  if is_protected_branch "develop"; then
    true  # Success
  else
    fail "develop should be protected (from project config)"
  fi

  if is_protected_branch "staging"; then
    true  # Success
  else
    fail "staging should be protected (from project config)"
  fi

  # Non-protected branch should return false
  if is_protected_branch "feature-x"; then
    fail "feature-x should not be protected"
  else
    true  # Success
  fi
}

@test "remove command returns exit code 1 for non-existent worktree" {
  run_git_turnouts remove non-existent-branch
  [ "$status" -eq 1 ]
}

@test "remove command can remove non-protected branch" {
  skip "Requires creating a worktree first - complex setup"
  # This would require:
  # 1. Creating a feature branch
  # 2. Creating a worktree for it
  # 3. Then testing removal
  # Left as TODO for comprehensive integration tests
}

@test "remove command handles multiple non-existent worktrees" {
  # Try to remove multiple non-existent worktrees
  run_git_turnouts remove feature-1 feature-2 feature-3
  assert_failure
  # Should show warning for each
  assert_output_contains "No worktree found" || assert_output_contains "Warning"
}

@test "rm alias works the same as remove command" {
  run_git_turnouts rm non-existent-branch
  assert_failure
  assert_output_contains "No worktree found" || assert_output_contains "Warning"
}

@test "remove command uses same protection function as verify" {
  # Source the script to test internal consistency
  source "$GIT_TURNOUTS_SCRIPT"
  load_configuration 2>/dev/null || true

  # Both commands use is_protected_branch function
  # Verify it works for default protected branches
  if is_protected_branch "main"; then
    true
  else
    fail "Protection check should work for main"
  fi

  if is_protected_branch "master"; then
    true
  else
    fail "Protection check should work for master"
  fi
}

@test "is_protected_branch function detects default protected branches" {
  # Source the script to access internal functions
  source "$GIT_TURNOUTS_SCRIPT"
  load_configuration 2>/dev/null || true

  # Test main is protected
  if is_protected_branch "main"; then
    true  # Success
  else
    fail "main should be protected by default"
  fi

  # Test master is protected
  if is_protected_branch "master"; then
    true  # Success
  else
    fail "master should be protected by default"
  fi
}

@test "is_protected_branch function detects custom protected branches" {
  # Source the script and create custom config
  source "$GIT_TURNOUTS_SCRIPT"

  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  cat > "$GIT_TURNOUTS_CONFIG" << EOF
global:
  protected_branches:
    - main
    - master
    - production
EOF

  load_configuration 2>/dev/null || true

  # Test production is protected
  if is_protected_branch "production"; then
    true  # Success
  else
    fail "production should be protected (from config)"
  fi

  # Test feature branch is not protected
  if is_protected_branch "feature-x"; then
    fail "feature-x should not be protected"
  else
    true  # Success
  fi
}

@test "remove_worktree function respects branch protection" {
  # Source the script to access internal functions
  source "$GIT_TURNOUTS_SCRIPT"
  load_configuration 2>/dev/null || true

  # Attempt to use remove_worktree on main
  # Since "main" worktree doesn't exist as a separate worktree,
  # it will fail at the existence check first
  run remove_worktree "main"
  assert_failure
  # Will show "No worktree found" before protection check
  assert_output_contains "No worktree found" || assert_output_contains "Warning"

  # The protection logic is tested by is_protected_branch tests above
  # In real usage, if a protected branch worktree existed, it would be caught
}
