# Encrypted Disk Boot Unlock & Automated Wallpaper Sync

This module provides a unified **Frosted Monolith** aesthetic and automated wallpaper synchronization for early-boot Linux storage unlock (Plymouth LUKS) and the login manager (SDDM).

![Encrypted Disk Unlock Screen](boot-unlock-preview.png)

## What It Does

- **Mirrors Active Wallpaper to Boot Screen**: Automatically takes your active desktop wallpaper, scales and blurs it (`1920x1080`, Gaussian blur `0x18`), and sets it as the early-boot background.
- **Frosted Monolith Monochromatic Deck**: Centers a frosted glass container (`card.png`) with 26px rounded corners, specular highlight border, and clean typography matching Omarchy's design language.
- **Minimalist Password Entry**: Replaces cluttered boot logs with clean bullet masks and device status tags.
- **Zero-Prompt Background Initramfs Rebuild**: Generates the unified kernel image (`limine-mkinitcpio`) in the background with zero user password prompts or terminal interrupts.
- **Real-Time Desktop Feedback**: Fires transient desktop notifications (`notify-send`) when the sync starts and updates in-place when complete.

---

## What Things Will Change After Installing It

| Component | What Changes | What Does NOT Change |
|---|---|---|
| **Plymouth Theme** | Active theme in `/etc/plymouth/plymouthd.conf` is set to `omarchy` using `omarchy.script` | Plymouth binary, kernel parameters, and bootloader entries remain intact |
| **Storage Encryption (LUKS)** | Only the graphical password entry screen is styled | **Zero changes** to disk encryption keys, crypttab, LUKS header, or passwords |
| **Wallpaper Sync Hook** | Adds hook `~/.config/omarchy/hooks/theme-set.d/25-sddm-wallpaper-sync.sh` | Wallpaper files and compositor configurations are untouched |
| **Initramfs** | Rebuilt automatically in background via `limine-mkinitcpio` when wallpaper changes | Fallback images and backup initramfs presets remain safe |
| **Desktop Lock Screen** | None. Desktop lock screens (`hyprlock` / `modern-lock`) remain untouched | In-session lock screen styling and PAM authentication are unchanged |

---

## Installation & Setup

1. **Deploy the Plymouth Theme**:
   ```bash
   sudo cp -r /usr/share/plymouth/themes/omarchy /usr/share/plymouth/themes/omarchy.bak
   sudo cp omarchy.script card.png /usr/share/plymouth/themes/omarchy/
   sudo plymouth-set-default-theme omarchy
   ```

2. **Install Background Sync Script & Sudoers Permission**:
   ```bash
   sudo cp omarchy-plymouth-sync /usr/local/bin/omarchy-plymouth-sync
   sudo chmod 755 /usr/local/bin/omarchy-plymouth-sync
   echo "$USER ALL=(ALL) NOPASSWD: /usr/local/bin/omarchy-plymouth-sync" | sudo tee /etc/sudoers.d/99-omarchy-plymouth-sync
   ```

3. **Install Theme Hook**:
   ```bash
   mkdir -p ~/.config/omarchy/hooks/theme-set.d
   cp 25-sddm-wallpaper-sync.sh ~/.config/omarchy/hooks/theme-set.d/25-sddm-wallpaper-sync.sh
   chmod 755 ~/.config/omarchy/hooks/theme-set.d/25-sddm-wallpaper-sync.sh
   ```

4. **Run First Sync**:
   ```bash
   sudo /usr/local/bin/omarchy-plymouth-sync
   ```
