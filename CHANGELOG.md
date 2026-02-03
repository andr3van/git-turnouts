# Changelog

All notable changes to Git Turnouts will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Verify Command**: New `verify` command to check worktrees against remote branches
  - `git-turnouts verify` - Check all worktrees against remote (read-only, safe)
  - `git-turnouts verify --verbose` - Show detailed status for each worktree
  - `git-turnouts verify --clean` - Remove worktrees with deleted remote branches (with confirmation)
  - `git-turnouts verify --clean --dry-run` - Preview what would be removed without actually removing
  - `git-turnouts verify --clean --yes` - Remove without confirmation prompt
- **Remote Branch Verification**: Automatically fetches and checks if remote branches still exist
- **Safety Features for Verification**:
  - Warns about unpushed commits before removal
  - Checks for uncommitted changes and prompts for confirmation
  - Protected branches are respected during cleanup
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
- **Configuration System**: Updated configuration format so it can be consolidated where all project settings are defined in one place
  - Replaced multi-section format with cleaner consolidated format
  - All project settings (base_dir, open_with, auto_prune, copy_files, protected_branches) now under single project entry
  - Simpler YAML structure: `global:` for global settings, `projects:` for project-specific settings

### Documentation
- Added "Verifying Worktrees" section to README.md
- Added "Checking Dependencies" section to README.md with examples and tool descriptions
- Completely rewritten `.config.yml.example` with consolidated format and comprehensive examples
- Updated README.md configuration section with consolidated format examples
- Added comprehensive examples for verify command usage
- Added comprehensive examples for config check command usage
- Updated ROADMAP.md with completed Remote Branch Sync & Cleanup feature
- Updated ROADMAP.md with completed Tool Dependency Check Command feature

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
