# x86-zfs-on-root-installer

Uses a big pile of bash to install debian root on zfs on your iron

## Usage

- Copy conf.yml.example to conf.yaml, fill out fields as necessary
- Make conf.yaml available via a httpd
- Make a ssh pubkey available via the httpd
- Boot the livecd to grub
- Pass these kernel cmdline params
  - `SSH_KEY_URL=http://your.httpd/id_<type>.pub`
  - `CONF_URL=http://your.httpd/conf.yml`
- Edit `console=` params for live env as necessary
- Boot the installer
- Login with these credentials:
  - Username: `installer`
  - Password: `potassium`
- Watch the installer fly by
- Debian root on zfs has issues exporting rpool after installation
  - I remember finding a fix for this, but can't remember what it was
  - Email me honk@goos.blog if you know the fix
  - Anyway.
  - First boot you'll be dropped into an initramfs shell
  - Run these commands to fix boot
  - `zpool import -Nf rpool; reboot -f`
