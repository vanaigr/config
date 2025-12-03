Remember to use absolute paths in `ln`

# Xremap:

1. install with cargo

```shell
sudo gpasswd -a <YOUR_USER> input
echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules
```

2. Link xremap to `.config/xremap`

3. link `xremap.service` to `~/.config/systemd/user/xremap.service`

4. `systemctl --user enable xremap.service`

# Power button

Add to `/etc/systemd/logind.conf`:

```
HandlePowerKey=suspend
HandlePowerKeyLongPress=poweroff
```

Symlinking dropin files doesn't work because Yes.

# Auto login:

`sudo ln -s /home/me/gh/config/getty@tty1.service.d/ /etc/systemd/system/getty@tty1.service.d`

# Append to `~/.profile`:

```shell
export MOZ_USE_XINPUT2=1

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  exec startx
fi
```

# `/etc/grub.d/30_os-prober`

set `quick_boot="0"`
