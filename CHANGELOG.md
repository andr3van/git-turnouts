# Changelog

All notable changes to Git Turnouts will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Verify Command**: New `verify` command to check worktrees against remote branches
  - `git-turnouts verify` - Check all worktrees against remote (read-only, safe)
  - `git-turnouts verify --verbose` - Show detailed status for each worktree including protection status
  - `git-turnouts verify --clean` - Remove worktrees with deleted remote branches (with confirmation)
  - `git-turnouts verify --clean --dry-run` - Preview what would be removed without actually removing
  - `git-turnouts verify --clean --yes` - Remove without confirmation prompt
- **Remote Branch Verification**: Automatically fetches and checks if remote branches still exist
- **Protected Branch Support in Verify**: Protected branches are now fully respected in verify command
  - Active protected branches show "(PROTECTED)" indicator in verbose output
  - Protected branches with deleted remotes are marked with 🛡️ in verbose output
  - Protected stale worktrees are completely skipped from removal (both worktree and branch preserved)
  - Separate summary count shows protected stale branches
  - Clear indication of protected branches in cleanup preview
  - Consistent protection status display regardless of branch being active or stale
- **Safety Features for Verification**:
  - Warns about unpushed commits before removal
  - Checks for uncommitted changes and prompts for confirmation
  - Protected branches are fully respected during cleanup (worktree + branch preserved)
  - Skips the main/primary worktree automatically
- **Config Check Command**: New `config check` subcommand to verify tool dependencies
  - `git-turnouts config check` - Check all required and optional tools
  - `git-turnouts config check --verbose` - Show detailed information including full paths and purposes
  - `git-turnouts config check --required` - Show only required tools (git, bash, jq)
  - `git-turnouts config check --optional` - Show only optional tools (gh, shellcheck)
  - Displays installation status with checkmarks (✅/❌), version numbers, and purposes
  - Tool purposes shown in default output to help users understand each tool's role
  - Only checks tools currently used by git-turnouts (no future/planned tools)
  - Verbose mode adds full installation paths
  - Provides installation guidance for missing tools
  - Exit code 1 if any required tools are missing, 0 if all required tools present

### Changed
- Enhanced `remove_worktree()` function with uncommitted changes detection
- Refactored `remove_worktree()` to be a global helper function (usable by both remove and verify commands)
- Updated help text to include verify command and config check subcommand with their options
- **Protected Branch Enforcement in Remove Command**: The `remove` command now fully respects branch protection configuration
  - Protected branches are completely refused for removal (both worktree and branch preserved)
  - Consistent behavior with `verify --clean` command
  - Clear error message with guidance when attempting to remove protected branches
- **Configuration System**: Updated configuration format so it can be consolidated where all project settings are defined in one place
  - Replaced multi-section format with cleaner consolidated format
  - All project settings (base_dir, open_with, auto_prune, copy_files, protected_branches) now under single project entry
  - Simpler YAML structure: `global:` for global settings, `projects:` for project-specific settings
- **Open With Behavior**: Removed hardcoded "idea" default for `open_with` setting
  - Default behavior changed from automatic opening in IntelliJ IDEA to opt-in (no automatic opening unless configured)
  - `open_with` now accepts ANY command/application name without validation against a whitelist
  - Implemented defensive programming for tool execution with multiple fallback approaches
  - Shows helpful tip message when no `open_with` is configured: "💡 Tip: To automatically open worktrees, use --open <app> or configure open_with in .config.yml"
  - Users can now use any editor/tool (idea, code, subl, vim, emacs, cursor, zed, etc.) without code changes
  - ⚠️ **BREAKING CHANGE**: Users relying on the hardcoded "idea" default will need to add `open_with: idea` to their `.config.yml` to restore automatic opening behavior

### Documentation
- Added "Verifying Worktrees" section to README.md
- Added "Checking Dependencies" section to README.md with examples and tool descriptions
- Completely rewritten `.config.yml.example` with consolidated format and comprehensive examples
- Updated README.md configuration section with consolidated format examples
- Added comprehensive examples for verify command usage
- Added comprehensive examples for config check command usage
- Updated ROADMAP.md with completed Remote Branch Sync & Cleanup feature
- Updated ROADMAP.md with completed Tool Dependency Check Command feature
- Updated `.config.yml.example` to document that `open_with` accepts any command (not just specific tools)
- Fixed README.md to show correct configuration structure (`global:` instead of nested `defaults:` section)
- Updated README.md to reflect no default automatic opening behavior
- Updated all configuration examples to use generic command names instead of hardcoded tool references
- Added "Protected Branches in Verify" section to README.md explaining protection behavior for both active and stale branches
- Updated `protected_branches` configuration description to clarify it applies to both 'remove' and 'verify --clean' commands
- Consolidated README configuration section by removing redundant individual sections (Default Behavior, Branch Protection, Removal Behavior)
- Enhanced "Example 4: Complete Configuration Reference" with comprehensive comments for all settings and default values

### Fixed
- Configuration documentation inconsistencies between code and examples
- Test case updated to verify that `open_with` accepts any value without validation warnings

## [1.0.1] - 2026-01-09

### Fixed
- **Symlink Resolution Issue**: Fixed critical bug where configuration files were not being loaded when git-turnouts was installed via symlink (recommended installation method)
  - Configuration file (`.config.yml`) was not being loaded from the correct directory
  - Example configuration file (`.config.yml.example`) could not be found for `config init` command
  - Global settings like `worktree.base_dir` were being ignored, falling back to auto-detection
  - This affected both `load_configuration()` and `cmd_config()` functions

### Changed
- Updated version number from 1.0.0 to 1.0.1
- Improved symlink resolution logic to properly follow symlinks and find the actual script directory
- Configuration now loads correctly regardless of installation method (symlink or PATH)

### Technical Details
The script now uses a proper symlink resolution loop that follows symlink chains:
```bash
local script_path="${BASH_SOURCE[0]}"
while [ -L "$script_path" ]; do
  local link_target=$(readlink "$script_path")
  if [[ "$link_target" == /* ]]; then
    script_path="$link_target"
  else
    script_path="$(dirname "$script_path")/$link_target"
  fi
done
local script_dir="$(cd "$(dirname "$script_path")" && pwd)"
```

### Impact
- Users who installed git-turnouts via symlink (as recommended in README) can now use custom configuration
- Global `worktree.base_dir` setting is now properly respected
- `git-turnouts config init` and `git-turnouts config show` commands now work correctly with symlinked installations

## [1.0.0] - 2026-01-06

### Added
- Initial public release of Git Turnouts
- PR-aware worktree creation with GitHub integration
- Smart branch resolution (local, remote, and new branches)
- Organized workspace with structured hierarchy
- Automatic IDE/application opening support (IntelliJ IDEA, VS Code, iTerm, Warp, Finder)
- Bulk worktree removal capabilities
- Protected branch safeguards (main/master)
- YAML-based configuration system
- File copying support for worktree setup
- Comprehensive documentation and examples

[1.0.1]: https://github.com/andr3van/git-turnouts/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/andr3van/git-turnouts/releases/tag/v1.0.0
