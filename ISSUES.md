# Git Turnouts - Issues & Technical Debt

This document tracks issues, technical debt, and improvements identified during codebase review. These items should be addressed after completing the primary ROADMAP.md features.

**Last Updated**: 2026-01-05

---

## ✅ Recent Completions

### ROADMAP Feature #1: Configuration System - COMPLETED (2026-01-05)
- ✅ Fully implemented hierarchical configuration system
- ✅ Global and project-specific settings for all sections
- ✅ Optional configuration - works without any config file
- ✅ Bash 3.2 compatible implementation
- ✅ Configuration parser with comprehensive validation

**Related Issues Addressed**:
- Issue #7 (Configuration Parsing Maintainability): New parser is well-structured but remains complex - comprehensive testing recommended
- Partially addresses configuration validation needs

### Issue #1: Command Injection Vulnerability - RESOLVED (2026-01-05)
- ✅ Fixed command injection vulnerability in iTerm integration
- ✅ Added proper path escaping using `sed` to escape single quotes
- ✅ Prevents malicious commands from being executed via crafted worktree names
- ✅ Added security documentation in code comments
- ✅ Verified other terminal integrations (Warp, Finder) are already safe

### Issue #2: Missing Dependency Verification - RESOLVED (2026-01-05)
- ✅ Implemented comprehensive `check_dependencies()` function
- ✅ Checks for required dependencies (git, jq) at startup
- ✅ Warns about optional dependencies (gh) with installation links
- ✅ Verifies git version supports worktrees (2.5+)
- ✅ Provides clear, actionable error messages with platform-specific installation guidance
- ✅ Bash 3.2 compatible implementation

### Issue #4: realpath Portability - RESOLVED (2026-01-05)
- ✅ Replaced `realpath` command with portable `get_absolute_path()` function
- ✅ Works on all Unix systems without external dependencies
- ✅ Handles existing/non-existent paths, relative paths, and tilde expansion
- ✅ Bash 3.2 compatible using subshells and pwd
- ✅ Improves compatibility with older macOS versions and various Unix systems

### Issue #5: Configuration File Security - VERIFIED (2026-01-05)
- ✅ Verified `.config.yml` is not tracked by git
- ✅ Confirmed `.gitignore` properly excludes personal config
- ✅ Verified no history of `.config.yml` in repository
- ✅ Only `.config.yml.example` template is tracked
- ✅ Personal configuration remains secure and local

### ROADMAP Feature #9: Automated Testing - COMPLETED (2026-01-05)
- ✅ Implemented comprehensive test suite with bats-core framework
- ✅ Created 54 tests across 4 test files with 100% pass rate
- ✅ Smoke tests (13): Basic script functionality and dependency checks
- ✅ Configuration tests (12): YAML parsing, hierarchical config, validation
- ✅ Command tests (14): All command operations and aliases
- ✅ Integration tests (15): Complex workflows and helper functions
- ✅ Test helper utilities for shared test functionality

### Test Isolation Security Fix - COMPLETED (2026-01-06)
- ✅ Fixed critical security bug where tests were deleting users' real `.config.yml` files
- ✅ Implemented `GIT_TURNOUTS_CONFIG` environment variable for config override
- ✅ Updated test infrastructure to use isolated temporary config directories
- ✅ All 54 tests now run in complete isolation from production config
- ✅ Added automatic cleanup of test config directories
- ✅ Updated all 24 config-related test cases across config.bats and integration.bats

**Security Impact:**
- **Before**: Running tests would `rm -f` the user's actual configuration file
- **After**: Tests use temporary isolated directories that never touch production config
- **Verification**: Confirmed via MD5 hash that real config files remain untouched during test runs

### Documentation: Troubleshooting Section - COMPLETED (2026-01-06)
- ✅ Added comprehensive troubleshooting section to README
- ✅ Covers all common issues: dependencies, permissions, conflicts, PR integration, IDE opening
- ✅ Provides clear solutions with copy-paste commands
- ✅ Documents workarounds for platform-specific issues
- ✅ Addresses Issue #10 requirements

---

## 🔴 Critical Issues

### 1. Command Injection Vulnerability in iTerm Integration
**Severity**: HIGH
**Location**: `git-turnouts:950-962` (updated)
**Status**: ✅ RESOLVED (2026-01-05)

**Description:**
The iTerm opening functionality used `osascript` with string interpolation that could be exploited if `TARGET_DIR` contains malicious characters.

**Previous Vulnerable Code:**
```bash
osascript -e "tell application \"iTerm\"
  create window with default profile
  tell current session of current window
    write text \"cd \\\"$TARGET_DIR\\\"\"
  end tell
end tell"
```

**Risk:**
If a user creates a worktree with specially crafted names, malicious commands could be executed.

**Fix Applied (2026-01-05):**
Implemented proper path escaping using `sed` to escape single quotes:

```bash
iterm)
  echo "🖥️  Opening in iTerm..."
  # Escape single quotes in path to prevent command injection
  # Replaces ' with '\'' which closes the string, adds an escaped quote, and reopens the string
  local ESCAPED_PATH
  ESCAPED_PATH=$(printf '%s' "$TARGET_DIR" | sed "s/'/'\\\\''/g")
  osascript -e "tell application \"iTerm\"
    create window with default profile
    tell current session of current window
      write text \"cd '$ESCAPED_PATH'\"
    end tell
  end tell"
  ;;
```

**Security Improvements:**
- ✅ All user-controlled paths are now properly escaped before being passed to `osascript`
- ✅ Single quote escaping technique prevents command injection
- ✅ Clear comments document the security measure
- ✅ Other terminal integrations (Warp, Finder) already use safe `open` command

---

### 2. Missing Dependency Verification
**Severity**: MEDIUM
**Location**: `git-turnouts:1479-1542` (updated)
**Status**: ✅ RESOLVED (2026-01-05)

**Description:**
The script assumed `gh`, `jq`, and modern `git` were installed but didn't verify this at startup, leading to cryptic errors.

**Previous Impact:**
- Users got cryptic errors if dependencies were missing
- PR integration silently failed without clear messaging
- Poor first-run experience

**Fix Applied (2026-01-05):**
Added comprehensive `check_dependencies()` function that runs at startup:

```bash
check_dependencies() {
  local missing=""
  local has_error=false

  # Check for required commands
  if ! command -v git >/dev/null 2>&1; then
    missing="${missing}git "
    has_error=true
  fi

  if ! command -v jq >/dev/null 2>&1; then
    missing="${missing}jq "
    has_error=true
  fi

  # Check for optional but important commands
  if ! command -v gh >/dev/null 2>&1; then
    echo "⚠️  Warning: GitHub CLI (gh) not found - PR integration will not work"
    echo "   Install from: https://cli.github.com/"
    echo ""
  fi

  # Check git version supports worktrees
  if command -v git >/dev/null 2>&1; then
    if ! git worktree list >/dev/null 2>&1; then
      echo "❌ Error: Your git version doesn't support worktrees"
      echo "   Please upgrade to git 2.5 or newer"
      echo "   Current version: $(git --version)"
      exit 1
    fi
  fi

  # Report missing required dependencies
  if [ "$has_error" = true ]; then
    echo "❌ Error: Missing required dependencies: $missing"
    echo ""
    echo "Please install the missing tools:"
    if [[ "$missing" == *"git"* ]]; then
      echo "  • git: https://git-scm.com/downloads"
    fi
    if [[ "$missing" == *"jq"* ]]; then
      echo "  • jq: https://jqlang.github.io/jq/download/"
      echo "    - macOS: brew install jq"
      echo "    - Linux: apt-get install jq or yum install jq"
    fi
    exit 1
  fi
}
```

**Improvements:**
- ✅ Checks for required dependencies (git, jq) with clear error messages
- ✅ Warns about optional dependencies (gh) with installation instructions
- ✅ Verifies git version supports worktrees (2.5+)
- ✅ Provides platform-specific installation guidance
- ✅ Runs automatically at startup after configuration loading
- ✅ Bash 3.2 compatible (no array usage)

---

## 🟡 High Priority Issues

### 3. Race Condition in Directory Creation
**Severity**: LOW
**Location**: `git-turnouts:660-664`
**Status**: Open

**Description:**
There's a time-of-check-time-of-use (TOCTOU) race condition:

```bash
# Check if target directory already exists
if [ -d "$TARGET_DIR" ]; then
  echo "❌ Error: Directory already exists: $TARGET_DIR"
  exit 1
fi

# ... later ...
git worktree add -B "$BRANCH" "$TARGET_DIR" "origin/$BRANCH"
```

**Impact:**
- Another process could create the directory between the check and `git worktree add`
- Low probability in single-user scenarios
- Could cause confusing errors in automated/parallel usage

**Recommendation:**
- Let `git worktree add` handle the directory existence check
- Catch and handle the error from git instead
- Or use `mkdir -p` with proper error handling

---

### 4. `realpath` Portability Issue
**Severity**: MEDIUM
**Location**: `git-turnouts:97-136, 909` (updated)
**Status**: ✅ RESOLVED (2026-01-05)

**Description:**
Script used `realpath` which isn't available on all Unix systems (notably older macOS versions).

**Previous Code:**
```bash
local BASE_WORKTREE_DIR_ABS=$(realpath "$BASE_WORKTREE_DIR")
```

**Impact:**
- Script failed on systems without `realpath`
- macOS users with older versions encountered errors
- Reduced portability across Unix systems

**Fix Applied (2026-01-05):**
Implemented portable `get_absolute_path()` function using bash-native path resolution:

```bash
# Get absolute path (portable alternative to realpath)
# Works on all Unix systems without requiring the realpath command
get_absolute_path() {
  local path="$1"

  # If path is empty, return empty
  if [ -z "$path" ]; then
    echo ""
    return
  fi

  # Expand tilde to home directory
  case "$path" in
    "~/"*)
      path="${HOME}/${path#\~/}"
      ;;
    "~")
      path="$HOME"
      ;;
  esac

  # If path exists as a directory, cd into it and get pwd
  if [ -d "$path" ]; then
    (cd "$path" && pwd)
  # If path doesn't exist yet, resolve the parent directory
  elif [ -e "$path" ]; then
    # Path exists as a file
    local dir=$(dirname "$path")
    local base=$(basename "$path")
    echo "$(cd "$dir" 2>/dev/null && pwd)/$base"
  else
    # Path doesn't exist yet - resolve what we can
    local dir=$(dirname "$path")
    local base=$(basename "$path")
    if [ -d "$dir" ]; then
      echo "$(cd "$dir" && pwd)/$base"
    else
      # Even parent doesn't exist, return as-is
      # This will be created by mkdir -p later
      echo "$path"
    fi
  fi
}

# Usage (line 909)
local BASE_WORKTREE_DIR_ABS=$(get_absolute_path "$BASE_WORKTREE_DIR")
```

**Improvements:**
- ✅ Works on all Unix systems without external dependencies
- ✅ Handles existing directories, files, and non-existent paths
- ✅ Supports tilde expansion for home directory paths (~/)
- ✅ Bash 3.2 compatible
- ✅ Properly handles relative paths (., .., etc.)
- ✅ Gracefully handles non-existent parent directories

---

### 5. Configuration File Security
**Severity**: LOW
**Location**: `.config.yml`, `.gitignore`
**Status**: ✅ VERIFIED (2026-01-05)

**Description:**
Needed to verify that `.config.yml` with personal paths is not committed to the repository.

**Verification Completed (2026-01-05):**
Confirmed that the configuration setup is already correct and secure:

1. **Git Tracking Status:**
   ```bash
   $ git ls-files | grep "\.config\.yml$"
   # (no output - .config.yml is NOT tracked)

   $ git ls-files | grep config
   .config.yml.example
   # (only the example template is tracked)
   ```

2. **Gitignore Configuration:**
   ```bash
   $ cat .gitignore
   # Personal configuration for all projects (copy from .config.yml.example)
   .config.yml
   ```

3. **Repository History:**
   ```bash
   $ git log --all --full-history -- .config.yml
   # (no output - .config.yml was never committed)
   ```

4. **Current Status:**
   ```bash
   $ git status --short | grep config
   # (no output - no pending changes to config files)
   ```

**Security Status:**
- ✅ `.config.yml` is NOT tracked by git
- ✅ `.config.yml.example` IS tracked (template only)
- ✅ `.gitignore` properly excludes `.config.yml`
- ✅ No history of `.config.yml` in repository
- ✅ Personal configuration remains local only
- ✅ No risk of accidentally committing personal paths

---

## 🟢 Medium Priority Issues

### 6. Error Recovery and Rollback
**Severity**: MEDIUM
**Location**: `cmd_add` function
**Status**: Open

**Description:**
If `git worktree add` fails after creating directories, partial state is left behind:
- Project directory may be created but empty
- No cleanup of partial operations

**Recommendation:**
Add error handling with rollback:

```bash
# After line 705
if ! git worktree add -b "$BRANCH" "$TARGET_DIR" HEAD; then
  echo "❌ Error: Failed to create worktree"
  # Cleanup partial state
  if [ -d "$TARGET_DIR" ]; then
    rm -rf "$TARGET_DIR"
  fi
  exit 1
fi
```

---

### 7. Configuration Parsing Maintainability
**Severity**: LOW
**Location**: `parse_yaml_config` (git-turnouts:130-348)
**Status**: Addressed (Monitoring)

**Update (2026-01-05)**: Configuration system has been refactored to support hierarchical global/project-specific settings.

**Current State:**
- Parser now handles 5 levels of YAML nesting (up from 4)
- Supports hierarchical structure: section.global.key and section.projects[].key
- Added `save_project_data()` helper function to improve organization
- Total parser size: ~220 lines (up from 154 due to extended functionality)

**Improved Structure:**
- ✅ Better organized with clear level handlers (Level 1-5)
- ✅ Separate helper function for project data accumulation
- ✅ Comprehensive validation of all configuration values
- ✅ Handles all configuration sections uniformly

**Current Complexity:**
- 5 levels of indentation handling
- Manual state machine for list vs object parsing
- Helper function reduces code duplication
- Supports both global and project-specific settings

**Recommendation (Updated):**
Given the successful refactoring, recommend **Option C** with emphasis on testing:

**Option C: Keep Current Parser + Add Comprehensive Tests** ✅ RECOMMENDED
- ✅ YAML format is user-friendly and widely understood
- ✅ Current parser successfully handles complex hierarchical structure
- ⚠️ **HIGH PRIORITY**: Add comprehensive tests (ROADMAP #9)
  - Test configuration parsing for all sections
  - Test project-specific overrides
  - Test hierarchical lookup
  - Test edge cases and malformed YAML
- Document supported YAML subset clearly
- Add validation for unsupported features

**Alternative Options** (Lower priority):
- **Option A** (Simpler format): Would require complete rewrite, losing YAML benefits
- **Option B** (External parser): Adds external dependency, complicates installation

**Next Steps:**
1. Implement ROADMAP #9 (Automated Testing) - Focus on configuration parsing
2. Document supported YAML features in `.config.yml.example`
3. Add error messages for unsupported YAML features

---

### 8. No Progress Indication for Long Operations
**Severity**: LOW
**Location**: PR fetch operations, worktree creation
**Status**: Open

**Description:**
Long-running operations (fetching large repos, creating worktrees) have no progress indication.

**Impact:**
- Users may think the tool has hung
- No feedback during network operations

**Recommendation:**
Add progress indicators:
- Use `git fetch --progress` for visible progress
- Add spinner for PR API calls
- Consider implementing ROADMAP feature #16 (Better Output & Formatting)

---

## 📝 Documentation Issues

### 9. ROADMAP Contains Time Estimates
**Severity**: LOW
**Location**: `ROADMAP.md:328-334`
**Status**: Open

**Description:**
The ROADMAP includes specific time estimates which violates project guidelines:

```markdown
**Implementation Phases**:
1. **Phase 1**: Smoke tests (version, help, config parsing) - 1-2 hours
2. **Phase 2**: Core functionality tests (add, remove, list) - 2-3 hours
...
**Total Effort**: ~8-10 hours for comprehensive test suite
```

**Recommendation:**
Remove time estimates and focus on what needs to be done, not when:

```markdown
**Implementation Phases**:
1. **Phase 1**: Smoke tests (version, help, config parsing)
2. **Phase 2**: Core functionality tests (add, remove, list)
...
```

---

### 10. Missing Troubleshooting Section in README
**Severity**: LOW
**Location**: `README.md`
**Status**: ✅ RESOLVED (2026-01-06)

**Description:**
README lacked troubleshooting guide for common issues.

**Resolution:**
Added comprehensive troubleshooting section to README covering:
- ✅ Missing dependencies (gh, jq, git version)
- ✅ Permission issues (worktree directories, config files)
- ✅ Worktree conflicts (directory exists, branch checked out, uncommitted changes)
- ✅ PR integration issues (PR not found, closed PRs, search failures)
- ✅ IDE opening issues (IDE not found, platform-specific)
- ✅ Configuration issues (YAML syntax, config not taking effect)
- ✅ General issues (not a git repo, slow operations)
- ✅ Debug mode instructions
- ✅ Clear solutions with copy-paste commands

The troubleshooting section provides actionable solutions for all common user issues.

---

## 🔵 Low Priority / Future Considerations

### 11. No Logging or Debug Mode
**Severity**: LOW
**Status**: Open

**Description:**
- No way to enable verbose/debug output
- Difficult to troubleshoot issues
- No audit trail of operations

**Recommendation:**
Add debug mode support:

```bash
# Environment variable for debug mode
if [ "${GIT_TURNOUTS_DEBUG:-}" = "1" ]; then
  set -x  # Enable bash debug mode
fi

# Or add --debug flag to commands
```

---

### 12. No Dry-Run Mode
**Severity**: LOW
**Status**: Open

**Description:**
Users can't preview operations before executing them (related to ROADMAP #17).

**Recommendation:**
Implement as part of ROADMAP feature #17 (Dry-Run Mode).

---

### 13. Configuration Schema Validation
**Severity**: LOW
**Status**: Partially Addressed

**Update (2026-01-05)**: Configuration validation has been implemented as part of the configuration system refactor.

**Implemented Validation:**
- ✅ `validate_configuration()` function validates all settings after parsing
- ✅ Validates `defaults.open_with` values (idea, code, iterm, warp, finder)
- ✅ Validates `remove.auto_prune` values (true, false, yes, no, 1, 0)
- ✅ Normalizes boolean values automatically
- ✅ Validates base_dir parent directories exist
- ✅ Provides clear warnings for invalid values with fallback to defaults
- ✅ Validates both global and project-specific settings

**Current Validation Coverage:**
```bash
# From validate_configuration() function (lines 350-436)
- defaults.global.open_with validation
- defaults.projects[].open_with validation
- worktree.global.base_dir parent directory check
- remove.global.auto_prune normalization
- remove.projects[].auto_prune normalization
```

**Still Missing:**
- ⚠️ Pre-parsing YAML structure validation
- ⚠️ Detection of unsupported YAML features
- ⚠️ Validation of copy_files paths exist in main worktree
- ⚠️ Validation of protected_branches format

**Recommendation (Updated):**
Current validation is good for user-provided values. Additional validation would be nice-to-have:

**Phase 1** (Current): ✅ DONE
- Value validation for user settings
- Fallback to defaults for invalid values

**Phase 2** (Future enhancement):
```bash
validate_yaml_structure() {
  local config_file="$1"

  # Check for common YAML syntax errors
  # Check for unsupported features (anchors, references, etc.)
  # Validate section names are recognized

  if [ $? -ne 0 ]; then
    echo "⚠️  Warning: Config file may have formatting issues"
    echo "   Run: git-turnouts config show"
    echo "   To verify your configuration"
  fi
}
```

**Priority**: LOW (current validation is sufficient for MVP)

---

### 14. No Support for Git Hooks Integration
**Severity**: LOW
**Status**: Planned (ROADMAP #19)

**Description:**
Related to ROADMAP feature #19 (Hooks System). Users can't run custom setup scripts automatically.

**Recommendation:**
Implement as part of ROADMAP once core features are stable.

---

## 📊 Code Quality Metrics

### Current State:
- **Total Lines of Code**: 1,157 lines (bash script)
- **Configuration Parser**: 154 lines (13% of codebase)
- **Test Coverage**: 0% (no tests)
- **Documented Functions**: ~80% have inline comments
- **Error Handling**: Good (uses `set -e`, validates inputs)
- **Bash Compatibility**: Excellent (3.2+ compatible)

### Targets After Addressing Issues:
- **Test Coverage**: 80%+ for core functions
- **Configuration Parser**: ✅ Refactored (2026-01-05) - Testing recommended
- **Security Audit**: ✅ Command injection fixed (2026-01-05) - Continue auditing other inputs
- **Documentation**: 100% of public functions

---

## 🎯 Recommended Action Plan

### Phase 1: Critical Security & Stability ✅ COMPLETE
1. ~~Fix command injection vulnerability (#1)~~ - ✅ DONE (2026-01-05)
2. ~~Add dependency checks (#2)~~ - ✅ DONE (2026-01-05)
3. ~~Fix realpath portability issue (#4)~~ - ✅ DONE (2026-01-05)
4. ~~Verify .config.yml security (#5)~~ - ✅ VERIFIED (2026-01-05)

### Phase 2: Testing Infrastructure ✅ COMPLETE
1. ~~Implement ROADMAP feature #9 (Automated Testing)~~ - ✅ DONE (2026-01-05)
   - ✅ Added comprehensive test suite (54 tests)
   - ✅ Configuration parser tests
   - ✅ Integration tests
   - ✅ Hierarchical configuration lookup tests
   - ✅ Project-specific override tests
2. Set up CI/CD pipeline (GitHub Actions) - **OPTIONAL**
3. Add shellcheck to testing workflow - **OPTIONAL**

### Phase 3: Code Quality ✅ PARTIALLY COMPLETE
1. ~~Add configuration validation (#13)~~ - ✅ DONE (2026-01-05)
2. Add error recovery/rollback (#6) - TODO
3. Fix race condition (#3) - LOW PRIORITY
4. Add debug/logging mode (#11) - TODO

### Phase 4: Documentation 📝
1. ~~Remove time estimates from ROADMAP (#9)~~ - Can be done anytime
2. Add troubleshooting section (#10) - MEDIUM PRIORITY
3. Document supported YAML subset in `.config.yml.example` - LOW PRIORITY

### Phase 5: Feature Development 🚀
Continue with ROADMAP features after Phase 1 & 2 are complete:
- Feature #3: Shell Completions
- Feature #5: Enhanced List Command
- Feature #6: Clean/Prune Command

---

## 📊 Current Status Summary

**Completed**:
- ✅ ROADMAP Feature #1 (Configuration System) - 2026-01-05
- ✅ ROADMAP Feature #9 (Automated Testing) - 2026-01-05
- ✅ Issue #1 (Command Injection Vulnerability) - 2026-01-05
- ✅ Issue #2 (Missing Dependency Verification) - 2026-01-05
- ✅ Issue #4 (realpath Portability) - 2026-01-05
- ✅ Issue #5 (Configuration File Security) - 2026-01-05
- ✅ Issue #10 (Documentation - Troubleshooting) - 2026-01-06
- ✅ Issue #13 (Configuration Validation) - Partially addressed
- ✅ Issue #7 (Configuration Parser) - Refactored and improved
- ✅ **Test Isolation Security Fix** - 2026-01-06

**🎉 MVP Ready Status**:
- ✅ All critical security issues resolved
- ✅ Comprehensive test suite with 100% pass rate
- ✅ Test isolation implemented (no risk to user configs)
- ✅ Complete documentation with troubleshooting guide
- ✅ Manual end-to-end verification completed
- 🚀 **Ready for v1.0.0 release**

**High Priority (Post-MVP)**:
1. 🟡 Issue #6 (Error recovery) - Improve robustness
2. 🚀 ROADMAP Feature #3 (Shell Completions) - User experience
3. 🚀 ROADMAP Feature #2 (Interactive/Fuzzy Search) - User experience

**Medium Priority**:
- (All medium priority items promoted or completed)

**Low Priority**:
- 🟢 Issue #3 (Race condition)
- 🟢 Issue #11 (Debug mode)

---

## Contributing

When addressing these issues:
1. Create a branch for each issue: `issue/N-short-description`
2. Reference this issue number in commits: `Fix #N: description`
3. Add tests for any bug fixes
4. Update this document when issues are resolved

---

## Issue Status Legend

- **Open**: Not yet addressed
- **In Progress**: Currently being worked on
- **Resolved**: Fixed and tested
- **Wontfix**: Decided not to address
- **Deferred**: Postponed to future release

---

**Note**: This document should be reviewed and updated regularly as issues are addressed and new ones are discovered.
