#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "list-based settings combine global and project-specific values (additive)" {
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
global:
  protected_branches:
    - global-p
projects:
  - name: $PROJECT_NAME
    protected_branches:
      - project-p
"
  
  run_git_turnouts config show
  assert_success
  
  # The output should show both global and project values
  # and the effective list should contain both
  assert_output_contains "global-p"
  assert_output_contains "project-p"
  
  # For protected branches, they are shown space-separated in effective
  assert_output_contains "Effective:.*main.*master.*global-p.*project-p"
}

@test "scalar settings override global with project-specific values (replacement)" {
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
global:
  base_dir: ~/global-base
  open_with: code
  auto_prune: true
projects:
  - name: $PROJECT_NAME
    base_dir: ~/project-base
    open_with: idea
    auto_prune: false
"
  
  run_git_turnouts config show
  assert_success
  
  # Base Directory should show override
  assert_output_contains "Global:.*global-base"
  assert_output_contains "Project:.*project-base.*ACTIVE OVERRIDE"
  assert_output_contains "Effective:.*project-base"
  
  # Open With should show override
  assert_output_contains "Global:  code"
  assert_output_contains "Project: idea.*ACTIVE OVERRIDE"
  assert_output_contains "Effective: idea"
  
  # Auto Prune should show override
  assert_output_contains "Global:  true"
  assert_output_contains "Project: false.*ACTIVE OVERRIDE"
  assert_output_contains "Effective: false"
}

@test "copy_files list combines global and project-specific values" {
  PROJECT_NAME=$(basename "$TEST_TEMP_DIR")
  
  create_test_config "
global:
  copy_files:
    - .global-file
projects:
  - name: $PROJECT_NAME
    copy_files:
      - .project-file
"
  
  run_git_turnouts config show
  assert_success
  
  assert_output_contains ".global-file"
  assert_output_contains ".project-file"
  assert_output_contains "Effective:.*.global-file.*.project-file"
}

@test "hard_protected_branches list combines global and project-specific values" {
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
  
  assert_output_contains "global-hard"
  assert_output_contains "project-hard"
  assert_output_contains "Effective:.*main.*master.*global-hard.*project-hard"
}
