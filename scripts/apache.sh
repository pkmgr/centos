#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202211071239-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  apache.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Monday, Nov 07, 2022 12:39 EST
# @@File             :  apache.sh
# @@Description      :  Script to setup apache for CentOS/AlmaLinux/RockyLinux
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="apache"
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
SCRIPT_DESCRIBE="apache"
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
SERVICES_ENABLE="cockpit cockpit.socket httpd munin-node php-fpm postfix sshd"
SERVICES_DISABLE="avahi-daemon.service avahi-daemon.socket chrony cups.path cups.service cups.socket dhcpd dhcpd6 dm-event.socket fail2ban firewalld import-state.service irqbalance.service iscsi iscsid.socket iscsiuio.socket kdump loadmodules.service lvm2-lvmetad.socket lvm2-lvmpolld.socket lvm2-monitor mdmonitor multipathd.service multipathd.socket nfs-client.target nis-domainname.service qemu-guest-agent.service radvd rpcbind.service rpcbind.socket shorewall shorewall6 sssd-kcm.socket timedatex.service tuned.service udisks2.service"
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
  local rhel_pkgmgr="" opts="--skip-broken" exitCode=0
  rhel_pkgmgr="$(builtin type -P dnf || builtin type -P yum || false)"
  [ "$RELEASE_VER" -lt 8 ] || opts="--allowerasing --nobest --skip-broken"
  $rhel_pkgmgr $opts "$@"
  if rpm -q "$pkg" | grep -v 'is not installed' | grep -q '^'; then exitCode=0; else exitCode=1; fi
  return $exitCode
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
      REPO_REPLACE="no"
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
install_pkg awstats
install_pkg cockpit
install_pkg cockpit-bridge
install_pkg cockpit-system
install_pkg cockpit-ws
install_pkg composer
install_pkg hostname
install_pkg httpd
install_pkg httpd-filesystem
install_pkg httpd-tools
install_pkg http-parser
install_pkg mod_fcgid
install_pkg mod_geoip
install_pkg mod_http2
install_pkg mod_maxminddb
install_pkg mod_perl
install_pkg mod_ssl
install_pkg mod_wsgi
install_pkg mod_proxy_html
install_pkg mod_proxy_uwsgi
install_pkg mrtg
install_pkg munin
install_pkg munin-common
install_pkg munin-node
install_pkg openssh-server
install_pkg openssl
install_pkg openssl-libs
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
install_pkg postfix
install_pkg proftpd
install_pkg python2-acme
install_pkg python2-certbot
install_pkg python2-certbot-apache
install_pkg python2-certbot-dns-rfc2136
install_pkg quota
install_pkg webalizer
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
devnull find /tmp/configs -type f -exec sed -i "s#mycurrentipaddress_4#$mycurrentipaddress_4#g" {} \; &>/dev/null
devnull find /tmp/configs -type f -exec sed -i "s#mycurrentipaddress_6#$mycurrentipaddress_6#g" {} \; &>/dev/null
devnull find /tmp/configs -type f -exec sed -i "s#myserverdomainname#$(hostname -f)#g" {} \;
devnull find /tmp/configs -type f -exec sed -i "s#myhostnameshort#$(hostname -s)#g" {} \;
devnull find /tmp/configs -type f -exec sed -i "s#mydomainname#$set_domainname#g" {} \;
devnull mkdir -p /etc/rsync.d /var/log/named
devnull cp -Rf /tmp/configs/etc/{php,httpd}* "/etc/"
devnull cp -Rf "/tmp/configs/var/www/." "/var/www/"
devnull cp -Rf "/tmp/configs/root/." "/root/"
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
if [ -d /etc/letsencrypt/live/$(domainname) ] || [ -d /etc/letsencrypt/live/domain ]; then
  ln -s /etc/letsencrypt/live/$(domainname) /etc/letsencrypt/live/domain
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
