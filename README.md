# x86-zfs-on-root-installer
Uses ansible to install debian root on zfs on your iron

Debian root on zfs via ansible


```bash
lb config 

lb config \
  --apt apt-get \
  --apt-indices false \
  --apt-recommends false \
  --apt-secure true \
  --binary-filesystem ext4 \
  --binary-image iso-hybrid \
  --debconf-frontend noninteractive \
  --distribution bookworm \
  --initramfs live-boot \
  --initramfs-compression gzip \
  --interactive false \
  --net-tarball true \
  --uefi-secure-boot disable \
  --system live \
  --debian-installer none

lb build 2>&1 | tee -a build.log

```
