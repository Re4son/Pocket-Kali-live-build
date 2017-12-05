# gpd-pocket-supplement-re4son

Status 5/12/2017:
Persistent kali linux live build with working:
- rotation
- touch screen
- wifi
- bluetooth
- HiDPI settings


copy 99-local-bluetooth.rules to kali-config/common/includes.chroot/etc/udev/rules.d/  
copy brcmfmac4356-pcie.txt to kali-config/common/includes.chroot/lib/firmware/brcm  
copy monitors.xml to kali-config/common/includes.chroot/etc/skel/.config/  
copy xrandr.desktop to kali-config/common/includes.chroot/etc/skel/.config/autostart  


