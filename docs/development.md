# Development Notes

## Repository Standards

This repository is intentionally lightweight, but it should still behave like a well-run Swift project on GitHub.

Core expectations:

- deterministic formatting
- minimal build surface
- readable operational documentation
- scoped pull requests
- reproducible local verification

## Swift Conventions

The project follows these conventions:

- `UpperCamelCase` for types
- `lowerCamelCase` for functions, properties, and local values
- one primary responsibility per file
- explicit access control only when it adds clarity
- comments explain intent, not mechanics
- `MARK:` sections only where they help navigation

Prefer straightforward control flow over clever compactness. If a block is hard to scan, split it into a helper.

## File Organization

Keep top-level source files organized by responsibility:

- app entry and shared configuration
- event capture and agent lifecycle
- Accessibility and window management
- control panel UI and actions
- packaging or build helpers

Avoid creating utility files that collect unrelated helpers.

## Documentation Rules

- `README.md` explains what the project does, how to build it, how to install it, and how to debug it.
- `CONTRIBUTING.md` explains how to change the project safely.
- GitHub templates should make bug reports and pull requests actionable.
- Keep documentation in English unless the document is intentionally product-facing content.

## Formatting

The repository uses `.editorconfig` for baseline whitespace rules and `.swift-format` for Swift formatting preferences.

Recommended commands:

```sh
make lint
make format
```

If `swift-format` is not installed, install it through your normal Swift toolchain workflow before submitting repository-wide formatting changes.

## GitHub Hygiene

Pull requests should include:

- a short problem statement
- a short implementation summary
- verification commands
- follow-up work, if any

Issues should describe expected behavior, actual behavior, reproduction steps, and environment details.
