#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202211071239-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  server.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Monday, Nov 07, 2022 12:39 EST
# @@File             :  server.sh
# @@Description      :  Script to setup server for CentOS/AlmaLinux/RockyLinux
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="server"
VERSION="202211071239-git"
USER="${SUDO_USER:-${USER}}"
HOME="${USER_HOME:-${HOME}}"
SRC_DIR="${BASH_SOURCE%/*}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
if [ "$1" = "--debug" ]; then shift 1 && set -xo pipefail && export SCRIPT_OPTS="--debug" && export _DEBUG="on"; fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if ! swapon --show 2>/dev/null | grep -v '^NAME ' | grep -q '^'; then
  echo "Creating and enabling swapfile"
  mkdir -p "/var/cache/swaps"
  dd if=/dev/zero of=/var/cache/swaps/swapFile bs=1024 count=1048576 &>/dev/null
  chmod 600 /var/cache/swaps/swapFile
  mkswap /var/cache/swaps/swapFile &>/dev/null
  swapon /var/cache/swaps/swapFile &>/dev/null
  if ! grep -q '/var/cache/swaps/swapFile' "/var/cache/swaps/swapFile"; then
    echo "/var/cache/swaps/swapFile swap swap defaults 0 0" >>/etc/fstab
  fi
  swapon --show 2>/dev/null | grep -v '^NAME ' | grep -q '^' && echo "Swap has been enabled"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
for pkg in sudo git curl wget; do
  command -v $pkg &>/dev/null || { printf '%b\n' "${CYAN}Installing $pkg${NC}" && yum install -yy -q $pkg &>/dev/null || exit 1; } || { echo "Failed to install $pkg" && exit 1; }
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ ! -d "/usr/local/share/CasjaysDev/scripts" ]; then
  git clone https://github.com/casjay-dotfiles/scripts /usr/local/share/CasjaysDev/scripts -q
  eval /usr/local/share/CasjaysDev/scripts/install.sh || { echo "Failed to initialize" && exit 1; }
  export PATH="/usr/local/share/CasjaysDev/scripts/bin:$PATH"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
SCRIPTSFUNCTURL="${SCRIPTSFUNCTURL:-https://github.com/casjay-dotfiles/scripts/raw/main/functions}"
SCRIPTSFUNCTDIR="${SCRIPTSFUNCTDIR:-/usr/local/share/CasjaysDev/scripts}"
SCRIPTSFUNCTFILE="${SCRIPTSFUNCTFILE:-system-installer.bash}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -f "../functions/$SCRIPTSFUNCTFILE" ]; then
  . "../functions/$SCRIPTSFUNCTFILE"
elif [ -f "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE" ]; then
  . "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE"
else
  curl -LSs "$SCRIPTSFUNCTURL/$SCRIPTSFUNCTFILE" -o "/tmp/$SCRIPTSFUNCTFILE" || exit 1
  . "/tmp/$SCRIPTSFUNCTFILE"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SCRIPT_OS="AlmaLinux"
SCRIPT_DESCRIBE="server"
GITHUB_USER="${GITHUB_USER:-casjay}"
DFMGR_CONFIGS="misc git tmux"
SYSTEMMGR_CONFIGS="cron ssh ssl"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SCRIPT_NAME="$APPNAME"
SCRIPT_NAME="${SCRIPT_NAME%.*}"
RELEASE_VER="$(grep --no-filename -s 'VERSION_ID=' /etc/*-release | awk -F '=' '{print $2}' | sed 's#"##g' | awk -F '.' '{print $1}' | grep '^')"
RELEASE_NAME="$(grep --no-filename -s '^NAME=' /etc/*-release | awk -F'=' '{print $2}' | sed 's|"||g;s| .*||g' | tr '[:upper:]' '[:lower:]' | grep '^')"
RELEASE_TYPE="$(grep --no-filename -s '^ID_LIKE=' /etc/*-release | awk -F'=' '{print $2}' | sed 's|"||g' | tr '[:upper:]' '[:lower:]' | tr ' ' '\n' | grep 'centos' | grep '^')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')"
BACKUP_DIR="$HOME/Documents/backups/$(date +'%Y/%m/%d')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SSH_KEY_LOCATION="${SSH_KEY_LOCATION:-https://github.com/$GITHUB_USER.keys}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SERVICES_ENABLE="cockpit cockpit.socket munin-node named ntpd php-fpm postfix proftpd rsyslog snmpd sshd tor uptimed"
SERVICES_DISABLE="avahi-daemon.service avahi-daemon.socket chrony cups.path cups.service cups.socket dhcpd dhcpd6 dm-event.socket fail2ban firewalld import-state.service irqbalance.service iscsi iscsid.socket iscsiuio.socket kdump loadmodules.service lvm2-lvmetad.socket lvm2-lvmpolld.socket lvm2-monitor mdmonitor multipathd.service multipathd.socket nfs-client.target nis-domainname.service radvd rpcbind.service rpcbind.socket shorewall shorewall6 sssd-kcm.socket timedatex.service tuned.service udisks2.service"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
grep --no-filename -sE '^ID=|^ID_LIKE=|^NAME=' /etc/*-release | grep -qiwE "$SCRIPT_OS" && true || printf_exit "This installer is meant to be run on a $SCRIPT_OS based system"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$1" == "--help" ] && printf_exit "${GREEN}${SCRIPT_DESCRIBE} installer for $SCRIPT_OS${NC}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
system_service_exists() { systemctl status "$1" 2>&1 | grep -iq "$1" && return 0 || return 1; }
system_service_enable() { systemctl status "$1" 2>&1 | grep -iq 'inactive' && execute "systemctl enable $1" "Enabling service: $1" || return 1; }
system_service_disable() { systemctl status "$1" 2>&1 | grep -iq 'active' && execute "systemctl disable --now $1" "Disabling service: $1" || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__dnf_yum() {
  local rhel_pkgmgr="" opts="--skip-broken"
  rhel_pkgmgr="$(builtin type -P dnf || builtin type -P yum || false)"
  [ "$RELEASE_VER" -lt 8 ] || opts="--allowerasing --nobest --skip-broken"
  $rhel_pkgmgr $opts "$@"
  if rpm -q "$pkg" | grep -v 'is not installed' | grep -q '^'; then exitCode=0; else exitCode=1; fi
  return $?
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
test_pkg() {
  for pkg in "$@"; do
    if rpm -q "$pkg" | grep -v 'is not installed' | grep -q '^'; then
      printf_blue "[ ✔ ] $pkg is already installed"
      return 1
    else
      return 0
    fi
  done
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
remove_pkg() {
  test_pkg "$*" &>/dev/null || execute "__dnf_yum remove -q -y $*" "Removing: $*"
  test_pkg "$*" &>/dev/null || return 0
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
install_pkg() {
  local statusCode=0
  if test_pkg "$*"; then
    execute "__dnf_yum install -q -yy $*" "Installing: $*"
    test_pkg "$*" &>/dev/null && statusCode=1 || statusCode=0
  else
    statusCode=0
  fi
  return $statusCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
detect_selinux() {
  if [ -f "/etc/selinux/config" ]; then
    grep -s 'SELINUX=' "/etc/selinux/config" | grep -q 'enabled' || return 1
  elif [ -f "$(type -P selinuxenabled 2>/dev/null)" ]; then
    selinuxenabled && return 1 || return 0
  else
    return 0
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
disable_selinux() {
  if detect_selinux; then
    printf_blue "selinux is now disabled"
    if [ -f "/etc/selinux/config" ]; then
      devnull setenforce 0
      sed -i 's|SELINUX=.*|SELINUX=disabled|g' "/etc/selinux/config"
    else
      mkdir -p "/etc/selinux"
      cat <<EOF | tee "/etc/selinux/config" &>/dev/null
#
SELINUX=disabled
SELINUXTYPE=targeted

EOF
    fi
  else
    printf_green "selinux is already disabled"
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
get_user_ssh_key() {
  local ssh_key=""
  [ -n "$SSH_KEY_LOCATION" ] || return 0
  [ -d "$HOME/.ssh" ] || mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  get_keys="$(curl -q -LSsf "$SSH_KEY_LOCATION" 2>/dev/null | grep '^' || false)"
  if [ -n "$get_keys" ]; then
    echo "$get_keys" | while read -r key; do
      if grep -qs "$key" "$HOME/.ssh/authorized_keys"; then
        printf_cyan "${key:0:80} exists in ~/.ssh/authorized_keys"
      else
        echo "$ssh_key" | tee -a "/root/.ssh/authorized_keys" &>/dev/null
        printf_green "Successfully added github ${key:0:80}"
      fi
    done
  else
    printf_return "Can not get key from $SSH_KEY_LOCATION"
    return 1
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
run_init_check() {
  { printf '%b\n' "${YELLOW}Updating cache and installing epel-release${NC}" && yum makecache &>/dev/null && __dnf_yum install epel-release -yy -q &>/dev/null; } || true
  if [ -d "/usr/local/share/CasjaysDev/scripts/.git" ]; then
    git -C /usr/local/share/CasjaysDev/scripts pull -q
    if [ $? -ne 0 ]; then
      git clone https://github.com/casjay-dotfiles/scripts /usr/local/share/CasjaysDev/scripts -q
    fi
  fi
  yum clean all &>/dev/null || true
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__yum() { yum "$@" $yum_opts &>/dev/null || return 1; }
grab_remote_file() { urlverify "$1" && curl -q -SLs "$1" || exit 1; }
backup_repo_files() { cp -Rf "/etc/yum.repos.d/." "$BACKUP_DIR" 2>/dev/null || return 0; }
rm_repo_files() { [ "${1:-$YUM_DELETE}" = "yes" ] && rm -Rf "/etc/yum.repos.d"/* &>/dev/null || return 0; }
run_external() { printf_green "Executing $*" && eval "$*" >/dev/null 2>&1 || return 1; }
save_remote_file() { urlverify "$1" && curl -q -SLs "$1" | tee "$2" &>/dev/null || exit 1; }
domain_name() { hostname -f | awk -F'.' '{$1="";OFS="." ; print $0}' | sed 's/^.//;s| |.|g' | grep '^'; }
retrieve_version_file() { grab_remote_file "https://github.com/casjay-base/centos/raw/main/version.txt" | head -n1 || echo "Unknown version"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf_head() {
  printf '%b##################################################\n' "$CYAN"
  printf '%b%s%b\n' $GREEN "$*" $CYAN
  printf '##################################################%b\n' $NC
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf_clear() {
  clear
  printf_head "$*"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
rm_if_exists() {
  local file_loc=("$@") && shift $#
  for file in "${file_loc[@]}"; do
    if [ -e "$file" ]; then
      execute "rm -Rf $file" "Removing $file"
    fi
  done
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
retrieve_repo_file() {
  local statusCode="0"
  local YUM_DELETE="true"
  yum clean all &>/dev/null
  if [ "$RELEASE_TYPE" = "centos" ] && [ "$(hostname -s)" != "pbx" ]; then
    if [ "$RELEASE_VER" -ge "9" ]; then
      YUM_DELETE="yes"
      REPO_REPLACE="no"
      RELEASE_FILE="https://github.com/rpm-devel/casjay-release/raw/main/casjay.rh9.repo"
    elif [ "$RELEASE_VER" -ge "8" ]; then
      YUM_DELETE="yes"
      REPO_REPLACE="yes"
      RELEASE_FILE="https://github.com/rpm-devel/casjay-release/raw/main/casjay.rh8.repo"
    elif [ "$RELEASE_VER" -lt "8" ]; then
      YUM_DELETE="yes"
      REPO_REPLACE="yes"
      RELEASE_FILE="https://github.com/rpm-devel/casjay-release/raw/main/casjay.rh.repo"
    else
      YUM_DELETE="no"
      RELEASE_FILE=""
    fi
  else
    yum makecache &>/dev/null
    return
  fi
  if [ -n "$RELEASE_FILE" ]; then
    printf '%b\n' "${YELLOW}Updating yum repos: This may take some time${NC}"
    backup_repo_files
    rm_repo_files "$YUM_DELETE"
    save_remote_file "$RELEASE_FILE" "/etc/yum.repos.d/casjay.repo"
    if [ "$ARCH" != "x86_64" ] && [ "$REPO_REPLACE" = "yes" ]; then
      sed -i 's|.*http://mirrors.elrepo.org/mirrors-elrepo.*|baseurl=https://rpm-devel.sourceforge.io/repo/RHEL/$releasever/$basearch/empty|g' /etc/yum.repos.d/casjay.repo
      sed -i 's|.*https://mirror.usi.edu/pub/remi/enterprise/.*|baseurl=https://rpm-devel.sourceforge.io/repo/RHEL/$releasever/$basearch/empty|g' /etc/yum.repos.d/casjay.repo
    fi
    yum makecache &>/dev/null || statusCode=1
  fi
  [ "$statusCode" -ne 0 ] || printf '%b\n' "${YELLOW}Done updating repos${NC}"
  return $statusCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
run_grub() {
  printf_green "Initializing grub configuration"
  local cfg="" efi="" grub_cfg="" grub_efi="" grub_bin="" grub_bin_name=""
  grub_cfg="$(find /boot/grub*/* -name 'grub*.cfg' | grep '^' || false)"
  grub_efi="$(find /boot/efi/EFI/* -name 'grub*.cfg' | grep '^' || false)"
  grub_bin="$(builtin type -P grub-mkconfig 2>/dev/null || builtin type -P grub2-mkconfig 2>/dev/null || false)"
  grub_bin_name="$(basename "$grub_bin" 2>/dev/null)"
  if [ -n "$grub_bin" ]; then
    rm_if_exists /boot/*rescue*
    if [ -n "$grub_cfg" ]; then
      for cfg in $grub_cfg; do
        if [ -e "$cfg" ]; then
          devnull $grub_bin -o "$cfg" && printf_green "Updated $cfg" || printf_return "Failed to update $cfg"
        fi
      done
    fi
    if [ -n "$grub_efi" ]; then
      for efi in $grub_efi; do
        if [ -e "$efi" ]; then
          devnull $grub_bin -o "$efi" && printf_green "Updated $efi" || printf_return "Failed to update $efi"
        fi
      done
    fi
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
run_post() {
  local e="$*"
  local m="${e//devnull /}"
  execute "$e" "executing: $m"
  setexitstatus
  set --
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
fix_network_device_name() {
  local device=""
  device="$(ip -4 route ls 2>/dev/null | grep default | grep -Po '(?<=dev )(\S+)' | head -n1 | grep '^' || echo 'eth0')"
  printf_green "Setting network device name to $device in $1"
  find "$1" -type f -exec sed -i 's|eth0|'$device'|g' {} +
}
##################################################################################################################
printf_clear "Initializing the installer for $RELEASE_NAME using $SCRIPT_DESCRIBE script"
##################################################################################################################
[ -d "/etc/casjaysdev/updates/versions" ] || mkdir -p "/etc/casjaysdev/updates/versions"
if [ -f "/etc/casjaysdev/updates/versions/$SCRIPT_NAME.txt" ]; then
  printf_red "$(<"/etc/casjaysdev/updates/versions/$SCRIPT_NAME.txt")"
  printf_red "To reinstall please remove the version file in"
  printf_red "/etc/casjaysdev/updates/versions/$SCRIPT_NAME.txt"
  exit 1
elif [ -f "/etc/casjaysdev/updates/versions/installed.txt" ]; then
  printf_red "$(<"/etc/casjaysdev/updates/versions/installed.txt")"
  printf_red "To reinstall please remove the version file in"
  printf_red "/etc/casjaysdev/updates/versions/installed.txt"
  exit 1
else
  run_init_check
  retrieve_repo_file || printf_exit "The script has failed to initialize"
  system_service_enable vnstat && systemctl start vnstat &>/dev/null
  [ -f "/etc/casjaysdev/updates/versions/os_version.txt" ] || echo "$RELEASE_VER" >"/etc/casjaysdev/updates/versions/os_version.txt"
fi
if ! builtin type -P systemmgr &>/dev/null; then
  run_external /usr/local/share/CasjaysDev/scripts/install.sh
  run_external /usr/local/share/CasjaysDev/scripts/bin/systemmgr --config
  run_external /usr/local/share/CasjaysDev/scripts/bin/systemmgr update scripts
  run_external "__yum clean all"
fi
printf_green "Installer has been initialized"
##################################################################################################################
printf_head "Disabling selinux"
##################################################################################################################
disable_selinux
##################################################################################################################
printf_head "Configuring cores for compiling"
##################################################################################################################
numberofcores=$(grep -c ^processor /proc/cpuinfo)
printf_yellow "Total cores avaliable: $numberofcores"
if [ -f /etc/makepkg.conf ]; then
  if [ $numberofcores -gt 1 ]; then
    sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'$(($numberofcores + 1))'"/g' /etc/makepkg.conf
    sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T '"$numberofcores"' -z -)/g' /etc/makepkg.conf
  fi
fi
##################################################################################################################
printf_head "Grabbing ssh key[s]: from $SSH_KEY_LOCATION for $USER"
##################################################################################################################
get_user_ssh_key
##################################################################################################################
printf_head "Configuring the system"
##################################################################################################################
run_external timedatectl set-timezone America/New_York
run_external yum update -q -yy --skip-broken
install_pkg net-tools
install_pkg wget
install_pkg curl
install_pkg git
install_pkg nail
install_pkg e2fsprogs
install_pkg redhat-lsb
install_pkg vim
install_pkg unzip
install_pkg cronie-noanacron
install_pkg bind-utils
for oci in 'oci*' 'cloud*' 'oracle*'; do __yum remove -yy -q "$oci" &>/dev/null; done
for rpms in echo chrony cronie-anacron sendmail sendmail-cf; do rpm -ev --nodeps $rpms &>/dev/null; done
retrieve_repo_file
rm_if_exists /tmp/dotfiles
rm_if_exists /root/anaconda-ks.cfg /var/log/anaconda
run_external yum update -q -yy --skip-broken
[ $RELEASE_VER -ge 9 ] && install_pkg glibc-langpack-en
##################################################################################################################
printf_head "Installing the packages for $RELEASE_NAME"
##################################################################################################################
install_pkg apr
install_pkg apr-util
install_pkg at
install_pkg attr
install_pkg authconfig
install_pkg autogen-libopts
install_pkg avahi
install_pkg awffull
install_pkg awstats
install_pkg basesystem
install_pkg bash
install_pkg bash-completion
install_pkg bc
install_pkg bind
install_pkg bind-libs
install_pkg bind-libs-lite
install_pkg bind-license
install_pkg bind-utils
install_pkg binutils
install_pkg biosdevname
install_pkg bison
install_pkg bridge-utils
install_pkg byobu
install_pkg bzip2
install_pkg bzip2-libs
install_pkg ca-certificates
install_pkg certbot
install_pkg checkpolicy
install_pkg chkconfig
install_pkg chrony
install_pkg cifs-utils
install_pkg cockpit
install_pkg cockpit-bridge
install_pkg cockpit-system
install_pkg cockpit-ws
install_pkg composer
install_pkg comps-extras
install_pkg coolkey
install_pkg coreutils
install_pkg cowsay
install_pkg cpio
install_pkg cpp
install_pkg cracklib
install_pkg cracklib-dicts
install_pkg createrepo
install_pkg cronie
install_pkg cronie-noanacron
install_pkg crontabs
install_pkg cryptsetup
install_pkg cryptsetup-libs
install_pkg cups-libs
install_pkg curl
install_pkg cyrus-sasl-gssapi
install_pkg cyrus-sasl-lib
install_pkg cyrus-sasl-plain
install_pkg dbus
install_pkg dbus-glib
install_pkg dbus-libs
install_pkg dbus-python
install_pkg dejavu-fonts-common
install_pkg dejavu-sans-mono-fonts
install_pkg deltarpm
install_pkg desktop-file-utils
install_pkg dhclient
install_pkg dhcp-common
install_pkg dhcp-libs
install_pkg dialog
install_pkg diffutils
install_pkg dmidecode
install_pkg dnsmasq
install_pkg dos2unix
install_pkg dosfstools
install_pkg downtimed
install_pkg dracut
install_pkg dracut-config-rescue
install_pkg dracut-network
install_pkg dwz
install_pkg ed
install_pkg elfutils
install_pkg elfutils-default-yama-scope
install_pkg elfutils-libelf
install_pkg elfutils-libs
install_pkg emacs-filesystem
install_pkg ethtool
install_pkg expat
install_pkg file
install_pkg file-libs
install_pkg filesystem
install_pkg findutils
install_pkg fipscheck
install_pkg fipscheck-lib
install_pkg firewalld
install_pkg firewalld-filesystem
install_pkg fontconfig
install_pkg fontpackages-filesystem
install_pkg fortune-mod
install_pkg fpaste
install_pkg freetype
install_pkg fuse
install_pkg fuse-libs
install_pkg fuse-sshfs
install_pkg fxload
install_pkg gawk
install_pkg gc
install_pkg gcc
install_pkg gd
install_pkg gdbm
install_pkg gdbm-devel
install_pkg gdisk
install_pkg gdk-pixbuf2
install_pkg gd-last
install_pkg GeoIP
install_pkg GeoIP-data
install_pkg gettext
install_pkg gettext-libs
install_pkg git
install_pkg glib2
install_pkg glibc
install_pkg glibc-common
install_pkg glibc-devel
install_pkg glibc-headers
install_pkg glib-networking
install_pkg gmp
install_pkg gnupg2
install_pkg gnupg2-smime
install_pkg gnutls
install_pkg gobject-introspection
install_pkg golang
install_pkg golang-bin
install_pkg golang-src
install_pkg gpgme
install_pkg gpm-libs
install_pkg grep
install_pkg groff-base
install_pkg grub2
install_pkg grub2-common
install_pkg grub2-pc
install_pkg grub2-pc-modules
install_pkg grub2-tools
install_pkg grub2-tools-extra
install_pkg grub2-tools-minimal
install_pkg grubby
install_pkg gssproxy
install_pkg guile
install_pkg gzip
install_pkg hardlink
install_pkg harfbuzz
install_pkg hdparm
install_pkg hostname
install_pkg htop
install_pkg httpd
install_pkg hunspell
install_pkg hunspell-en-US
install_pkg hwdata
install_pkg iftop
install_pkg info
install_pkg initscripts
install_pkg iproute
install_pkg iprutils
install_pkg ipset
install_pkg ipset-libs
install_pkg iptables
install_pkg iptstate
install_pkg iputils
install_pkg jasper-libs
install_pkg jbigkit-libs
install_pkg js-jquery
install_pkg json-c
install_pkg json-glib
install_pkg jwhois
install_pkg kexec-tools
install_pkg keyutils
install_pkg keyutils-libs
install_pkg kpartx
install_pkg krb5-libs
install_pkg less
install_pkg lm_sensors-libs
install_pkg logrotate
install_pkg lsof
install_pkg lua
install_pkg lvm2
install_pkg lvm2-libs
install_pkg lynx
install_pkg lyx-fonts
install_pkg lz4
install_pkg lzo
install_pkg m4
install_pkg mailcap
install_pkg mailx
install_pkg make
install_pkg man-db
install_pkg man-pages
install_pkg mesa-libEGL
install_pkg mesa-libgbm
install_pkg mesa-libGL
install_pkg mesa-libglapi
install_pkg mlocate
install_pkg mod_geoip
install_pkg mod_wsgi
install_pkg mozjs17
install_pkg mrtg
install_pkg mtr
install_pkg munin
install_pkg munin-common
install_pkg munin-node
install_pkg nano
install_pkg ncurses
install_pkg ncurses-base
install_pkg ncurses-libs
install_pkg neofetch
install_pkg net-snmp
install_pkg net-snmp-agent-libs
install_pkg net-snmp-libs
install_pkg net-snmp-utils
install_pkg nettle
install_pkg net-tools
install_pkg newt
install_pkg newt-python
install_pkg nfs-utils
install_pkg nginx
install_pkg nmap-ncat
install_pkg nodejs
install_pkg nspr
install_pkg nss
install_pkg nss-pem
install_pkg nss-softokn
install_pkg nss-softokn-freebl
install_pkg nss-sysinit
install_pkg nss-tools
install_pkg nss-util
install_pkg oddjob
install_pkg oddjob-mkhomedir
install_pkg openssh
install_pkg openssh-clients
install_pkg openssh-server
install_pkg openssl
install_pkg openssl-libs
install_pkg os-prober
install_pkg p11-kit
install_pkg p11-kit-trust
install_pkg PackageKit
install_pkg PackageKit-glib
install_pkg PackageKit-yum
install_pkg pam
install_pkg pango
install_pkg parted
install_pkg passwd
install_pkg pcre
install_pkg pcre2
install_pkg perl
install_pkg perl-Algorithm-Diff
install_pkg perl-Archive-Tar
install_pkg perl-Archive-Zip
install_pkg perl-Authen-SASL
install_pkg perl-autodie
install_pkg perl-B-Hooks-EndOfScope
install_pkg perl-BSD-Resource
install_pkg perl-Business-ISBN
install_pkg perl-Business-ISBN-Data
install_pkg perl-Cache-Cache
install_pkg perl-Cache-Memcached
install_pkg perl-Carp
install_pkg perl-Carp-Always
install_pkg perl-CGI
install_pkg perl-Class-Data-Inheritable
install_pkg perl-Class-Inspector
install_pkg perl-Class-Load
install_pkg perl-Class-Method-Modifiers
install_pkg perl-Class-Singleton
install_pkg perl-Compress-Raw-Bzip2
install_pkg perl-Compress-Raw-Zlib
install_pkg perl-constant
install_pkg perl-CPAN
install_pkg perl-CPAN-Meta
install_pkg perl-CPAN-Meta-Requirements
install_pkg perl-CPAN-Meta-YAML
install_pkg perl-Crypt-DES
install_pkg perl-Data-Dump
install_pkg perl-Data-Dumper
install_pkg perl-Data-OptList
install_pkg perl-Data-Section
install_pkg perl-Date-ISO8601
install_pkg perl-Date-Manip
install_pkg perl-DateTime
install_pkg perl-DateTime-Locale
install_pkg perl-DateTime-TimeZone
install_pkg perl-DateTime-TimeZone-SystemV
install_pkg perl-DateTime-TimeZone-Tzfile
install_pkg perl-DBD-MySQL
install_pkg perl-DBD-Pg
install_pkg perl-DB_File
install_pkg perl-DBI
install_pkg perl-devel
install_pkg perl-Devel-CallChecker
install_pkg perl-Devel-Caller
install_pkg perl-Devel-GlobalDestruction
install_pkg perl-Devel-LexAlias
install_pkg perl-Devel-StackTrace
install_pkg perl-Digest
install_pkg perl-Digest-HMAC
install_pkg perl-Digest-MD5
install_pkg perl-Digest-SHA
install_pkg perl-Digest-SHA1
install_pkg perl-Dist-CheckConflicts
install_pkg perl-DynaLoader-Functions
install_pkg perl-Email-Date-Format
install_pkg perl-Encode
install_pkg perl-Encode-Detect
install_pkg perl-Encode-Locale
install_pkg perl-Env
install_pkg perl-Error
install_pkg perl-Eval-Closure
install_pkg perl-Exception-Class
install_pkg perl-experimental
install_pkg perl-Exporter
install_pkg perl-Exporter-Tiny
install_pkg perl-ExtUtils-CBuilder
install_pkg perl-ExtUtils-Embed
install_pkg perl-ExtUtils-Install
install_pkg perl-ExtUtils-MakeMaker
install_pkg perl-ExtUtils-Manifest
install_pkg perl-ExtUtils-ParseXS
install_pkg perl-FCGI
install_pkg perl-File-Copy-Recursive
install_pkg perl-File-Fetch
install_pkg perl-File-HomeDir
install_pkg perl-File-Listing
install_pkg perl-File-Path
install_pkg perl-File-ShareDir
install_pkg perl-File-Temp
install_pkg perl-File-Which
install_pkg perl-Filter
install_pkg perl-GD
install_pkg perl-GD-Barcode
install_pkg perl-Geo-IP
install_pkg perl-Getopt-Long
install_pkg perl-Git
install_pkg perl-GSSAPI
install_pkg perl-HTML-Parser
install_pkg perl-HTML-Tagset
install_pkg perl-HTML-Template
install_pkg perl-HTTP-Cookies
install_pkg perl-HTTP-Daemon
install_pkg perl-HTTP-Date
install_pkg perl-HTTP-Message
install_pkg perl-HTTP-Negotiate
install_pkg perl-HTTP-ProxyAutoConfig
install_pkg perl-HTTP-Tiny
install_pkg perl-interpreter
install_pkg perl-IO-Compress
install_pkg perl-IO-HTML
install_pkg perl-IO-Multiplex
install_pkg perl-IO-Socket-INET6
install_pkg perl-IO-Socket-IP
install_pkg perl-IO-Socket-SSL
install_pkg perl-IO-Zlib
install_pkg perl-IPC-Cmd
install_pkg perl-IPC-ShareLite
install_pkg perl-IPC-System-Simple
install_pkg perl-JSON-PP
install_pkg perl-libs
install_pkg perl-libwww-perl
install_pkg perl-Linux-Pid
install_pkg perl-List-MoreUtils
install_pkg perl-Locale-Codes
install_pkg perl-Locale-Maketext
install_pkg perl-Locale-Maketext-Simple
install_pkg perl-local-lib
install_pkg perl-Log-Dispatch
install_pkg perl-Log-Dispatch-FileRotate
install_pkg perl-Log-Log4perl
install_pkg perl-LWP-MediaTypes
install_pkg perl-LWP-Protocol-https
install_pkg perl-macros
install_pkg perl-Mail-Sender
install_pkg perl-Mail-Sendmail
install_pkg perl-MailTools
install_pkg perl-MIME-Lite
install_pkg perl-MIME-Types
install_pkg perl-Module-Build
install_pkg perl-Module-CoreList
install_pkg perl-Module-Implementation
install_pkg perl-Module-Load
install_pkg perl-Module-Load-Conditional
install_pkg perl-Module-Loaded
install_pkg perl-Module-Metadata
install_pkg perl-Module-Runtime
install_pkg perl-Mozilla-CA
install_pkg perl-MRO-Compat
install_pkg perl-namespace-autoclean
install_pkg perl-namespace-clean
install_pkg perl-Net-CIDR
install_pkg perl-Net-Daemon
install_pkg perl-Net-DNS
install_pkg perl-Net-HTTP
install_pkg perl-Net-IP
install_pkg perl-Net-LibIDN
install_pkg perl-Net-Server
install_pkg perl-Net-SMTP-SSL
install_pkg perl-Net-SNMP
install_pkg perl-Net-SSLeay
install_pkg perl-Net-XMPP
install_pkg perl-NTLM
install_pkg perl-Package-Constants
install_pkg perl-Package-DeprecationManager
install_pkg perl-Package-Generator
install_pkg perl-Package-Stash
install_pkg perl-Package-Stash-XS
install_pkg perl-PadWalker
install_pkg perl-Params-Check
install_pkg perl-Params-Classify
install_pkg perl-Params-Util
install_pkg perl-Params-Validate
install_pkg perl-parent
install_pkg perl-Parse-CPAN-Meta
install_pkg perl-PathTools
install_pkg perl-Perl-OSType
install_pkg perl-PlRPC
install_pkg perl-Pod-Checker
install_pkg perl-Pod-Escapes
install_pkg perl-podlators
install_pkg perl-Pod-Parser
install_pkg perl-Pod-Perldoc
install_pkg perl-Pod-Simple
install_pkg perl-Pod-Usage
install_pkg perl-Ref-Util
install_pkg perl-Ref-Util-XS
install_pkg perl-Role-Tiny
install_pkg perl-Scalar-List-Utils
install_pkg perl-SNMP_Session
install_pkg perl-Socket
install_pkg perl-Socket6
install_pkg perl-Software-License
install_pkg perl-srpm-macros
install_pkg perl-Storable
install_pkg perl-String-CRC32
install_pkg perl-Sub-Exporter
install_pkg perl-Sub-Exporter-Progressive
install_pkg perl-Sub-Identify
install_pkg perl-Sub-Install
install_pkg perl-Sub-Name
install_pkg perl-Switch
install_pkg perl-Sys-Syslog
install_pkg perl-Taint-Runtime
install_pkg perl-TermReadKey
install_pkg perl-Test-Harness
install_pkg perl-Test-Simple
install_pkg perl-Text-Diff
install_pkg perl-Text-Glob
install_pkg perl-Text-ParseWords
install_pkg perl-Text-Template
install_pkg perl-Thread-Queue
install_pkg perl-threads
install_pkg perl-threads-shared
install_pkg perltidy
install_pkg perl-TimeDate
install_pkg perl-Time-HiRes
install_pkg perl-Time-Local
install_pkg perl-Time-Piece
install_pkg perl-Try-Tiny
install_pkg perl-URI
install_pkg perl-Variable-Magic
install_pkg perl-version
install_pkg perl-WWW-RobotRules
install_pkg perl-XML-DOM
install_pkg perl-XML-LibXML
install_pkg perl-XML-NamespaceSupport
install_pkg perl-XML-Parser
install_pkg perl-XML-RegExp
install_pkg perl-XML-SAX
install_pkg perl-XML-SAX-Base
install_pkg perl-XML-Stream
install_pkg php
install_pkg php-cli
install_pkg php-common
install_pkg php-fpm
install_pkg php-gd
install_pkg php-gmp
install_pkg php-intl
install_pkg php-mbstring
install_pkg php-mysqlnd
install_pkg php-pdo
install_pkg php-pecl-geoip
install_pkg php-pecl-zendopcache
install_pkg php-pgsql
install_pkg php-xml
install_pkg pinentry
install_pkg pinfo
install_pkg pixman
install_pkg pkgconfig
install_pkg plymouth
install_pkg plymouth-core-libs
install_pkg plymouth-scripts
install_pkg ponysay
install_pkg popt
install_pkg postfix
install_pkg proftpd
install_pkg psacct
install_pkg pygobject2
install_pkg pygpgme
install_pkg pyliblzma
install_pkg pyOpenSSL
install_pkg pyparsing
install_pkg pytalloc
install_pkg python
install_pkg python2-acme
install_pkg python2-certbot
install_pkg python2-certbot-apache
install_pkg python2-certbot-dns-rfc2136
install_pkg python2-configargparse
install_pkg python2-cryptography
install_pkg python2-enum34
install_pkg python2-funcsigs
install_pkg python2-future
install_pkg python2-idna
install_pkg python2-josepy
install_pkg python2-mock
install_pkg python2-parsedatetime
install_pkg python2-pbr
install_pkg python2-pip
install_pkg python2-psutil
install_pkg python2-pyasn1
install_pkg python2-pyrfc3339
install_pkg python2-pysocks
install_pkg python2-requests
install_pkg python2-six
install_pkg python2-speedtest-cli
install_pkg python2-zope-interface
install_pkg python36-pillow-devel
install_pkg python-augeas
install_pkg python-backports
install_pkg python-backports-ssl_match_hostname
install_pkg python-cffi
install_pkg python-chardet
install_pkg python-configobj
install_pkg python-dateutil
install_pkg python-decorator
install_pkg python-deltarpm
install_pkg python-dmidecode
install_pkg python-dns
install_pkg python-enum34
install_pkg python-ethtool
install_pkg python-firewall
install_pkg python-gobject-base
install_pkg python-idna
install_pkg python-iniparse
install_pkg python-inotify
install_pkg python-ipaddress
install_pkg python-IPy
install_pkg python-kitchen
install_pkg python-libs
install_pkg python-ndg_httpsclient
install_pkg python-perf
install_pkg python-ply
install_pkg python-pycparser
install_pkg python-pycurl
install_pkg python-pyudev
install_pkg python-requests
install_pkg python-requests-toolbelt
install_pkg python-setuptools
install_pkg python-six
install_pkg python-slip
install_pkg python-slip-dbus
install_pkg python-srpm-macros
install_pkg python-sssdconfig
install_pkg python-urlgrabber
install_pkg python-urllib3
install_pkg python-virtualenvwrapper
install_pkg python-zope-component
install_pkg python-zope-event
install_pkg python-zope-interface
install_pkg pytz
install_pkg pyxattr
install_pkg qrencode-libs
install_pkg quota
install_pkg quota-nls
install_pkg rdma-core
install_pkg readline
install_pkg realmd
install_pkg recode
install_pkg redhat-rpm-config
install_pkg rootfiles
install_pkg rpm
install_pkg rpm-build-libs
install_pkg rpm-libs
install_pkg rpm-plugin-systemd-inhibit
install_pkg rpm-python
install_pkg rrdtool
install_pkg rrdtool-perl
install_pkg rsync
install_pkg rsync-daemon
install_pkg rsyslog
install_pkg samba
install_pkg satyr
install_pkg screen
install_pkg sed
install_pkg sendxmpp
install_pkg setools-libs
install_pkg setup
install_pkg setuptool
install_pkg shadow-utils
install_pkg shared-mime-info
install_pkg slang
install_pkg smartmontools
install_pkg snappy
install_pkg sos
install_pkg sqlite
install_pkg stix-fonts
install_pkg sudo
install_pkg symlinks
install_pkg system-config-users
install_pkg sysstat
install_pkg systemd
install_pkg systemd-libs
install_pkg systemd-python
install_pkg systemd-sysv
install_pkg systemtap-sdt-devel
install_pkg sysvinit-tools
install_pkg t1lib
install_pkg tar
install_pkg tcpdump
install_pkg tcp_wrappers
install_pkg tcp_wrappers-libs
install_pkg telnet
install_pkg time
install_pkg tmux
install_pkg tmux-powerline
install_pkg tmux-top
install_pkg tor
install_pkg traceroute
install_pkg tree
install_pkg trousers
install_pkg tzdata
install_pkg udisks2
install_pkg udisks2-iscsi
install_pkg udisks2-lvm2
install_pkg unzip
install_pkg uptimed
install_pkg usb_modeswitch
install_pkg usb_modeswitch-data
install_pkg usbutils
install_pkg usermode
install_pkg util-linux
install_pkg vconfig
install_pkg vnstat
install_pkg volume_key-libs
install_pkg webalizer
install_pkg wget
install_pkg which
install_pkg whois
install_pkg wireless-tools
install_pkg words
install_pkg wpa_supplicant
install_pkg xdg-utils
install_pkg xfsprogs
install_pkg xkeyboard-config
install_pkg xmlrpc-c
install_pkg xmlrpc-c-client
install_pkg xorg-x11-xauth
install_pkg xz
install_pkg xz-libs
install_pkg yarn
install_pkg yum
install_pkg yum-metadata-parser
install_pkg yum-plugin-fastestmirror
install_pkg yum-utils
install_pkg zip
install_pkg zlib
##################################################################################################################
printf_head "Setting up grub"
##################################################################################################################
run_grub
##################################################################################################################
printf_head "Deleting files"
##################################################################################################################
rm -Rf /etc/named* /var/named/* /etc/ntp* /etc/cron*/0* /etc/cron*/dailyjobs /var/ftp/uploads /etc/httpd/conf.d/ssl.conf /tmp/configs
##################################################################################################################
printf_head "Installing custom system configs"
##################################################################################################################
run_post "systemmgr install $SYSTEMMGR_CONFIGS"
##################################################################################################################
printf_head "Installing custom dotfiles"
##################################################################################################################
run_post "dfmgr install $DFMGR_CONFIGS"
##################################################################################################################
printf_head "setting up config files"
##################################################################################################################
NETDEV="$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")"
[ -n "$NETDEV" ] && mycurrentipaddress_6="$(ifconfig $NETDEV | grep -E 'venet|inet' | grep -v 'docker' | grep inet6 | grep -i 'global' | awk '{print $2}' | head -n1 | grep '^')" || mycurrentipaddress_6="$(hostname -I | tr ' ' '\n' | grep -Ev '^::1|^$' | grep ':.*:' | head -n1 | grep '^' || echo '::1')"
[ -n "$NETDEV" ] && mycurrentipaddress_4="$(ifconfig $NETDEV | grep -E 'venet|inet' | grep -v '127.0.0.' | grep inet | grep -v 'inet6' | awk '{print $2}' | sed 's#addr:##g' | head -n1 | grep '^')" || mycurrentipaddress_4="$(hostname -I | tr ' ' '\n' | grep -vE '|127\.0\.0|172\.17\.0|:.*:|^$' | head -n1 | grep '[0-9]\.[0-9]' || echo '127.0.0.1')"
set_domainname="$(hostname -f | awk -F '.' '{$1="";OFS="." ; print $0}' | sed 's/^.//' | tr ' ' '.' | grep '^' || hostname -f)"
devnull git clone -q "https://github.com/casjay-base/centos" "/tmp/configs"
devnull git clone -q "https://github.com/phpsysinfo/phpsysinfo" "/var/www/html/sysinfo"
devnull git clone -q "https://github.com/solbu/vnstat-php-frontend" "/var/www/html/vnstat"
devnull find /tmp/configs -type f -iname "*.sh" -exec chmod 755 {} \;
devnull find /tmp/configs -type f -iname "*.pl" -exec chmod 755 {} \;
devnull find /tmp/configs -type f -iname "*.cgi" -exec chmod 755 {} \;
devnull find /tmp/configs -type f -exec sed -i "s#mycurrentipaddress_4#$mycurrentipaddress_4#g" {} \;
devnull find /tmp/configs -type f -exec sed -i "s#mycurrentipaddress_6#$mycurrentipaddress_6#g" {} \;
devnull find /tmp/configs -type f -exec sed -i "s#myserverdomainname#$(hostname -f)#g" {} \;
devnull find /tmp/configs -type f -exec sed -i "s#myhostnameshort#$(hostname -s)#g" {} \;
devnull find /tmp/configs -type f -exec sed -i "s#mydomainname#$set_domainname#g" {} \;
[ -n "$NETDEV" ] && devnull find -L /tmp/configs -type f -exec sed -i "s#mynetworkdevice#$NETDEV#g" {} \; || devnull find -L /tmp/configs -type f -exec sed -i "s#mynetworkdevice#eth0#g" {} \;
[ -n "$NETDEV" ] && [ -f "/etc/sysconfig/network-scripts/ifcfg-eth0.sample" ] && devnull mv -f "/etc/sysconfig/network-scripts/ifcfg-eth0.sample" "/etc/sysconfig/network-scripts/ifcfg-$NETDEV.sample"
#devnull rm -Rf /tmp/configs/etc/{fail2ban,shorewall,shorewall6}
devnull mkdir -p /etc/rsync.d /var/log/named
devnull cp -Rf /tmp/configs/{etc,root,usr,var}* /
devnull sed -i "s#myserverdomainname#$HOSTNAME#g" /etc/sysconfig/network
devnull sed -i "s#mydomain#$set_domainname#g" /etc/sysconfig/network
devnull chown -Rf named:named /etc/named* /var/named /var/log/named
devnull chown -Rf apache:apache /var/www /usr/local/share/httpd
devnull chmod 644 -Rf /etc/cron.d/* /etc/logrotate.d/*
devnull touch /etc/postfix/mydomains.pcre
devnull chattr +i /etc/resolv.conf
if devnull postmap /etc/postfix/transport /etc/postfix/canonical /etc/postfix/virtual /etc/postfix/mydomains; then
  newaliases &>/dev/null || newaliases.postfix -I &>/dev/null
fi
if ! grep -sq 'kernel.domainname' "/etc/sysctl.conf"; then
  echo "kernel.domainname=$domainname_sysctl" >>/etc/sysctl.conf
fi
sudo -HE STATICSITE="$(hostname -f)" bash -c "$(curl -LSs "https://github.com/casjay-templates/default-web-assets/raw/main/setup.sh")"
##################################################################################################################
printf_head "Installing custom dotfiles"
##################################################################################################################
printf_head "Enabling services"
##################################################################################################################
for service_enable in $SERVICES_ENABLE; do
  [ -n "$service_enable" ] && system_service_enable $service_enable
done
##################################################################################################################
printf_head "Disabling services"
##################################################################################################################
for service_disable in $SERVICES_DISABLE; do
  [ -n "$service_disable" ] && system_service_disable $service_disable
done
##################################################################################################################
printf_head "Cleaning up"
##################################################################################################################
system_service_enable httpd
system_service_enable nginx
[ -f "/etc/yum/pluginconf.d/subscription-manager.conf" ] && echo "" >"/etc/yum/pluginconf.d/subscription-manager.conf"
find / -iname '*.rpmnew' -exec rm -Rf {} \;
find / -iname '*.rpmsave' -exec rm -Rf {} \;
rm -Rf /tmp/*.tar /tmp/dotfiles /tmp/configs
/root/bin/changeip.sh >/dev/null 2>&1
mkdir -p /mnt/backups /var/www/html/.well-known /etc/letsencrypt/live
echo "" >>/etc/fstab
#echo "10.0.254.1:/mnt/Volume_1/backups         /mnt/backups                 nfs defaults,rw 0 0" >> /etc/fstab
#echo "10.0.254.1:/var/www/html/.well-known     /var/www/html/.well-known    nfs defaults,rw 0 0" >> /etc/fstab
#echo "10.0.254.1:/etc/letsencrypt              /etc/letsencrypt             nfs defaults,rw 0 0" >> /etc/fstab
#mount -a
update-ca-trust && update-ca-trust extract
# If using letsencrypt certificates
chmod 600 /etc/named/certbot-update.conf
if [ -d "/etc/letsencrypt/live/$set_domainname" ] || [ -d "/etc/letsencrypt/live/domain" ]; then
  [ -d "/etc/letsencrypt/live/domain" ] || ln -sf "/etc/letsencrypt/live/$set_domainname" /etc/letsencrypt/live/domain
  find /etc/postfix /etc/httpd /etc/nginx -type f -exec sed -i 's#/etc/ssl/CA/CasjaysDev/certs/localhost.crt#/etc/letsencrypt/live/domain/fullchain.pem#g' {} \;
  find /etc/postfix /etc/httpd /etc/nginx -type f -exec sed -i 's#/etc/ssl/CA/CasjaysDev/private/localhost.key#/etc/letsencrypt/live/domain/privkey.pem#g' {} \;
  if [ -d "/etc/cockpit/ws-certs.d" ]; then
    rm -Rf "/etc/cockpit/ws-certs.d"/*.pem
    cat /etc/letsencrypt/live/domain/fullchain.pem >/etc/cockpit/ws-certs.d/1-my-cert.cert
    cat /etc/letsencrypt/live/domain/privkey.pem >>/etc/cockpit/ws-certs.d/1-my-cert.cert
  fi
else
  # If using self-signed certificates
  find /etc/postfix /etc/httpd /etc/cockpit/ws-certs.d -type f -exec sed -i 's#/etc/letsencrypt/live/domain/fullchain.pem#/etc/ssl/CA/CasjaysDev/certs/localhost.crt#g' {} \;
  find /etc/postfix /etc/httpd /etc/cockpit/ws-certs.d -type f -exec sed -i 's#/etc/letsencrypt/live/domain/privkey.pem#/etc/ssl/CA/CasjaysDev/private/localhost.key#g' {} \;
fi
bash -c "$(munin-node-configure --remove-also --shell >/dev/null 2>&1)"
if [ -f /var/lib/tor/hidden_service/hostname ]; then
  cp -Rf /var/lib/tor/hidden_service/hostname /var/www/html/tor_hostname
fi
if [ "$(hostname -s)" != "pbx" ]; then
  retrieve_repo_file
fi
chown -Rf apache:apache /var/www
history -c && history -w

##################################################################################################################
printf_head "Installer version: $(retrieve_version_file)"
##################################################################################################################
mkdir -p "/etc/casjaysdev/updates/versions"
echo "$VERSION" >"/etc/casjaysdev/updates/versions/configs.txt"
echo "$(date +'Installed on %y-%m-%d at %H:%M')" >"/etc/casjaysdev/updates/versions/installed.txt"
echo "Installed on $(date +'%Y-%m-%d at %H:%M %Z')" >"/etc/casjaysdev/updates/versions/$SCRIPT_NAME.txt"
chmod -Rf 664 "/etc/casjaysdev/updates/versions/configs.txt"
chmod -Rf 664 "/etc/casjaysdev/updates/versions/installed.txt"

##################################################################################################################
printf_head "Finished "
echo ""
##################################################################################################################
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
set --
exit
# end
