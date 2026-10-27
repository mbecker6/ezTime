# ezTime

A tiny macOS menu bar clock. Click it to pick any time zone from a searchable list, sorted by GMT offset. Optional launch at login.

Requires macOS 13 or later (Apple Silicon or Intel).

## Install

Paste this into Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/mbecker6/ezTime/main/install.sh | bash
```

It downloads the latest release into `/Applications` and starts it. Run it again to update.

### Manual install

1. Download `ezTime.zip` from the [latest release](https://github.com/mbecker6/ezTime/releases/latest) and unzip it.
2. Move `ezTime.app` to `/Applications` and open it.
3. macOS will block it because the app isn't notarized by Apple. Go to System Settings → Privacy & Security, scroll down and click **Open Anyway**.

## Uninstall

Click the clock → Quit, then delete `/Applications/ezTime.app`.

## Build from source

```bash
./build.sh
```

The app ends up in `build/ezTime.app`. Needs Swift 5.9+ (Xcode or the Command Line Tools).

## Releasing

Push a version tag; GitHub Actions builds `ezTime.zip` and publishes the release:

```bash
git tag v1.0.0 && git push origin v1.0.0
```
