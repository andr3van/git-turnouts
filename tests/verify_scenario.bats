#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "verify --clean proceeds after declining deletion of worktree with changes" {
  # 1. Create multiple branches and worktrees
  mkdir -p worktrees
  for b in branch-a branch-b branch-c branch-d branch-e; do
    git branch "$b" master
    git worktree add "worktrees/$b" "$b" -q
  done

  # 2. Make them all "stale" by ensuring no remote branches exist
  # (In our test repo there's no remote, so they should be considered stale)
  
  # 3. Add uncommitted changes to branch-c
  echo "changes" >> "worktrees/branch-c/README.md"

  # 4. Run verify --clean
  # We need to provide:
  # 'y' for the initial batch confirmation
  # 'n' for branch-c's uncommitted changes confirmation
  # Note: branches are processed in the order they appear in 'git worktree list'
  # which should be alphabetical by path: branch-a, branch-b, branch-c, branch-d, branch-e
  
  run bash -c "printf 'y\nn\n' | $GIT_TURNOUTS_SCRIPT verify --clean"
  
  # branch-a, branch-b, branch-d, branch-e should be GONE
  # branch-c should still EXIST
  
  assert_output_contains "Skipped removal of 'branch-c'"
  assert_output_contains "Worktree 'branch-d' removed successfully"
  assert_output_contains "Worktree 'branch-e' removed successfully"

  [ ! -d "worktrees/branch-a" ]
  [ ! -d "worktrees/branch-b" ]
  [ -d "worktrees/branch-c" ]
  [ ! -d "worktrees/branch-d" ]
  [ ! -d "worktrees/branch-e" ]
}
