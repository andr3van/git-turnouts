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

@test "config show works without config file" {
  # Delete the test config (safe - never touches real config)
  rm -f "$GIT_TURNOUTS_CONFIG"

  run_git_turnouts config show
  assert_success
  assert_output_contains "Configuration"
}

@test "config show displays global defaults" {
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
worktree:
  global:
    base_dir: ~/test-worktrees

defaults:
  global:
    open_with: code
EOF

  run_git_turnouts config show
  assert_success
  assert_output_contains "test-worktrees"
  assert_output_contains "code"
}

@test "config parsing handles project-specific settings" {
  # Create test config with project-specific settings (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << EOF
worktree:
  projects:
    - name: $(basename $TEST_TEMP_DIR)
      base_dir: ~/custom-worktrees

defaults:
  projects:
    - name: $(basename $TEST_TEMP_DIR)
      open_with: idea
EOF

  run_git_turnouts config show
  assert_success
  assert_output_contains "custom-worktrees"
  assert_output_contains "idea"
}

@test "config validates open_with values" {
  # Create test config with invalid open_with value (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << 'EOF'
defaults:
  global:
    open_with: invalid-editor
EOF

  run_git_turnouts config show
  assert_success
  # Should show warning about invalid value
  assert_output_contains "Warning" || assert_output_contains "invalid"
}

@test "config handles tilde expansion in paths" {
  # Create test config (safe - never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << 'EOF'
worktree:
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
worktree:
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
worktree:
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
protection:
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
remove:
  global:
    auto_prune: false
EOF

  run_git_turnouts config show
  assert_success
  assert_output_contains "false" || assert_output_contains "disabled"
}
