# Omarchy Shell Polish 1.10.0

### Encrypted Disk Boot Unlock UI & Automated Wallpaper Sync

This release introduces the **Encrypted Disk Boot Unlock UI & Automated Background Sync Engine** under `reference/boot-unlock/`.

![Encrypted Disk Unlock Screen](reference/boot-unlock/boot-unlock-preview.png)

### What It Does
- **Theme-Synchronized Bootloader**: Mirrors your active Omarchy desktop wallpaper to the Plymouth early-boot kernel unlock screen (LUKS encrypted disk passphrase prompt) and SDDM login greeter.
- **Frosted Monolith Aesthetic**: Renders a centered frosted glass card with 26px rounded corners, ambient Gaussian blur, and a minimalist masked password field.
- **Zero-Prompt Automation**: Fully automated through an unprivileged cache (`/var/cache/multienv/background.png`) and background `limine-mkinitcpio` trigger—no terminal popups or root password requests when switching wallpapers.
- **Real-Time Desktop Feedback**: Fires transient desktop notifications (`notify-send`) when the sync starts and updates in-place upon successful completion.

### What Changes After Installing It
- **Plymouth Theme**: Sets active theme in `/etc/plymouth/plymouthd.conf` to `omarchy`.
- **System Sync Script**: Installs `/usr/local/bin/omarchy-plymouth-sync` and sudoers rule `/etc/sudoers.d/99-omarchy-plymouth-sync`.
- **Theme-Set Hook**: Adds `~/.config/omarchy/hooks/theme-set.d/25-sddm-wallpaper-sync.sh` to trigger on wallpaper changes.
- **Initramfs Rebuilds**: The system initramfs is updated automatically in the background via `limine-mkinitcpio` whenever a wallpaper changes.
- **Zero Breaking Changes**: Your LUKS encryption keys, crypttab parameters, kernel command line, and in-session lock screen (`hyprlock`) remain completely untouched.
