# Changelog

All notable changes to Git Turnouts will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
