# CmdTabUltra

CmdTabUltra is a macOS menu bar utility that restores an application's window when you switch to it with `Cmd-Tab`.

It works without private frameworks. The agent listens for `Cmd-Tab` transitions, inspects the target app through the Accessibility API, and then restores or reopens a window when macOS would otherwise leave the app active with no visible window.

## Features

- Restores a minimized window after `Cmd-Tab`
- Reopens an app when it has no standard window
- Falls back to `Cmd-N` when macOS reopen does not create a window
- Ships with a local control panel and LaunchAgent integration
- Builds a universal app bundle, ZIP archive, DMG image, and `.pkg` installer

## Requirements

- macOS 11 or later
- Xcode Command Line Tools
- Accessibility permission for CmdTabUltra

## Quick Start

Build and install locally:

```sh
make install
```

Build a drag-and-drop DMG:

```sh
make dmg
open dist/CmdTabUltra-<version>.dmg
```

After installation:

1. Drag `CmdTabUltra.app` into `Applications`.
2. Open `CmdTabUltra.app`.
3. Grant Accessibility permission when prompted.
4. Start the background service from the control panel if it is not already running.

The control panel writes the per-user LaunchAgent from the app's current location, so the app can be installed in `/Applications` or `~/Applications`.

## How It Works

When `Cmd-Tab` activates a new foreground app, CmdTabUltra:

1. waits for the app activation event;
2. inspects the app's standard windows through the Accessibility API;
3. leaves the app alone if a visible window already exists;
4. unminimizes one window if every standard window is minimized;
5. reopens the app, then falls back to `Cmd-N`, when no standard window exists.

## Build Targets

Common development targets:

```sh
make help
make universal
make bundle
make zip
make dmg
make pkg
make lint
make format
make clean
```

Create a GitHub release with the local GitHub CLI:

```sh
scripts/release.sh
```

## Repository Layout

```text
src/
  Main.swift
  Config.swift
  AccessibilitySupport.swift
  EventTapController.swift
  CmdTabSwitchState.swift
  WindowState.swift
  WindowActions.swift
  ControlPanel*.swift
  ShellCommand.swift
  LaunchAgentStatus.swift
  AgentProcess.swift
  ServiceControl.swift

resources/     App icon and bundled assets
scripts/       Local helper scripts
packaging/     Installer metadata and postinstall script
docs/          Project conventions and development notes
.github/       CI workflow and collaboration templates
dist/          Generated output; do not commit
```

## Development Workflow

Project conventions are documented here:

- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [development.md](./docs/development.md)
- [.swift-format](./.swift-format)
- [.editorconfig](./.editorconfig)

The repository follows these baseline rules:

- Swift code should align with the Swift API Design Guidelines and the existing local architecture.
- Formatting should be deterministic and repository-wide.
- Pull requests should stay scoped, include verification notes, and avoid unrelated refactors.
- Generated artifacts in `dist/` must not be committed.

## Installation Notes

The DMG contains:

- `CmdTabUltra.app`
- an `Applications` shortcut for drag-and-drop installation

The app writes `com.stoutput.cmdtabultra.plist` to `~/Library/LaunchAgents/` when the service is started from the control panel.

If you replace the app without a stable signing identity, macOS may require Accessibility permission again. To preserve permission across upgrades, keep these stable:

- bundle identifier: `com.stoutput.cmdtabultra`
- app location selected by the user
- code-signing identity

To build with signing:

```sh
make pkg SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
```

## Debugging

Tail the agent log:

```sh
tail -f /tmp/CmdTabUltra.log
```

Inspect LaunchAgent status:

```sh
launchctl print "gui/$(id -u)/com.stoutput.cmdtabultra"
launchctl print-disabled "gui/$(id -u)" | grep com.stoutput.cmdtabultra
```

Inspect the ready marker:

```sh
cat "$HOME/Library/Application Support/CmdTabUltra/agent-ready"
```

The PID in `agent-ready` should match the PID reported by `launchctl print`.

## Release Process

1. Update the `Version` key in `com.stoutput.cmdtabultra.plist`.
2. Verify `make lint` and `make universal`.
3. Commit and push the version bump to `main`.
4. Run `scripts/release.sh` to push the release tag.

The release script validates that the local `main` branch matches `origin/main`, creates a signed Git tag, and pushes it. GitHub Actions builds the ZIP, DMG, and PKG assets and publishes the release automatically when a `v*` tag is pushed.

## Current Scope

The control panel currently uses Chinese UI copy. Repository documentation and contribution guidance are standardized in English so the codebase remains accessible to broader GitHub collaboration.
