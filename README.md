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
- **Protected Branches**: Automatically protects main/master branches from deletion
- **Safety Checks**: Prevents branch conflicts and duplicate worktrees
- **Progress Tracking**: Shows detailed progress and summary statistics

## Requirements

- **Unix-like OS** (macOS, Linux)
- **Git** (2.5 or newer, with worktree support)
- **Bash** (3.2+)
- **jq** (for JSON parsing) - [Install jq](https://jqlang.github.io/jq/download/)
- **GitHub CLI (gh)** (optional, for PR integration features) - [Install gh](https://cli.github.com/)

**Platform Notes:**
- **Core features** (worktree management, PR integration): Fully supported on macOS and Linux
- **Automatic opening** (`--open` flag): Currently uses macOS-specific commands. On Linux, worktrees are created successfully but automatic opening in applications is not yet supported.

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

# Search for PR by title (partial match)
git-turnouts add "feature name"

# Search for PR by exact title
git-turnouts add "Exact PR Title"

# Custom folder name with PR title search
git-turnouts add my-folder "PR Title"
```

#### Open in Different Applications
```bash
# Open in VS Code (default is IntelliJ IDEA)
git-turnouts add feature-x --open code

# Open in iTerm
git-turnouts add feature-x --open iterm

# Available options: idea, code, iterm, warp, finder
```

### Removing Worktrees

```bash
# Remove a single worktree
git-turnouts remove feature-branch

# Remove multiple worktrees (bulk operation)
git-turnouts remove feature-1 feature-2 feature-3

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

1. **PR Number**: If input is numeric (e.g., `7113`), directly fetches that PR
   - Checks PR state (open/closed/merged)
   - **Merged PRs**: Blocks creation (branch likely deleted)
   - **Closed PRs**: Allows creation with warning (branch may still exist)
   - **Open PRs**: Proceeds normally
   - Uses PR's branch name
   - Fetches latest changes from remote

2. **PR Title Search**: Searches open PRs for matching titles
   - Quoted strings = exact match
   - Unquoted strings = partial match
   - Uses PR's branch if found

3. **Standard Branch**: Falls back to normal Git branch resolution
   - Checks for remote branch first
   - Creates new branch from HEAD if needed

### Safety Features

- Prevents checking out the same branch in multiple worktrees
- Protects main/master branches from deletion
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

### Quick Start

1. **Create your configuration file:**
   ```bash
   git-turnouts config init
   ```
   This creates `.config.yml` in the git-turnouts directory

2. **Edit your configuration:**
   ```bash
   # The init command shows you the path to edit
   vim ~/.../git-turnouts/.config.yml
   ```

3. **View your current configuration:**
   ```bash
   git-turnouts config show
   ```
   This shows the detected project name and effective settings

Your settings will be applied automatically across all projects!

### Configuration Options

See `.config.yml.example` for all available options with detailed comments. Here's a quick overview:

#### Worktree Configuration

```yaml
worktree:
  # Global settings apply to all projects
  global:
    # Base directory for all projects
    # Project name is automatically added as a subdirectory
    base_dir: ~/worktrees

    # Files to copy from main worktree to new worktrees
    copy_files:
      - .editorconfig
      - .env.example
      - .nvmrc

  # Project-specific settings (overrides global)
  # The 'name' must match your repository's directory name exactly
  projects:
    - name: my-app
      base_dir: ~/custom/my-app
      copy_files:
        - .editorconfig
        - .env.local
    - name: another-project
      base_dir: /tmp/another-project
```

**How it works:**
1. Project name is detected from your repository's directory name (e.g., `/path/to/my-app` → project name is `my-app`)
2. The project name is **always added as a subdirectory** for organization
3. If a project-specific `base_dir` exists → use it: `{base_dir}/{project}/{branch}`
4. Else if global `base_dir` exists → use it: `{base_dir}/{project}/{branch}`
5. Else → auto-detect: `../worktree/{project}/{branch}`

**Example:** With `global.base_dir: ~/worktrees` and project `my-app`:
- Worktrees created at: `~/worktrees/my-app/feature-x`

---

### 💡 Pro Tip: Automatic File Copying

The `copy_files` feature is one of Git Turnouts' most powerful workflow improvements. It automatically copies essential configuration files from your main worktree to every new worktree you create.

**The problem it solves:**

Many files are **essential to run your application** but are **NOT in version control** (listed in `.gitignore`):
- `.env` files containing personal API keys, credentials, or secrets
- Local IDE settings or personalized configurations
- Files with environment-specific values unique to your machine

Without `copy_files`, you'd need to manually recreate or copy these files for **every single worktree** - a tedious and error-prone process.

**Why this matters:**
- **No manual setup** - Each worktree is instantly ready to work with
- **Never forget essential files** - Stop worrying about missing `.env` files or credentials
- **Consistency across worktrees** - All your worktrees use the same local configuration
- **Save time** - Eliminate the tedious copy-paste routine for every new worktree

**Common files to copy:**
```yaml
copy_files:
  - .env                # Personal environment variables, API keys, secrets (NOT in git)
  - .env.local          # Local development overrides (NOT in git)
  - .editorconfig       # Editor settings (indentation, formatting)
  - .nvmrc              # Node.js version for the project
  - .ruby-version       # Ruby version manager
  - .prettierrc         # Code formatting rules
  - .eslintrc.js        # Linting configuration
  - .idea/codeStyles/   # IDE code style settings
```

**Real-world example:**
```yaml
worktree:
  global:
    base_dir: ~/worktrees
    copy_files:
      - .env              # Contains your personal database credentials
      - .env.local        # Your local API keys
      - .editorconfig
      - .nvmrc
```

When you run `git-turnouts add feature-auth`, it will:
1. Create the worktree at `~/worktrees/my-app/feature-auth`
2. Automatically copy `.env`, `.env.local`, `.editorconfig`, and `.nvmrc` to the new worktree
3. Open in your IDE, ready to work immediately - **no manual file copying, no missing credentials**

**Without copy_files:**
Every time you create a worktree, you must:
- Remember which files to copy
- Manually copy `.env` file with your credentials
- Set up local configurations again
- Deal with "Cannot connect to database" errors when you forget

**With copy_files:**
Every worktree is automatically set up with all your personal configurations. Just run the app - it works immediately. 🚀

---

#### Default Behavior

```yaml
defaults:
  global:
    # Default application to open worktrees (idea, code, iterm, warp, finder)
    # idea/code = IDEs, iterm/warp = terminals, finder = file manager
    open_with: code
  projects:
    - name: my-app
      open_with: idea
```

#### Branch Protection

```yaml
protection:
  global:
    # Branches that cannot be deleted when removing worktrees
    # Note: main, master, and your repo's default branch are always protected
    protected_branches:
      - develop
      - staging
      - production
  projects:
    - name: critical-app
      protected_branches:
        - develop
        - staging
        - production
        - hotfix
```

#### Removal Behavior

```yaml
remove:
  global:
    # Auto-run git worktree prune after removing worktrees
    auto_prune: true
  projects:
    - name: experimental
      auto_prune: false
```

### Configuration Examples

#### Example 1: VS Code User

```yaml
defaults:
  global:
    open_with: code
```

#### Example 2: Global + Project-Specific Worktree Locations

```yaml
worktree:
  global:
    # All projects go to ~/worktrees/{project-name} by default
    # (project name is automatically added)
    base_dir: ~/worktrees
    copy_files:
      - .editorconfig
      - .env.example

  # But my-important-project goes to a specific location
  projects:
    - name: my-important-project
      base_dir: ~/critical
```

**Results:**
- Most projects: `~/worktrees/my-app/branch-name`
- my-important-project: `~/critical/my-important-project/branch-name`

#### Example 3: Production Environment Protection

```yaml
protection:
  global:
    # main and master are already protected by default
    protected_branches:
      - develop
      - staging
      - production
      - hotfix
```

#### Example 4: Complete Configuration

```yaml
worktree:
  global:
    base_dir: ~/worktrees
    copy_files:
      - .editorconfig
      - .env.example
  projects:
    - name: critical-app
      base_dir: ~/production

defaults:
  global:
    open_with: code

protection:
  global:
    protected_branches:
      - develop
      - staging

remove:
  global:
    auto_prune: true
```

**Results:**
- Most projects: `~/worktrees/{project}/branch-name`
- critical-app: `~/production/critical-app/branch-name`

### Notes

- Configuration is **optional** - git-turnouts works perfectly without any configuration file
- Configuration is **centralized** - one `.config.yml` file in the git-turnouts directory manages all projects
- Project names are detected automatically from the repository directory name
- Project name is **always added as a subdirectory** for organization
- Project-specific settings override global settings
- The `.config.yml.example` file serves as a template and reference

## Troubleshooting

### Missing Dependencies

#### "gh: command not found"
GitHub CLI is required for PR integration features.

**Solution:**
```bash
# macOS
brew install gh

# Linux
# See: https://cli.github.com/
```

After installation, authenticate with GitHub:
```bash
gh auth login
```

**Note:** You can still use git-turnouts with branch names without `gh` installed - PR integration features will not be available.

#### "jq: command not found"
jq is required for JSON processing.

**Solution:**
```bash
# macOS
brew install jq

# Linux (Debian/Ubuntu)
sudo apt-get install jq

# Linux (RHEL/CentOS)
sudo yum install jq

# Or download from: https://jqlang.github.io/jq/download/
```

#### "Your git version doesn't support worktrees"
Git 2.5 or newer is required.

**Solution:**
```bash
# Check your current version
git --version

# macOS - upgrade via Homebrew
brew upgrade git

# Linux - upgrade via package manager
sudo apt-get update && sudo apt-get upgrade git  # Debian/Ubuntu
sudo yum update git                                # RHEL/CentOS
```

### Permission Issues

#### "Permission denied" when creating worktrees
The worktree base directory may not be writable.

**Solution:**
```bash
# Check permissions
ls -la ~/worktrees/

# Fix permissions
chmod u+w ~/worktrees

# Or use a different directory in your config
git-turnouts config init
# Edit .config.yml and set base_dir to a writable location
```

#### "Cannot write to config file"
The git-turnouts directory may not be writable.

**Solution:**
```bash
# Find the git-turnouts directory
which git-turnouts

# Fix permissions on the directory
chmod u+w /path/to/git-turnouts

# Or create a local config by setting environment variable
export GIT_TURNOUTS_CONFIG=~/.config/git-turnouts/config.yml
```

### Worktree Conflicts

#### "Directory already exists"
A directory with that name already exists in the worktree location.

**Solution:**
```bash
# Check what's there
ls -la ~/worktrees/my-project/

# Remove the conflicting directory if it's not a worktree
rm -rf ~/worktrees/my-project/branch-name

# Or choose a different folder name
git-turnouts add my-custom-name branch-name
```

#### "Branch is already checked out"
Git prevents checking out the same branch in multiple worktrees.

**Solution:**
```bash
# List all worktrees to find where it's checked out
git worktree list

# Remove the existing worktree first
git-turnouts remove branch-name

# Or use a different branch
git-turnouts add new-branch-name
```

#### "Cannot remove worktree: uncommitted changes"
Worktree has uncommitted changes that would be lost.

**Solution:**
```bash
# Option 1: Commit the changes
cd path/to/worktree
git add .
git commit -m "Save work in progress"

# Option 2: Stash the changes
git stash save "Work in progress"

# Option 3: Manually delete (WARNING: loses changes)
rm -rf path/to/worktree
git worktree prune
```

### PR Integration Issues

#### "PR #123 not found"
The PR doesn't exist or you don't have access to it.

**Solution:**
```bash
# Verify PR exists
gh pr view 123

# Check you're authenticated
gh auth status

# Try re-authenticating
gh auth login

# Verify you're in the correct repository
git remote -v
```

#### "PR #123 is closed" (not merged)
Git Turnouts shows a warning but proceeds to create the worktree.

**Explanation:**
Closed PRs that aren't merged can still have their branches available. The worktree will be created if the branch exists remotely.

#### "PR #123 has been merged"
Git Turnouts blocks worktree creation for merged PRs.

**Reason:**
Merged PR branches are typically deleted from the remote repository and no longer exist.

**Solution:**
```bash
# Option 1: Work with the base branch where it was merged
git-turnouts add main

# Option 2: Checkout the specific commit if you need to review it
# (Use git log to find the merge commit hash)

# Option 3: If the branch still exists remotely, fetch it manually
git fetch origin branch-name
git-turnouts add branch-name
```

#### "No PRs found matching 'search term'"
No open PRs match your search query.

**Solution:**
```bash
# List all open PRs
gh pr list

# Try a different search term
git-turnouts add "different keywords"

# Use the branch name directly
git-turnouts add branch-name
```

### Application Opening Issues

#### Application doesn't open automatically
The application may not be installed or not in the expected location.

**Solution:**
```bash
# Verify application is installed and can be opened from terminal
# macOS examples:
open -a "IntelliJ IDEA"       # IDE
open -a "Visual Studio Code"  # IDE
open -a "iTerm"               # Terminal
open -a "Warp"                # Terminal

# Check your configuration
git-turnouts config show

# Change default application
git-turnouts config init
# Edit .config.yml and set defaults.open_with

# Or specify application per command
git-turnouts add branch-name --open code
```

#### "Application not found: idea/code/etc"
Application opening currently uses platform-specific commands.

**Solution:**
```bash
# Create worktree without automatic opening
git-turnouts add branch-name

# Then navigate manually
cd path/to/worktree  # Path shown in output

# Or use your system's file manager/terminal
# macOS:
open path/to/worktree

# Linux:
xdg-open path/to/worktree
```

**Current Application Support:**
- **VS Code** (`code`): IDE - May work on both macOS and Linux if installed
- **IntelliJ IDEA** (`idea`): IDE - Currently macOS-specific command
- **iTerm** (`iterm`): Terminal - macOS only
- **Warp** (`warp`): Terminal - Currently macOS-specific command
- **Finder** (`finder`): File Manager - macOS only

**Tip:** On platforms with limited application support, create worktrees without the `--open` flag and navigate manually.

### Configuration Issues

#### "Error parsing config file"
Your `.config.yml` file may have YAML syntax errors.

**Solution:**
```bash
# Backup your config
cp .config.yml .config.yml.backup

# Reset to example template
git-turnouts config init

# Or manually check YAML syntax
# Common issues:
# - Incorrect indentation (use spaces, not tabs)
# - Missing colons after keys
# - Unquoted strings with special characters

# View what's being read
git-turnouts config show
```

#### Configuration not taking effect
Make sure you're editing the right config file.

**Solution:**
```bash
# Find where config should be
which git-turnouts
# Config should be in the same directory as the script

# Show current effective configuration
git-turnouts config show

# Shows detected project name and paths
```

### General Issues

#### "fatal: not a git repository"
You must run git-turnouts from within a Git repository.

**Solution:**
```bash
# Navigate to your repository first
cd /path/to/your/repository

# Verify it's a git repo
git status

# Then run git-turnouts
git-turnouts list
```

#### Script hangs or takes a long time
Network operations (fetching PRs, pulling branches) can be slow.

**Explanation:**
This is normal for:
- Fetching large repositories
- Slow network connections
- First-time branch fetches

Git Turnouts will show progress where possible. Be patient during network operations.

#### Need more help?

1. **Check verbose error messages** - git-turnouts provides detailed error information
2. **Enable debug mode** (if needed):
   ```bash
   bash -x git-turnouts add branch-name
   ```
3. **Open an issue**: [GitHub Issues](https://github.com/andr3van/git-turnouts/issues)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE) - see LICENSE file for details

## Why This Tool?

Created to streamline Git worktree workflows with modern GitHub PR integration. Born from the need to work on multiple features, review PRs, and handle hotfixes without the constant context switching pain.

## Acknowledgments

Built for developers who work on multiple features simultaneously and need to switch tracks without losing momentum. Like a well-designed railroad junction, Git Turnouts keeps your development workflow running smoothly.
