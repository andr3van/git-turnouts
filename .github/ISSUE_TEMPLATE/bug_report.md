---
name: Bug Report
about: Report a bug or unexpected behavior
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## Environment

- **OS**: [e.g., macOS 14.0, Ubuntu 22.04, Windows Git Bash]
- **Bash Version**: [output of `bash --version`]
- **Git Version**: [output of `git --version`]
- **Git Turnouts Version**: [commit hash or release tag, e.g., v1.0.0]
- **GitHub CLI Version** (if applicable): [output of `gh --version`]

## Steps to Reproduce

1. Go to '...'
2. Run command '....'
3. See error

```bash
# Exact commands you ran
git-turnouts add feature-branch
```

## Expected Behavior

A clear description of what you expected to happen.

## Actual Behavior

What actually happened instead.

## Error Output

```
Paste the complete error message or output here
```

## Configuration

If relevant, share your configuration (remove any sensitive information):

```yaml
# Contents of .config.yml (if relevant)
worktree:
  global:
    base_dir: ~/worktrees
```

## Additional Context

Add any other context about the problem here:
- Does it happen consistently or intermittently?
- Did this work in a previous version?
- Are there any specific branch names or patterns that trigger it?
- Screenshots if applicable

## Possible Solution (Optional)

If you have an idea of what might be causing the issue or how to fix it, please share.
