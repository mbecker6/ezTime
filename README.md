# ezTime

A tiny macOS menu bar clock. Click it to pick any time zone from a searchable list, sorted by GMT offset. Optional launch at login.

Requires macOS 13 or later (Apple Silicon or Intel).

## Install

Paste this into Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/mbecker6/ezTime/main/install.sh | bash
```

It installs the latest version into `/Applications` and starts it. Run it again to update.

## Uninstall

Click the clock → Quit, then delete `/Applications/ezTime.app`.

## Build from source

```bash
./build.sh
```

The app ends up in `build/ezTime.app`. Needs Swift 5.9+ (Xcode or the Command Line Tools).
