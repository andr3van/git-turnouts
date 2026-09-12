# Git Turnouts

> Switch between branches like a pro - your Git branch switching yard

A powerful command-line tool for managing Git worktrees with intelligent GitHub Pull Request integration. Just like railroad turnouts route trains between tracks, Git Turnouts helps you seamlessly switch between multiple branches and work contexts.

**Currently Supported Platforms:** macOS, Linux (Unix-like systems)

## Why "Turnouts"?

In railroad terminology, a **turnout** (also called a "switch" or "point") is a mechanical installation that guides trains from one track to another. This perfectly mirrors what Git Turnouts does - it helps you smoothly switch between different development tracks (branches) without the friction of stashing, committing unfinished work, or losing context.

**Key metaphor parallels:**
- 🛤️ Multiple tracks = Multiple branches
- 🚂 Switching trains = Switching work contexts
- 🔀 Railroad junction = Git worktree workspace
- 📍 Track routing = Branch management

## Features

- **PR-Aware Worktree Creation**: Automatically detect and checkout GitHub PRs by number or title
- **Smart Branch Resolution**: Intelligently handles local, remote, and new branches
- **Organized Workspace**: Creates worktrees in a structured hierarchy
- **Automatic Opening**: Open worktrees in your IDE (IntelliJ IDEA, VS Code) or other applications (iTerm, Warp, Finder)
- **Bulk Removal**: Remove multiple worktrees efficiently in a single command
- **Configurable Branch Protection**: Protects critical branches (main, master, etc.) with both soft and hard protection levels
- **Safety Checks**: Prevents branch conflicts and duplicate worktrees
- **Progress Tracking**: Shows detailed progress and summary statistics

## Requirements

- **Unix-like OS** (macOS, Linux)
- **Git** (2.5+)
- **Bash** (3.2+)
- **jq** (required for PR integration and config)
- **GitHub CLI (gh)** (optional, for PR features)

Use `git-turnouts config check` to verify your environment.

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/andr3van/git-turnouts.git
   cd git-turnouts
   ```

2. Make the script executable:
   ```bash
   chmod +x git-turnouts
   ```

3. Add to your PATH (choose one method):

   **Option A: Symlink to a directory in your PATH**
   ```bash
   ln -s "$(pwd)/git-turnouts" /usr/local/bin/git-turnouts
   ```

   **Option B: Add to PATH in your shell profile**
   ```bash
   # Add to ~/.bashrc, ~/.zshrc, etc.
   export PATH="$PATH:/path/to/git-turnouts"
   ```

4. Verify installation:
   ```bash
   git-turnouts --version
   ```

## Checking Dependencies

Verify your installation and get guidance for missing tools:

```bash
git-turnouts config check [--verbose | --required | --optional]
```

**Required:** `git` (2.5+), `bash` (3.2+), `jq`.
**Optional:** `gh` (GitHub PR integration), `shellcheck` (development).

## Usage

### Creating Worktrees

#### Basic Usage
```bash
# Create worktree with branch name
git-turnouts add feature-branch

# Create worktree with different folder and branch names
git-turnouts add my-folder feature-branch
```

#### PR Integration
```bash
# Checkout PR by number
git-turnouts add 7113

# Search for PR by title (prefers exact match, falls back to partial)
git-turnouts add "feature name"

# Force exact match only (using literal quotes)
git-turnouts add '"Exact PR Title"'

# Custom folder name with PR title search
git-turnouts add my-folder "PR Title"
```

#### Open in Different Applications
```bash
# Open in your editor (no automatic opening by default)
git-turnouts add feature-x --open code

# Open in a terminal
git-turnouts add feature-x --open iterm

# Use any command/application that accepts a directory path
```

### Removing Worktrees

```bash
# Remove a single worktree
git-turnouts remove feature-branch

# Remove multiple worktrees (bulk operation)
git-turnouts remove feature-1 feature-2 feature-3

# Force remove a protected branch (soft-protected)
git-turnouts remove --force protected-branch

# Short alias
git-turnouts rm feature-branch
```

### Listing Worktrees

```bash
# List all worktrees
git-turnouts list

# Short alias
git-turnouts ls
```

### Verifying Worktrees

Check for stale worktrees tracking deleted remote branches and clean them up:

```bash
# Preview stale worktrees (safe, read-only)
git-turnouts verify

# Clean up stale worktrees (with confirmation)
git-turnouts verify --clean

# Clean up including protected stale worktrees
git-turnouts verify --clean --force
```

**Key Features:**
- Detects worktrees whose remote branches were deleted (e.g., after PR merge).
- Respects **protected branches** (skips them unless `--force` is used).
- Warns about unpushed commits or uncommitted changes.
- Default **hard-protection** for `main`, `master`, and the repository's default branch ensures they are never removed.

## How It Works

### Worktree Structure

Worktrees are organized in a clean hierarchy:
```
~/projects/
├── my-project/              # Main repository
└── worktree/
    └── my-project/          # Project-specific worktrees
        ├── feature-1/
        ├── feature-2/
        └── 7113/            # PR-based worktree
```

### PR Detection Flow

1. **PR Number**: (e.g., `7113`) Fetches PR, blocks creation if merged.
2. **PR Title**: Searches open PRs (exact then partial match). Use `' "Title" '` for forced exact match.
3. **Standard Branch**: Falls back to Git branch resolution or creates a new one from HEAD.

### Safety Features

- Prevents checking out the same branch in multiple worktrees
- Protects critical branches from deletion (with configurable soft and hard protection)
- Validates target directories don't exist
- Handles merged/closed PRs appropriately

## Examples

### Example 1: Work on Multiple Features
```bash
# Create worktrees for different features (one at a time)
git-turnouts add feature-authentication
git-turnouts add feature-dashboard
git-turnouts add feature-api

# Work on them simultaneously in different IDE windows
```

### Example 2: Review PRs
```bash
# Quickly checkout PR #7113 for review
git-turnouts add 7113 --open code

# When done reviewing
git-turnouts remove 7113
```

### Example 3: Bulk Cleanup
```bash
# Remove multiple completed feature branches at once
git-turnouts remove feature-1 feature-2 feature-3 pr-7113

# Progress tracking shows: [1/4], [2/4], [3/4], [4/4]
```

## Configuration

Git Turnouts uses a single YAML configuration file that manages all your projects. The configuration file lives in the git-turnouts installation directory.

### Configuration Quick Start

1. **Initialize:** `git-turnouts config init` (creates `.config.yml` in script directory)
2. **View:** `git-turnouts config show`
3. **Configure:** Edit `.config.yml` to set your preferences.

### Key Options

- `base_dir`: Global or project-specific worktree location.
- `hard_protected_branches`: Branches that can never be removed.
- `protected_branches`: Branches that require `--force` to remove.
- `open_with`: Command to automatically open new worktrees (e.g., `code`).
- `auto_prune`: Automatically prune after removing worktrees (true/false).
- `copy_files`: List of files to copy to new worktrees (e.g., `.env`).

See `.config.yml.example` for a full reference.

---

### 💡 Pro Tip: Automatic File Copying

The `copy_files` feature automatically copies essential files (like `.env`, `.editorconfig`) from your main repository to every new worktree.

**Why use it?**
- **Instant Setup**: New worktrees are immediately ready to run.
- **No Manual Copying**: Stop manually recreating `.env` files with local credentials.
- **Consistency**: All worktrees use the same local configuration.

**Example:**
```yaml
global:
  copy_files:
    - .env
    - .env.local
    - .editorconfig
```

---

### Configuration Reference

```yaml
global:
  base_dir: ~/worktrees           # Base directory for all projects
  hard_protected_branches: [prod] # Cannot be removed even with --force
  protected_branches: [develop]   # Require --force to remove
  open_with: code                # Command to open worktrees (optional)
  auto_prune: true               # Auto-prune after removing (default: true)
  copy_files: [.env, .nvmrc]     # Files to copy to new worktrees

projects:
  - name: my-app
    base_dir: ~/custom/my-app      # Overrides global base_dir
    copy_files: [.env.local]       # Combines with global copy_files
```

**Hierarchy:**
- **Scalar settings** (`base_dir`, `open_with`, `auto_prune`): Project overrides global.
- **List settings** (`hard_protected_branches`, `protected_branches`, `copy_files`): Project combines with global (additive).

### Notes

- **Optional**: Works perfectly without any configuration.
- **Centralized**: Single `.config.yml` in the script directory manages all projects.
- **Automated**: Project names are auto-detected from the repository directory.
- **Extensible**: Add `open_with` commands that are in your system `PATH`.

## Troubleshooting

### Dependencies
- **Missing `gh` or `jq`**: Install them using your package manager (`brew`, `apt`, `yum`). Run `gh auth login` for GitHub features.
- **Git version**: Requires 2.5+. Upgrade your git client if worktrees are not supported.

### Permissions
- **"Permission denied"**: Ensure the `base_dir` and the `git-turnouts` script directory are writable.
- **Config issues**: Use `export GIT_TURNOUTS_CONFIG=~/.config/git-turnouts/config.yml` if the default location is not writable.

### Worktrees
- **"Directory already exists"**: Remove the stale directory or use a custom name: `git-turnouts add <custom-name> <branch>`.
- **"Branch already checked out"**: A branch can only be in one worktree. Use `git worktree list` to find it.
- **"Uncommitted changes"**: Commit or stash changes before removing a worktree.

### Application Opening
- **IDE not opening**: Ensure the command (e.g., `code`, `idea`) is in your `PATH`.
- **Linux GUI**: Automatic opening of GUI apps on Linux may require manual setup.

For more details, run `git-turnouts config check --verbose` or open a [GitHub Issue](https://github.com/andr3van/git-turnouts/issues).

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT License](LICENSE)

## Why Git Turnouts?

Created to streamline context-switching. Like a railroad turnout, it guides you between tracks (branches) without the friction of stashing or losing momentum.
