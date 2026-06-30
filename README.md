# CmdTabUltra

[English](./README.md) | [简体中文](./README.zh-CN.md)

CmdTabUltra is a macOS window restore utility. When you switch back to an app with `Cmd-Tab`, it restores a minimized window or reopens a window if macOS leaves the app active with no visible window.

## Features

- Restores minimized windows after `Cmd-Tab`
- Reopens apps that have no standard visible window
- Falls back to `Cmd-N` when app reopen does not create a window
- Provides a local control panel for service status, startup, diagnostics, and language
- Runs the background service through a per-user LaunchAgent

## Requirements

- macOS 11 or later
- Xcode Command Line Tools
- Accessibility permission for CmdTabUltra

## Install

Build and install locally:

```sh
make install
```

Build a DMG:

```sh
make dmg
open dist/CmdTabUltra-<version>.dmg
```

After installing, open `CmdTabUltra.app`, grant Accessibility permission, then start the service from the control panel.

## Development

Common commands:

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

Update the release version in [VERSION](./VERSION). Packaging, app metadata, installer names, and release tags use that file as the single version source.

Project layout:

```text
src/          Swift source
VERSION       Release version
resources/    App icon and localized strings
scripts/      Local helper scripts
packaging/    Installer metadata
docs/         Development notes
dist/         Generated artifacts
```

See [CONTRIBUTING.md](./CONTRIBUTING.md) and [docs/development.md](./docs/development.md) for contribution and maintenance notes.

## Notes

CmdTabUltra uses public macOS APIs and Accessibility permission. The control panel writes `com.jint233.cmdtabultra.plist` to `~/Library/LaunchAgents/` when the background service is started.

Generated files in `dist/` should not be committed.

## License

Apache License 2.0. See [LICENSE](./LICENSE).
