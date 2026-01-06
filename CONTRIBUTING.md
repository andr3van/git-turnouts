# Contributing to Git Turnouts

Thank you for your interest in contributing to Git Turnouts! We welcome contributions of all kinds.

## Areas Where Help is Appreciated

- 🎨 **New IDE/Application Adapters** - Support for additional editors and terminals
- 🐛 **Bug Reports** - Platform-specific issues, edge cases
- 📚 **Documentation** - Tutorials, use cases, examples
- ✨ **Features** - New worktree management capabilities
- 🧪 **Testing** - Additional test coverage, edge case testing
- 🌍 **Platform Support** - Windows native support, additional Unix-like systems

## Getting Started

### Prerequisites

- Git 2.5 or newer
- Bash 3.2+
- [bats-core](https://github.com/bats-core/bats-core) for running tests
- jq (for JSON parsing)
- GitHub CLI (gh) for testing PR integration features

### Setting Up Your Development Environment

1. **Fork the repository** on GitHub

2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/git-turnouts.git
   cd git-turnouts
   ```

3. **Create a feature branch:**
   ```bash
   git checkout -b feature/my-feature
   ```

4. **Make the git-turnouts script executable:**
   ```bash
   chmod +x git-turnouts
   ```

5. **Run existing tests to ensure everything works:**
   ```bash
   bats tests/*.bats
   ```

## Pull Request Process

### 1. Make Your Changes

- Write clean, readable code following our coding standards (see below)
- Add or update tests for your changes
- Update documentation (README.md, help text, etc.) for any feature or behavioral changes

### 2. Test Thoroughly

**Manual testing checklist:**
- [ ] Creating worktrees with various branch types (local, remote, new)
- [ ] Creating worktrees from PR numbers and PR titles
- [ ] Worktree removal (single and bulk)
- [ ] Configuration commands (init, show, edit)
- [ ] List command with various filters
- [ ] Application opening (`--open` flag with different applications)
- [ ] Configuration file handling (global and project-specific settings)
- [ ] Branch protection (attempt to remove protected branches)
- [ ] File copying (`copy_files` feature)

**Platform testing:**
- **macOS** - Primary platform
- **Linux** - Ubuntu, Fedora, or Arch recommended
- **Windows** - Git Bash (if applicable)

**Automated testing:**
```bash
# Run all tests
bats tests/*.bats

# Run specific test file
bats tests/config.bats
```

### 3. Commit Your Changes

Use clear, descriptive commit messages following this format:

```
<type>: <short description>

[optional longer description]

[optional footer with issue references]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring (no functional changes)
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependencies, build, etc.)

**Examples:**
```bash
git commit -m "feat: add support for VSCodium IDE"
git commit -m "fix: handle branch names with special characters"
git commit -m "docs: add troubleshooting section for Windows users"
```

### 4. Push to Your Fork

```bash
git push origin feature/my-feature
```

### 5. Open a Pull Request

Create a PR on GitHub with:

- **Clear description** of what your changes do and why
- **Link to related issues** (e.g., "Fixes #123" or "Related to #456")
- **Testing performed:**
  - Platforms tested
  - Test cases covered
  - Any edge cases considered
- **Screenshots/examples** (if applicable, especially for output changes)

**PR Title Format:**
```
<type>: <short description>
```

**Example PR description:**
```markdown
## Description
Adds support for opening worktrees in VSCodium editor.

## Related Issues
Closes #42

## Testing Performed
- [x] Tested on macOS 14.0
- [x] Tested on Ubuntu 22.04
- [x] Verified `--open code` still works
- [x] Verified `--open vscodium` opens VSCodium
- [x] Added test cases in tests/integration.bats

## Screenshots
[Screenshot showing VSCodium opening successfully]
```

## Coding Standards

### Bash Style Guide

**General:**
- Use `#!/usr/bin/env bash` shebang
- Target **Bash 3.2+ compatibility** (macOS default)
- Use `set -e` for strict error handling when appropriate
- Keep lines under **100 characters** where possible
- Use **2-space indentation** (no tabs)

**Variables:**
- Always quote variables: `"$var"` not `$var`
- Use `local` for function-local variables
- Use `snake_case` for function names and variables
- Use `UPPER_CASE` for constants and environment variables

**Functions:**
```bash
# Good
my_function() {
  local arg="$1"
  echo "Processing: $arg"
}

# Avoid
myFunction() {
  arg=$1  # Missing local, unquoted
  echo Processing: $arg  # Unquoted
}
```

**Error Handling:**
```bash
# Check command success
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required"
  exit 1
fi

# Validate arguments
if [ -z "$branch_name" ]; then
  echo "Error: Branch name is required"
  exit 1
fi
```

**Arrays (Bash 3.2 compatible):**
```bash
# Use whitespace-separated strings or iterate safely
for file in .env .editorconfig .nvmrc; do
  echo "$file"
done
```

### Configuration Parsing

When working with YAML configuration:
- Use the existing `parse_yaml()` and `load_configuration()` functions
- Handle missing configuration gracefully with defaults
- Respect the hierarchy: project-specific → global → hardcoded defaults

### Testing

When adding tests:
- Use descriptive test names: `@test "config show displays project-specific settings"`
- Use test helpers from `tests/test_helper.bash`
- Clean up test artifacts in teardown
- Test both success and failure cases

## Documentation Standards

### README.md Updates

When adding features, update:
- **Features** section - Add bullet point for new capability
- **Usage** section - Add examples with explanation
- **Configuration** section - Document any new config options
- **Troubleshooting** section - Add common issues and solutions

### Help Text

Update the `cmd_help()` function in the script for:
- New commands
- New flags or options
- Changed behavior

### Code Comments

- Comment **why**, not **what** (code should be self-explanatory)
- Use comments for complex logic or bash-specific workarounds
- Reference issue numbers for bug fixes: `# Fix for #123: handle spaces in branch names`

## Issue Reporting

### Bug Reports

Include:
- **Git Turnouts version** (from git commit hash or release tag)
- **OS and version** (macOS 14.0, Ubuntu 22.04, etc.)
- **Bash version** (`bash --version`)
- **Steps to reproduce**
- **Expected vs actual behavior**
- **Relevant configuration** (`.config.yml` contents if applicable)
- **Error messages** (full output)

### Feature Requests

Include:
- **Use case** - What problem does this solve?
- **Proposed solution** - How should it work?
- **Alternatives considered** - Other approaches you've thought about
- **Examples** - Show what the usage would look like

## Code Review Process

- Maintainers will review your PR
- Address feedback by pushing additional commits to your branch
- Once approved, maintainers will merge your PR
- Please be patient - maintainers are volunteers

## Questions?

- Open an issue for questions about contributing
- Check existing issues and PRs for similar discussions
- Review the README.md for usage examples and architecture

---

Thank you for contributing to Git Turnouts! 🚀
