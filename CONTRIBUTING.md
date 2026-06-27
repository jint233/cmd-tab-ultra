# Contributing

## Principles

- Keep changes small and reviewable.
- Follow existing architecture before introducing new abstractions.
- Prefer behavior-preserving refactors unless the pull request is explicitly about product behavior.
- Document user-visible changes and operational changes in the same pull request.

## Source of Truth

Use these references when contributing:

1. Swift API Design Guidelines
2. Apple's general Swift style expectations
3. Repository rules in [development.md](./docs/development.md)
4. Repository formatting rules in [.swift-format](./.swift-format) and [.editorconfig](./.editorconfig)

## Branch and Pull Request Expectations

- One branch per focused change
- One pull request per cohesive unit of work
- Clear title and summary
- Verification notes with the exact commands you ran
- Screenshots only when the UI changes

## Code Style

- Use English for identifiers, comments, commit messages, and repository docs.
- Keep UI copy consistent within the product surface being edited.
- Prefer `final` types unless subclassing is needed.
- Prefer `let` over `var` unless mutation is required.
- Use `MARK:` sections when they improve navigation.
- Remove dead code instead of commenting it out.

## Testing and Verification

Before opening a pull request, run:

```sh
make lint
make universal
```

If packaging or install behavior changed, also run:

```sh
make bundle
make dmg
make pkg
```

Include any skipped verification in the pull request description.

## Releases

Release versions come from the `Version` key in `com.jint233.cmdtabultra.plist`.

To publish from a clean `main` branch:

```sh
scripts/release.sh
```

The script requires GitHub CLI authentication and pushes a `v*` tag. GitHub Actions builds and uploads the universal ZIP, DMG image, and installer package.

## Documentation

Update documentation when you change:

- build commands
- installation flow
- runtime permissions
- packaging behavior
- contributor workflow

## Out of Scope for Drive-By Changes

Do not mix these into unrelated pull requests:

- broad renames
- formatting-only rewrites across untouched files
- UI copy overhauls
- packaging changes with no verification
