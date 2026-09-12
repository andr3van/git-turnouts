#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "verify respects soft-protected branches (skipped unless --force)" {
  local current_branch=$(git symbolic-ref --short HEAD)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
projects:
  - name: $PROJECT_NAME
    protected_branches:
      - protected-soft
"
  
  # 1. Create a branch and a worktree for it
  git checkout -b protected-soft
  git checkout "$current_branch"
  mkdir -p worktrees
  git worktree add worktrees/wt-soft protected-soft
  
  # 2. Run verify --clean without --force
  # In our test repo there's no remote, so it would normally be considered stale
  # but since it's soft-protected, it should be skipped by verify --clean by default
  
  run_git_turnouts verify --clean --yes --verbose
  assert_success
  assert_output_contains "PROTECTED - will not be removed"
  
  # Verify worktree still exists
  [ -d "worktrees/wt-soft" ]
  
  # 3. Run verify --clean WITH --force
  run_git_turnouts verify --clean --force --yes
  assert_success
  assert_output_contains "Worktree 'protected-soft' removed successfully"
  
  # Verify worktree is removed
  [ ! -d "worktrees/wt-soft" ]
}

@test "verify respects hard-protected branches (skipped even with --force)" {
  local current_branch=$(git symbolic-ref --short HEAD)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
projects:
  - name: $PROJECT_NAME
    hard_protected_branches:
      - protected-hard
"
  
  # 1. Create a branch and a worktree for it
  git checkout -b protected-hard
  git checkout "$current_branch"
  mkdir -p worktrees
  git worktree add worktrees/wt-hard protected-hard
  
  # 2. Run verify --clean WITH --force
  # Hard-protected branches should NEVER be removed
  
  run_git_turnouts verify --clean --force --yes
  assert_success
  assert_output_contains "Hard-protected \(cannot be removed\)"
  
  # Verify worktree still exists
  [ -d "worktrees/wt-hard" ]
}

@test "verify verbose mode indicates protection status" {
  local current_branch=$(git symbolic-ref --short HEAD)
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
projects:
  - name: $PROJECT_NAME
    protected_branches:
      - soft-p
    hard_protected_branches:
      - hard-p
"
  
  git checkout -b soft-p
  git checkout -b hard-p
  git checkout "$current_branch"
  mkdir -p worktrees
  git worktree add worktrees/soft-p soft-p
  git worktree add worktrees/hard-p hard-p
  
  run_git_turnouts verify --verbose
  assert_success
  assert_output_contains "soft-p.*PROTECTED"
  assert_output_contains "hard-p.*PROTECTED"
  assert_output_contains "🛡️"
}
