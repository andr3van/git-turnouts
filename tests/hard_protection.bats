#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "is_hard_protected_branch respects global configuration" {
  source "$GIT_TURNOUTS_SCRIPT"
  
  create_test_config "
global:
  hard_protected_branches:
    - global-hard
"
  
  load_configuration 2>/dev/null || true
  
  run is_hard_protected_branch "global-hard"
  [ "$status" -eq 0 ]
  
  run is_hard_protected_branch "main"
  [ "$status" -eq 0 ]
  
  run is_hard_protected_branch "other"
  [ "$status" -eq 1 ]
}

@test "is_hard_protected_branch respects project-specific configuration" {
  source "$GIT_TURNOUTS_SCRIPT"
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
projects:
  - name: $PROJECT_NAME
    hard_protected_branches:
      - project-hard
"
  
  load_configuration 2>/dev/null || true
  
  run is_hard_protected_branch "project-hard"
  [ "$status" -eq 0 ]
  
  run is_hard_protected_branch "main"
  [ "$status" -eq 0 ]
}

@test "remove -f cannot remove configured hard-protected branches" {
  local current_branch=$(git symbolic-ref --short HEAD)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
projects:
  - name: $PROJECT_NAME
    hard_protected_branches:
      - absolutely-protected
"
  
  # Create a branch and a worktree for it
  git checkout -b absolutely-protected
  git checkout "$current_branch"
  mkdir -p worktrees
  git worktree add worktrees/wt-hard absolutely-protected
  
  # Try to remove with force (should still fail)
  run_git_turnouts remove --force absolutely-protected
  assert_failure
  assert_output_contains "Error: Cannot remove hard-protected branch"
  
  # Verify worktree still exists
  [ -d "worktrees/wt-hard" ]
}

@test "remove (no force) fails for configured hard-protected branches" {
  local current_branch=$(git symbolic-ref --short HEAD)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
projects:
  - name: $PROJECT_NAME
    hard_protected_branches:
      - absolutely-protected
"
  
  # Create a branch and a worktree for it
  git checkout -b absolutely-protected
  git checkout "$current_branch"
  mkdir -p worktrees
  git worktree add worktrees/wt-hard absolutely-protected
  
  # Try to remove without force
  run_git_turnouts remove absolutely-protected
  assert_failure
  assert_output_contains "Error: Cannot remove hard-protected branch"
  
  # Verify worktree still exists
  [ -d "worktrees/wt-hard" ]
}

@test "verify --clean --force skips configured hard-protected branches" {
  local current_branch=$(git symbolic-ref --short HEAD)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
projects:
  - name: $PROJECT_NAME
    hard_protected_branches:
      - stay-put
"
  
  # Create a branch and a worktree for it
  git checkout -b stay-put
  git checkout "$current_branch"
  mkdir -p worktrees
  git worktree add worktrees/wt-stay stay-put
  
  # The branch 'stay-put' doesn't have a remote, so it would normally be considered stale
  # but since it's hard-protected, it should be skipped by verify --clean even with --force
  
  run_git_turnouts verify --clean --force --yes
  assert_success
  assert_output_contains "Hard-protected \(cannot be removed\)"
  
  # Verify worktree still exists
  [ -d "worktrees/wt-stay" ]
}

@test "config show displays hard-protected branches" {
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
global:
  hard_protected_branches:
    - global-hard
projects:
  - name: $PROJECT_NAME
    hard_protected_branches:
      - project-hard
"
  
  run_git_turnouts config show
  assert_success
  assert_output_contains "Hard-protected Branches"
  assert_output_contains "global-hard"
  assert_output_contains "project-hard"
  assert_output_contains "Effective:.*main.*master.*global-hard.*project-hard"
}
