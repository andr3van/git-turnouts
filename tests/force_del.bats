#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "is_hard_protected_branch identifies critical branches" {
  source "$GIT_TURNOUTS_SCRIPT"
  
  run is_hard_protected_branch "main"
  [ "$status" -eq 0 ]
  
  run is_hard_protected_branch "master"
  [ "$status" -eq 0 ]
  
  run is_hard_protected_branch "other-branch"
  [ "$status" -eq 1 ]
}

@test "remove -f can remove a soft-protected branch" {
  local current_branch=$(git symbolic-ref --short HEAD)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  create_test_config "
projects:
  - name: $PROJECT_NAME
    protected_branches:
      - protected-branch
"
  
  # Create a worktree for protected-branch
  git checkout -b protected-branch
  git checkout "$current_branch"
  mkdir -p worktrees
  git worktree add worktrees/wt-protected protected-branch
  
  # Try to remove without force (should fail)
  run_git_turnouts remove protected-branch
  assert_failure
  assert_output_contains "Error: Cannot remove protected branch"
  
  # Try to remove with force (should succeed)
  run_git_turnouts remove --force protected-branch
  assert_success
  assert_output_contains "Worktree 'protected-branch' removed successfully"
  assert_output_contains "Removed 'protected-branch' from protected_branches in project '$PROJECT_NAME'"
  
  # Verify config was updated
  run grep "protected-branch" "$GIT_TURNOUTS_CONFIG"
  [ "$status" -ne 0 ]
}

@test "remove -f cannot remove hard-protected branches" {
  local current_branch=$(git symbolic-ref --short HEAD)
  # Switch to another branch so we can add the current one as a worktree
  git checkout -b temp-branch
  mkdir -p worktrees
  git worktree add worktrees/wt-hard "$current_branch"
  
  run_git_turnouts remove --force "$current_branch"
  assert_failure
  assert_output_contains "Error: Cannot remove hard-protected branch"
}

@test "verify --clean --force cleans up stale protected worktrees" {
  local current_branch=$(git symbolic-ref --short HEAD)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  create_test_config "
projects:
  - name: $PROJECT_NAME
    protected_branches:
      - stale-protected
"
  
  # 1. Create a worktree
  git checkout -b stale-protected
  git checkout "$current_branch"
  mkdir -p worktrees
  git worktree add worktrees/wt-stale stale-protected
  
  # It is considered stale because origin/stale-protected does not exist
  
  # Verify --clean (without force) - should skip it
  run_git_turnouts verify --clean --yes
  assert_success
  assert_output_contains "Protected .stale.: 1"
  assert_output_contains "nothing to remove"
  
  # Verify --clean --force - should remove it and clean config
  run_git_turnouts verify --clean --force --yes
  assert_success
  assert_output_contains "Removing stale worktrees"
  assert_output_contains "Removed 'stale-protected' from protected_branches in project '$PROJECT_NAME'"
  
  # Verify config was updated
  run grep "stale-protected" "$GIT_TURNOUTS_CONFIG"
  [ "$status" -ne 0 ]
}

@test "verify detects stale config entries" {
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  create_test_config "
projects:
  - name: $PROJECT_NAME
    protected_branches:
      - non-existent-branch
"
  
  run_git_turnouts verify
  assert_success
  assert_output_contains "Stale Config: 1"
  assert_output_contains "Found 1 stale entries in project '$PROJECT_NAME' configuration"
  
  # Try cleaning without force
  run_git_turnouts verify --clean --yes
  assert_success
  assert_output_contains "Use --force to remove protected worktrees and stale config entries"
  
  # Try cleaning with force
  run_git_turnouts verify --clean --force --yes
  assert_success
  assert_output_contains "Cleaning up stale configuration entries"
  assert_output_contains "Removed 'non-existent-branch' from protected_branches in project '$PROJECT_NAME'"
  
  # Verify config was updated
  run grep "non-existent-branch" "$GIT_TURNOUTS_CONFIG"
  [ "$status" -ne 0 ]
}

@test "global protection is NOT detected as stale configuration" {
  create_test_config "
global:
  protected_branches:
    - global-stale
"
  
  run_git_turnouts verify
  assert_success
  assert_output_not_contains "Stale Config: 1"
  assert_output_contains "All worktrees and configuration are up to date"
}

@test "remove --force cleans up stale config entry even if no worktree exists" {
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  create_test_config "
projects:
  - name: $PROJECT_NAME
    protected_branches:
      - stale-branch
"
  
  # Try to remove without force (should just warn about missing worktree)
  run_git_turnouts remove stale-branch
  assert_failure
  assert_output_contains "No worktree found"
  run grep "stale-branch" "$GIT_TURNOUTS_CONFIG"
  [ "$status" -eq 0 ]
  
  # Try to remove with force (should cleanup config)
  run_git_turnouts remove --force stale-branch
  assert_success
  assert_output_contains "Found 'stale-branch' in protected_branches for project '$PROJECT_NAME'"
  assert_output_contains "Removed 'stale-branch' from protected_branches in project '$PROJECT_NAME'"
  
  # Verify config was updated
  run grep "stale-branch" "$GIT_TURNOUTS_CONFIG"
  [ "$status" -ne 0 ]
}
