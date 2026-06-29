# anubis-os branding + fastfetch bundle

This zip mirrors the layout your BlueBuild repo expects. Drop the contents
straight into the root of your repo (merging with what's already there):

```
recipes/
  recipe.yml            <- updated: ArcMenu->Logo Menu fix already applied,
                            fastfetch package + os-release branding module
                            + systemd module added
  recipe-macbook.yml     <- same changes, FaceTime HD module already removed

files/
  system/...              <- gets copied to `/` by the existing `files` module
  systemd/system/...       <- gets copied to /usr/lib/systemd/system by the
                              `systemd` module
```

## What's new in this bundle

- **Logo**: `files/system/usr/share/icons/hicolor/{scalable,256x256,symbolic}/apps/anubis-logo*`
  and `files/system/usr/share/pixmaps/anubis-logo.png` — used by
  `gnome-control-center`'s About page via `LOGO=anubis-logo` in `/etc/os-release`.
- **Branding**: both recipes now have an `os-release` module setting
  `NAME`/`PRETTY_NAME`/`VARIANT`/`LOGO`/etc. to "Anubis Linux 44". `ID`/`ID_LIKE`
  are deliberately untouched (kept as `fedora`) so COPR resolution for earlier
  modules (RPM Fusion, kmod-wl, etc.) doesn't break — that's also why this
  module runs near the end of the build, right before `signing`.
- **fastfetch**: package added to both recipes. Config lives at
  `files/system/usr/share/fastfetch/anubis-config.jsonc`, using your ASCII art
  (`anubis-ascii.txt`) as the logo. New accounts get it via
  `/etc/skel/.config/fastfetch/config.jsonc`. Existing accounts (e.g. if
  someone rebases an existing install onto this image) get it from a
  first-boot systemd unit + script that copies the config in **without
  overwriting** any config.jsonc a user already has.
- **Alias**: `ff` and `fastfetch` both resolve to
  `fastfetch --config /usr/share/fastfetch/anubis-config.jsonc`, set up via
  `/etc/profile.d/anubis-fastfetch.sh`. Covers bash login + interactive
  shells on Fedora by default; does NOT cover zsh (zsh doesn't source
  `/etc/profile.d`) — see the comment in that file if you add zsh later.
- **Privacy choices in fastfetch** (intentional — see comments in the
  config itself): no `localip`, `publicip`, `weather`, `bluetooth`, or `wifi`
  modules, and the title doesn't print `{user-name}@{host-name}`.

## Still worth checking before merging

1. Your repo already has `enable-first-boot-units.sh` and
   `enable-gnome-extensions-defaults.sh` (referenced in both recipes) which
   I never saw the contents of. Worth a quick check that the new
   `anubis-fastfetch-firstboot.service` (enabled declaratively via the
   `systemd` module) doesn't conflict with whatever those scripts already do
   for unit-enabling.
2. The dconf override file mentioned in your existing comments
   (`files/system/etc/dconf/db/local.d/00-anubis-extensions`) also wasn't
   shown to me, so I couldn't check it against anything here — there
   shouldn't be any overlap, but worth a glance.
3. The uploaded SVG (`anubis-logo.svg`) is actually a PNG wrapped in an SVG
   container (not a true vector path) — works fine as a GTK icon, but if you
   ever want a crisp icon at very large sizes, a real vector redraw would
   look better than this raster-in-SVG approach.
4. Haven't run an actual `bluebuild build` — please test before relying on
   this in CI.
