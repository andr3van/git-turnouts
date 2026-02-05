#!/usr/bin/env bats
# Configuration system tests for git-turnouts
# Tests YAML parsing, hierarchical config, and validation

load test_helper

setup() {
  setup_test_repo
}

teardown() {
  teardown_test_repo
}

@test "config show works when config file doesn't exist" {
  # Delete the test config (safe - never touches real config)
  rm -f "$GIT_TURNOUTS_CONFIG"

  run_git_turnouts config show
  assert_success
  assert_output_contains "Worktree Configuration"
  assert_output_contains "Default Behavior"
}

@test "config init creates config file from template" {
  # Find the script directory to locate .config.yml.example
  SCRIPT_DIR=$(dirname "$GIT_TURNOUTS_SCRIPT")

  # Remove test config file if present (safe - never touches real config)
  rm -f "$GIT_TURNOUTS_CONFIG"

  # Ensure example file exists (it should already exist)
  if [ ! -f "$SCRIPT_DIR/.config.yml.example" ]; then
    skip "config.yml.example not found"
  fi

  run_git_turnouts config init
  assert_success
  assert_output_contains "Created configuration file"

  # Verify config file was created in test location
  [ -f "$GIT_TURNOUTS_CONFIG" ]
}

@test "config parsing handles global settings" {
  # Create a test config with global settings (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << 'EOF'
global:
  base_dir: ~/test-worktrees
  open_with: code
EOF

  run_git_turnouts config show
  assert_success
  assert_output_contains "test-worktrees"
  assert_output_contains "code"
}

@test "config accepts any open_with value without validation" {
  # Create test config with any command name (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << 'EOF'
global:
  open_with: my-custom-editor
EOF

  run_git_turnouts config show
  assert_success
  # Should accept any value without warnings (validation happens at runtime)
  assert_output_contains "my-custom-editor"
  assert_output_not_contains "Warning"
  assert_output_not_contains "Invalid"
}

@test "config handles tilde expansion in paths" {
  # Create test config (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << 'EOF'
global:
  base_dir: ~/my-worktrees
EOF

  run_git_turnouts config show
  assert_success
  # Should show the expanded path
  assert_output_contains "my-worktrees"
}

@test "config handles empty file gracefully" {
  # Create empty test config file (safe - never touches real config)
  touch "$GIT_TURNOUTS_CONFIG"

  run_git_turnouts config show
  assert_success
  # Should work with empty config, using defaults
}

@test "config handles comments in YAML" {
  # Create test config with comments (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << 'EOF'
# This is a comment
global:
  # Another comment
  base_dir: ~/worktrees  # Inline comment
EOF

  run_git_turnouts config show
  assert_success
  assert_output_contains "worktrees"
}

@test "config handles copy_files list" {
  # Create test config (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << 'EOF'
global:
  copy_files:
    - .editorconfig
    - .env.example
    - .nvmrc
EOF

  run_git_turnouts config show
  assert_success
  assert_output_contains ".editorconfig" || assert_output_contains "editorconfig"
}

@test "config handles protected_branches list" {
  # Create test config (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << 'EOF'
global:
  protected_branches:
    - develop
    - staging
    - production
EOF

  run_git_turnouts config show
  assert_success
  assert_output_contains "develop" || assert_output_contains "staging"
}

@test "config handles auto_prune boolean values" {
  # Create test config (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << 'EOF'
global:
  auto_prune: false
EOF

  run_git_turnouts config show
  assert_success
  assert_output_contains "false" || assert_output_contains "disabled"
}

@test "config handles consolidated project settings" {
  # Test that all project settings can be defined in one place
  cat > "$GIT_TURNOUTS_CONFIG" << EOF
global:
  base_dir: ~/worktrees
  open_with: code

projects:
  - name: $(basename $TEST_TEMP_DIR)
    base_dir: ~/custom
    open_with: idea
    auto_prune: false
    copy_files:
      - .editorconfig
      - .env.local
    protected_branches:
      - develop
      - staging
EOF

  run_git_turnouts config show
  assert_success
  assert_output_contains "custom"
  assert_output_contains "idea"
}

@test "config project settings override global settings" {
  # Test that project-specific settings override global ones
  cat > "$GIT_TURNOUTS_CONFIG" << EOF
global:
  base_dir: ~/global-worktrees
  open_with: code

projects:
  - name: $(basename $TEST_TEMP_DIR)
    base_dir: ~/project-worktrees
    open_with: idea
EOF

  run_git_turnouts config show
  assert_success
  # Should show project-specific values, not global ones
  assert_output_contains "project-worktrees"
  assert_output_contains "idea"
}
