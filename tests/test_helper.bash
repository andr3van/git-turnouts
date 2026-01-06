# Test helper utilities for git-turnouts tests
# This file contains shared setup, teardown, and helper functions

# Get the absolute path to the git-turnouts script
GIT_TURNOUTS_SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/git-turnouts"

# Temporary directory for test repositories
TEST_TEMP_DIR=""

# Temporary directory for test config files (isolated from real config)
TEST_CONFIG_DIR=""

# Setup function - create a temporary test repository
setup_test_repo() {
  # Create a unique temporary directory for this test
  TEST_TEMP_DIR=$(mktemp -d)

  # Create isolated config directory for testing (never touch real config)
  TEST_CONFIG_DIR=$(mktemp -d)
  export GIT_TURNOUTS_CONFIG="$TEST_CONFIG_DIR/.config.yml"

  # Initialize a git repository in the temp directory
  cd "$TEST_TEMP_DIR"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create an initial commit so we have a valid repository
  echo "# Test Repository" > README.md
  git add README.md
  git commit -q -m "Initial commit"
}

# Teardown function - clean up temporary test repository
teardown_test_repo() {
  if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
    cd /
    rm -rf "$TEST_TEMP_DIR"
  fi

  # Clean up isolated config directory
  if [ -n "$TEST_CONFIG_DIR" ] && [ -d "$TEST_CONFIG_DIR" ]; then
    rm -rf "$TEST_CONFIG_DIR"
  fi

  # Unset config override to ensure it doesn't leak between tests
  unset GIT_TURNOUTS_CONFIG
}

# Helper: Create a test configuration file in isolated test directory
create_test_config() {
  local config_content="$1"
  # Write to the isolated test config (never touches real config)
  cat > "$GIT_TURNOUTS_CONFIG" << EOF
$config_content
EOF
}

# Helper: Run git-turnouts command in test repository
run_git_turnouts() {
  run "$GIT_TURNOUTS_SCRIPT" "$@"
}

# Helper: Assert output contains a string
assert_output_contains() {
  local expected="$1"
  if [[ ! "$output" =~ $expected ]]; then
    echo "Expected output to contain: $expected"
    echo "Actual output: $output"
    return 1
  fi
}

# Helper: Assert output does not contain a string
assert_output_not_contains() {
  local unexpected="$1"
  if [[ "$output" =~ $unexpected ]]; then
    echo "Expected output to NOT contain: $unexpected"
    echo "Actual output: $output"
    return 1
  fi
}

# Helper: Assert command succeeded
assert_success() {
  if [ "$status" -ne 0 ]; then
    echo "Expected success (status 0), got status $status"
    echo "Output: $output"
    return 1
  fi
}

# Helper: Assert command failed
assert_failure() {
  if [ "$status" -eq 0 ]; then
    echo "Expected failure (non-zero status), got status 0"
    echo "Output: $output"
    return 1
  fi
}

# Helper: Create a mock gh command that always succeeds
mock_gh_success() {
  local mock_gh_dir="$TEST_TEMP_DIR/.mock/bin"
  mkdir -p "$mock_gh_dir"

  cat > "$mock_gh_dir/gh" << 'MOCK_GH_EOF'
#!/bin/bash
# Mock gh command for testing
case "$1" in
  pr)
    case "$2" in
      view)
        echo "Test PR #123"
        echo "Title: Test PR Title"
        echo "Author: testuser"
        exit 0
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
  *)
    exit 0
    ;;
esac
MOCK_GH_EOF

  chmod +x "$mock_gh_dir/gh"
  export PATH="$mock_gh_dir:$PATH"
}

# Helper: Create a mock jq command
mock_jq() {
  local mock_jq_dir="$TEST_TEMP_DIR/.mock/bin"
  mkdir -p "$mock_jq_dir"

  cat > "$mock_jq_dir/jq" << 'MOCK_JQ_EOF'
#!/bin/bash
# Mock jq command for testing
echo '{"test": "value"}'
MOCK_JQ_EOF

  chmod +x "$mock_jq_dir/jq"
  export PATH="$mock_jq_dir:$PATH"
}
