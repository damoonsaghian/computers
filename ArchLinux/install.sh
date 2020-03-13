printf '\nen_US.UTF-8 UTF-8\n' >> /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf

pacman -S grub intel-ucode amd-ucode linux linux-firmware \
  btrfs-progs e2fsprogs dosfstools unzip nano man-db pulseaudio-alsa networkmanager \
  ttf-hack noto-fonts materia-gtk-theme \
  lightdm-gtk-greeter xorg-server light-locker gnome-shell gvfs lxterminal

printf '\nGRUB_TIMEOUT=0\nGRUB_DISABLE_OS_PROBER=true\n' >> /etc/default/grub
printf '\nset superusers=""\n' >> /etc/grub.d/40_custom
printf '\nCLASS="--class gnu-linux --class gnu --class os --unrestricted"\n' >
  /etc/grub.d/10_linux
grub-mkconfig -o /boot/grub/grub.cfg
grub-mkstandalone -O x86_64-efi -o '/boot/efi/EFI/BOOT/BOOTX64.EFI' \
  'boot/grub/grub.cfg=/boot/grub/grub.cfg'
# automatically update Grub every time "grub" package is upgraded:
mkdir -p /etc/pacman.d/hooks
echo '[Trigger]
Type = Package
Operation = Upgrade
Target = grub
[Action]
Description = Updating grub
When = PostTransaction
Exec = /usr/bin/grub-mkstandalone -O x86_64-efi -o \"/boot/efi/EFI/BOOT/BOOTX64.EFI\" \"boot/grub/grub.cfg=/boot/grub/grub.cfg\"
' > /etc/pacman.d/hooks/100-grub.hook

systemctl enable systemd-timesyncd
systemctl enable NetworkManager

systemctl enable lightdm
mkdir -p /etc/lightdm/lightdm.conf.d/
echo '[LightDM]
sessions-directory=/usr/share/wayland-sessions
' > /etc/lightdm/lightdm.conf.d/50-myconfig.conf
mkdir -p /etc/lightdm/lightdm-gtk-greeter.conf.d/
echo '[greeter]
hide-user-image=true
indicators=
' > /etc/lightdm/lightdm-gtk-greeter.conf.d/50-myconfig.conf

# since Gnome does not use the autostart file provided by "light-locker" package itself:
mkdir -p /etc/skel/.config/autostart
echo '[Desktop Entry]
Type=Application
Name=Screen Locker
Exec=light-locker
NoDisplay=true
' > /etc/skel/.config/autostart/light-locker.desktop

# to customize dconf default values:
mkdir -p /etc/dconf/profile
echo 'user-db:user
system-db:local
' > /etc/dconf/profile/user

mkdir -p /etc/dconf/db/local.d
echo "[org/gnome/system/location]
enabled=true
[org/gnome/desktop/datetime]
automatic-timezone=true
[org/gnome/desktop/notifications]
show-banners=false
[org/gnome/desktop/background]
primary-color='#222222'
secondary-color='#222222'
[org/gnome/desktop/interface]
overlay-scrolling=false
document-font-name='sans 10.5'
font-name='sans 10.5'
monospace-font-name='monospace 10.5'
gtk-theme='Materia-light-compact'
cursor-blink-timeout=1000
enable-hot-corners=false
[org/gnome/desktop/wm/preferences]
button-layout=''
[org/gnome/desktop/wm/keybindings]
cycle-windows=['']
cycle-windows-backward=['']
close=['<Alt>Escape']
toggle-maximized=['<Shift><Alt>Space']
activate-window-menu=['']
[org/gnome/shell/keybindings]
toggle-application-view=['<Alt>Space', '<Super>a']
switch-to-application-1=['<Alt>a']
[org/gnome/shell]
disable-extension-version-validation=true
enabled-extensions=['gnome-shell-improved']
" > /etc/dconf/db/local.d/00-mykeyfile
dconf update

mkdir -p /usr/local/share/gnome-shell/extensions/gnome-shell-improved/
echo '{
  "uuid": "gnome-shell-improved",
  "name": "GnomeShellImproved",
  "description": "GnomeShell improved",
  "shell-version": []
}' > /usr/local/share/gnome-shell/extensions/gnome-shell-improved/metadata.json
echo 'stage {
  font-family: sans;
  font-size: 10.5pt;
  font-weight: normal;
  color: #ffffff;
  background-color: #222222;
}
#overview {
  color: #ffffff;
  background-color: #222222;
}
#panel {
  height: 18px;
  margin-bottom: 0;
  background-color: #222222;
}
#panel .panel-button {
  -natural-hpadding: 4px;
  -minimum-hpadding: 4px;
  margin: 1px 0px 0px 0px;
  font-family: monospace;
  font-size: 10.5pt;
  font-weight: normal;
  color: #ffffff;
}
#panel .panel-button .system-status-icon {
  padding: 0px 8px 0 0;
}
' > /usr/local/share/gnome-shell/extensions/gnome-shell-improved/style.css
cp ./extension.js /usr/local/share/gnome-shell/extensions/gnome-shell-improved/

curl --proto '=https' -sSf -o #1 https://raw.githubusercontent.com/damoonsaghian/Comshell/master/ArchLinux/gtk.css
mkdir -p /etc/skel/.config/gtk-3.0
cp ./gtk.css /etc/skel/.config/gtk-3.0/
mkdir -p /etc/skel/.config/gtk-4.0
cp ./gtk.css /etc/skel/.config/gtk-4.0/

echo '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <selectfont>
    <rejectfont>
      <pattern><patelt name="family" ><string>NotoNastaliqUrdu</string></patelt></pattern>
      <pattern><patelt name="family" ><string>NotoKufiArabic</string></patelt></pattern>
      <pattern><patelt name="family" ><string>NotoNaskhArabic</string></patelt></pattern>
      <pattern><patelt name="family" ><string>NotoNaskhArabicUI</string></patelt></pattern>
    </rejectfont>
  </selectfont>
  <alias>
    <family>serif</family>
    <prefer><family>NotoSerif</family></prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer><family>NotoSans</family></prefer>
  </alias>
  <alias>
    <family>sans</family>
    <prefer><family>NotoSans</family></prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer><family>Hack</family></prefer>
  </alias>
</fontconfig>
' > /etc/fonts/local.conf

echo '[general]
fontname=Monospace 10.5
cursorblinks=true
geometry_columns=80
geometry_rows=25
hidescrollbar=true
hidemenubar=true
hideclosebutton=true
hidepointer=true
disablef10=true
disablealt=true
disableconfirm=true
bgcolor=rgb(55,55,55)
fgcolor=rgb(255,255,255)
palette_color_0=rgb(7,54,66)
palette_color_1=rgb(220,50,47)
palette_color_2=rgb(133,153,0)
palette_color_3=rgb(181,137,0)
palette_color_4=rgb(38,139,210)
palette_color_5=rgb(211,54,130)
palette_color_6=rgb(42,161,152)
palette_color_7=rgb(238,232,213)
palette_color_8=rgb(0,43,54)
palette_color_9=rgb(203,75,22)
palette_color_10=rgb(88,110,117)
palette_color_11=rgb(101,123,131)
palette_color_12=rgb(131,148,150)
palette_color_13=rgb(108,113,196)
palette_color_14=rgb(147,161,161)
palette_color_15=rgb(253,246,227)
color_preset=Solarized Dark
' > /etc/skel/.config/lxterminal/lxterminal.conf

echo '[Desktop Entry]
Name=Terminal
TryExec=lxterminal
Exec=lxterminal
Icon=utilities-terminal
Type=Application
' > /usr/local/share/applications/lxterminal.desktop

echo '
PS1="\[$(tput setab 4)\]\[$(tput setaf 15)\]\w\[$(tput sgr0)\]\[$(tput setaf 4)\]\[$(tput sgr0)\] "
unset HISTFILE
' >> /etc/skel/.bashrc

useradd -m -G wheel user1
passwd user1
passwd
