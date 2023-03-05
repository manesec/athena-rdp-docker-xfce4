FROM athenaos/base

ENV LANG=en_US.UTF-8
ENV TZ=Europe/Zurich
ENV PATH="/usr/bin:${PATH}"
ENV PUSER=athena
ENV PUID=1000

# Configure the locale; enable only en_US.UTF-8 and the current locale.
RUN sed -i -e 's~^\([^#]\)~#\1~' '/etc/locale.gen' && \
  echo -e '\nen_US.UTF-8 UTF-8' >> '/etc/locale.gen' && \
  if [[ "${LANG}" != 'en_US.UTF-8' ]]; then \
  echo "${LANG}" >> '/etc/locale.gen'; \
  fi && \
  locale-gen && \
  echo -e "LANG=${LANG}\nLC_ADDRESS=${LANG}\nLC_IDENTIFICATION=${LANG}\nLC_MEASUREMENT=${LANG}\nLC_MONETARY=${LANG}\nLC_NAME=${LANG}\nLC_NUMERIC=${LANG}\nLC_PAPER=${LANG}\nLC_TELEPHONE=${LANG}\nLC_TIME=${LANG}" > '/etc/locale.conf'

# Configure the timezone.
RUN echo "${TZ}" > /etc/timezone && \
  ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime

RUN pacman -Syu --noconfirm

## Need for creating /usr/share/polkit-1/actions/org.freedesktop.consolekit.policy file
RUN pacman -Syu --noconfirm consolekit
RUN pacman -Rd --nodeps --noconfirm polkit-consolekit

#######################################################
###                  BASIC PACKAGES                 ###
#######################################################

RUN pacman -Syu --noconfirm --needed accountsservice btrfs-progs dialog gcc inetutils make man-db man-pages most nano nbd net-tools netctl pv rsync sudo timelineproject-hg xdg-user-dirs

#######################################################
###                   DEPENDENCIES                  ###
#######################################################

RUN pacman -Syu --noconfirm --needed exa python-libtmux python-libtmux sassc hwloc ocl-icd pocl

#######################################################
###                      FONTS                      ###
#######################################################

RUN pacman -Syu --noconfirm --needed adobe-source-han-sans-cn-fonts adobe-source-han-sans-jp-fonts adobe-source-han-sans-kr-fonts gnu-free-fonts nerd-fonts-jetbrains-mono ttf-jetbrains-mono

#######################################################
###                    UTILITIES                    ###
#######################################################

RUN pacman -Syu --noconfirm --needed asciinema bashtop bat bc cmatrix cowsay cron downgrade dunst eog espeakup figlet file-roller fortune-mod git gnome-keyring imagemagick jdk-openjdk jq lolcat lsd neofetch nyancat openbsd-netcat openvpn orca p7zip paru pfetch python-pywhat reflector sl textart tidy tk tmux toilet tree ufw unzip vim vnstat wget which xclip xcp xmlstarlet zoxide
RUN pacman -Syu --noconfirm --needed openssl shellinabox

#######################################################
###                   CHAOTIC AUR                   ###
#######################################################

RUN pacman -Syu --noconfirm --needed chaotic-keyring chaotic-mirrorlist powershell

#######################################################
###                    BLACKARCH                    ###
#######################################################

RUN pacman -Syu --noconfirm --needed blackarch-keyring blackarch-mirrorlist

#######################################################
###                ATHENA REPOSITORY                ###
#######################################################

RUN pacman -Syu --noconfirm --needed athena-application-config athena-keyring athena-nvchad athena-welcome athena-zsh figlet-fonts htb-tools myman nist-feed superbfetch-git toilet-fonts

#######################################################
###                    GUI TOOLS                    ###
#######################################################

RUN pacman -Syu --noconfirm --needed alacritty bless chatgpt-desktop-bin code discord gnome-characters gnome-control-center gnome-menus gnome-shell-extensions gnome-themes-extra gnome-tweaks gtk-engine-murrine hexedit kitty nautilus networkmanager networkmanager-openvpn octopi polkit-gnome reflector xdg-desktop-portal xdg-desktop-portal-gnome athena-blue-eyes-theme athena-firefox-config athena-pentoxic-menu athena-pwnage-menu athena-theme-tweak athena-vscode-themes athena-welcome gnome-shell-extension-appindicator-git gnome-shell-extension-desktop-icons-ng gnome-shell-extension-fly-pie-git gnome-shell-extension-pop-shell-git gnome-shell-extension-ubuntu-dock-git

# Install xrdp and xorgxrdp from AUR.
# - Unlock gnome-keyring automatically for xrdp login.
RUN pacman -Syu --noconfirm --needed \
  check imlib2 tigervnc libxrandr fuse libfdk-aac ffmpeg nasm xorg-server xorg-server-devel && \
  pacman -S --noconfirm --needed xrdp xorgxrdp

RUN systemctl enable xrdp.service

# Install the workaround for:
# - https://github.com/neutrinolabs/xrdp/issues/1684
# - GNOME Keyring asks for password at login.
RUN cd /tmp && \
  wget --progress=dot:giga 'https://github.com/matt335672/pam_close_systemd_system_dbus/archive/f8e6a9ac7bdbae7a78f09845da4e634b26082a73.zip' && \
  unzip f8e6a9ac7bdbae7a78f09845da4e634b26082a73.zip && \
  cd /tmp/pam_close_systemd_system_dbus-f8e6a9ac7bdbae7a78f09845da4e634b26082a73 && \
  make install && \
  rm -fr /tmp/pam_close_systemd_system_dbus-f8e6a9ac7bdbae7a78f09845da4e634b26082a73

# Clean Pacman cache
RUN pacman -Scc --noconfirm

# Enable/disable the services.
RUN systemctl enable sshd.service NetworkManager.service && \
  systemctl mask \
  bluetooth.service \
  dev-sda1.device \
  dm-event.service \
  dm-event.socket \
  geoclue.service \
  initrd-udevadm-cleanup-db.service \
  lvm2-lvmpolld.socket \
  lvm2-monitor.service \
  power-profiles-daemon.service \
  systemd-boot-update.service \
  systemd-modules-load.service \
  systemd-network-generator.service \
  systemd-networkd.service \
  systemd-networkd.socket \
  systemd-networkd-wait-online.service \
  systemd-remount-fs.service \
  systemd-udev-settle.service \
  systemd-udev-trigger.service \
  systemd-udevd.service \
  systemd-udevd-control.socket \
  systemd-udevd-kernel.socket \
  udisks2.service \
  upower.service \
  usb-gadget.target \
  usbmuxd.service && \
  systemctl mask --global \
  gvfs-mtp-volume-monitor.service \
  gvfs-udisks2-volume-monitor.service \
  obex.service \
  pipewire.service \
  pipewire.socket \
  pipewire-media-session.service \
  pipewire-pulse.service \
  pipewire-pulse.socket \
  wireplumber.service

# Copy the configuration files and scripts.
COPY rootfs/ /

# Workaround for the colord authentication issue.
# See: https://unix.stackexchange.com/a/581353
RUN systemctl enable fix-colord.service

RUN systemd-machine-id-setup
RUN xrdp-keygen xrdp /etc/xrdp/rsakeys.ini
RUN athena-motd -f /etc/issue

# Create and configure user
RUN groupadd sudo && \
  useradd  \
  --shell /bin/bash \
  -g users \
  -G sudo,lp,network,power,sys,wheel \
  --badname \
  -u "$PUID" \
  -d "/home/$PUSER" \
  -m -N "$PUSER"
RUN echo "$PUSER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$PUSER
RUN chmod 044 /etc/sudoers.d/$PUSER
RUN echo -e "$PUSER\n$PUSER" | passwd "$PUSER"
RUN sed -i "/export SHELL=/c\export SHELL=\$(which zsh)" /home/$PUSER/.bashrc
RUN echo -e "/bin/zsh\n/usr/bin/zsh" >> /etc/shells
RUN echo "exec zsh" >> /home/$PUSER/.bashrc

# Expose SSH and RDP ports.
EXPOSE 22
EXPOSE 3389

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
