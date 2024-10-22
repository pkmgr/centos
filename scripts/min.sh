#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202211071239-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  min.oci.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Monday, Nov 07, 2022 12:39 EST
# @@File             :  min.oci.sh
# @@Description      :  Script to setup min.oci for CentOS/AlmaLinux/RockyLinux
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  yes
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="min"
VERSION="202211071239-git"
USER="${SUDO_USER:-${USER}}"
HOME="${USER_HOME:-${HOME}}"
SRC_DIR="${BASH_SOURCE%/*}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
if [ "$1" = "--debug" ]; then shift 1 && set -xo pipefail && export SCRIPT_OPTS="--debug" && export _DEBUG="on"; fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ ! -d "/etc/casjaysdev" ]; then
  if yum makecache && yum update -yy; then
    echo "Rebooting your system: Please rerun this script after reboot"
    mkdir -p "/etc/casjaysdev"
    sleep 20 && reboot
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -z "$(type -P ifconfig)" ] && [ -z "$(type -P hostname)" ]; then
  echo "Installing net-tools package"
  yum install -yy net-tools -q
fi
for pkg in sudo git curl wget; do
  command -v $pkg &>/dev/null || { echo "Installing $pkg" && yum install -yy -q $pkg &>/dev/null || exit 1; } || { echo "Failed to install $pkg" && exit 1; }
done
unset pkg
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
read -t 30 -p "Enter your full hostname: (default: $HOSTNAME) " set_hostname
set_hostname="${set_hostname:=$HOSTNAME}"
if [ -n "$set_hostname" ]; then
  hostnamectl set-hostname $set_hostname && echo "$set_hostname" >/etc/hostname || false
  [ $? -eq 0 ] && [ -n "$(type -P hostname)" ] && hostname -F /etc/hostname
  unset set_hostname
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -n "$(type systemd-ask-password)" ]; then
  root_pass_1="$(systemd-ask-password --emoji=no --echo=masked --timeout=30 "Enter your root password: ")"
  root_pass_2="$(systemd-ask-password --emoji=no --echo=masked --timeout=30 "Confirm your root password: ")"
else
  stty -echo
  printf "Enter your root password: " && read -t 30 -s root_pass_1
  printf '\n'
  printf "Confirm your root password: " && read -t 30 -s root_pass_2
  printf '\n'
  stty echo
fi
if [ -n "$root_pass_1" ]; then
  if [ "$root_pass_1" = "$root_pass_2" ]; then
    echo "$root_pass_1" | passwd --stdin root >/dev/null
  fi
fi
unset root_pass_1 root_pass_2
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SWAP_SIZE="$(swapon --show=SIZE --noheadings | sed 's/[0-9]//g' | head -n1 | grep 'M' || swapon --show=SIZE --noheadings | sed 's/[0-9]//g' | head -n1 | grep 'G' || false)"
if [ "$SWAP_SIZE" != "G" ]; then
  swap_file_size="4096"
  swap_file="swapFile"
  swap_dir="/var/cache/swaps"
  kilobit="2000000"
  gigabit=$((kilobit / 1000))
  mem="$(free | grep ':' | awk '{print $2}' | head -n1 | grep '^' || echo "1")"
  if [ $mem -le $kilobit ] && [ ! -f "$swap_dir/$swap_file" ]; then
    echo "Setting up swap in $swap_dir/$swap_file"
    echo "This may take a few minutes so enjoy your coffee"
    mkdir -p "$swap_dir"
    if dd if=/dev/zero of=$swap_dir/$swap_file bs=1MB count=$swap_file_size &>/dev/null; then
      echo "swap size is: ${swap_file_size}MB"
      chmod 600 $swap_dir/$swap_file
      mkswap $swap_dir/$swap_file >/dev/null
      swapon $swap_dir/$swap_file >/dev/null
      if ! grep -qs "$swap_dir/$swap_file" /etc/fstab; then
        echo "$swap_dir/$swap_file          swap        swap             defaults          0 0" | tee -a /etc/fstab >/dev/null
      fi
    fi
  fi
  unset SWAP_SIZE swap_file_size swap_file swap_dir kilobit gigabit mem
  swapon --show 2>/dev/null | grep -v '^NAME ' | grep -q '^' && echo "Swap has been enabled"
  sleep 5
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ ! -d "/usr/local/share/CasjaysDev/scripts" ]; then
  git clone "https://github.com/casjay-dotfiles/scripts" "/usr/local/share/CasjaysDev/scripts" -q
  eval "/usr/local/share/CasjaysDev/scripts/install.sh" || { echo "Failed to initialize" && exit 1; }
  export PATH="/usr/local/share/CasjaysDev/scripts/bin:$PATH"
  sleep 5
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
SCRIPT_DESCRIBE="Minimal"
GITHUB_USER="${GITHUB_USER:-casjay}"
DFMGR_CONFIGS="misc vim bash git tmux"
SYSTEMMGR_CONFIGS="cron ssh ssl"
SET_HOSTNAME="$([ -n "$(command -v hostname)" ] && hostname -s 2>/dev/null | grep '^' || echo "${HOSTNAME//.*/}")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SCRIPT_NAME="$APPNAME"
SCRIPT_NAME="${SCRIPT_NAME%.*}"
RELEASE_VER="$(grep --no-filename -s 'VERSION_ID=' /etc/*-release | awk -F '=' '{print $2}' | sed 's#"##g' | awk -F '.' '{print $1}' | grep '^')"
RELEASE_NAME="$(grep --no-filename -s '^NAME=' /etc/*-release | awk -F'=' '{print $2}' | sed 's|"||g;s| .*||g' | tr '[:upper:]' '[:lower:]' | grep '^')"
RELEASE_TYPE="$(grep --no-filename -s '^ID_LIKE=' /etc/*-release | awk -F'=' '{print $2}' | sed 's|"||g' | tr '[:upper:]' '[:lower:]' | tr ' ' '\n' | grep 'centos' | grep '^')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
DEFAULT_KERNEL="${DEFAULT_KERNEL:-kernel-ml}"
ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')"
BACKUP_DIR="$HOME/Documents/backups/$(date +'%Y/%m/%d')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SSH_KEY_LOCATION="${SSH_KEY_LOCATION:-https://github.com/$GITHUB_USER.keys}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if echo "${SET_HOSTNAME:-$HOSTNAME}" | grep -qE '^pbx'; then
  SYSTEM_TYPE="pbx"
elif echo "${SET_HOSTNAME:-$HOSTNAME}" | grep -qE '^dns'; then
  SYSTEM_TYPE="dns"
elif echo "${SET_HOSTNAME:-$HOSTNAME}" | grep -qE '^vpn'; then
  SYSTEM_TYPE="vpn"
elif echo "${SET_HOSTNAME:-$HOSTNAME}" | grep -qE '^mail'; then
  SYSTEM_TYPE="mail"
elif echo "${SET_HOSTNAME:-$HOSTNAME}" | grep -qE '^server'; then
  SYSTEM_TYPE="server"
elif echo "${SET_HOSTNAME:-$HOSTNAME}" | grep -qE '^sql|^db'; then
  SYSTEM_TYPE="sql"
elif echo "${SET_HOSTNAME:-$HOSTNAME}" | grep -qE '^devel|^build|^ci|^testing'; then
  SYSTEM_TYPE="devel"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SERVICES_ENABLE="cockpit cockpit.socket docker httpd munin-node nginx ntpd php-fpm postfix proftpd rsyslog snmpd sshd uptimed downtimed"
SERVICES_DISABLE="avahi-daemon.service avahi-daemon.socket cups.path cups.service cups.socket dhcpd dhcpd6 dm-event.socket fail2ban firewalld import-state.service irqbalance.service iscsi iscsid.socket iscsiuio.socket kdump loadmodules.service lvm2-lvmetad.socket lvm2-lvmpolld.socket lvm2-monitor mdmonitor multipathd.service multipathd.socket named nfs-client.target nis-domainname.service nmb radvd rpcbind.service rpcbind.socket shorewall shorewall6 smb sssd-kcm.socket timedatex.service tuned.service udisks2.service"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
grep --no-filename -sE '^ID=|^ID_LIKE=|^NAME=' /etc/*-release | grep -qiwE "$SCRIPT_OS" && true || printf_exit "This installer is meant to be run on a $SCRIPT_OS based system"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$1" == "--help" ] && printf_exit "${GREEN}${SCRIPT_DESCRIBE} installer for $SCRIPT_OS${NC}"
port_in_use() { netstatg 2>&1 | awk '{print $4}' | grep ':[0-9]' | awk -F':' '{print $2}' | grep '[0-9]' | grep -q "^$1$" || return 2; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
system_service_exists() { systemctl status "$1" 2>&1 | grep 'Loaded:' | grep -iq "$1" && return 0 || return 1; }
system_service_active() { (systemctl is-enabled "$1" || systemctl is-active "$1") | grep -qiE 'enabled|active' || return 1; }
system_service_enable() { systemctl status "$1" 2>&1 | grep -iq 'inactive' && execute "systemctl enable --now $1" "Enabling service: $1" || return 1; }
system_service_disable() { systemctl status "$1" 2>&1 | grep -iq 'active' && execute "systemctl disable --now $1" "Disabling service: $1" || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
does_user_exist() { grep -qs "^$1:" "/etc/passwd" || return 1; }
does_group_exist() { grep -qs "^$1:" "/etc/group" || return 1; }
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
  local col=${COLUMNS:-120}
  local col=$(($col - 40))
  [ -n "$SSH_KEY_LOCATION" ] || return 0
  [ -d "$HOME/.ssh" ] || mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  get_keys="$(curl -q -LSsf "$SSH_KEY_LOCATION" 2>/dev/null | grep '^' || false)"
  if [ -n "$get_keys" ]; then
    echo "$get_keys" | while read -r key; do
      key_value="$(echo "$key" | awk -F ' ' '{print $2}')"
      if grep -qs "$key" "$HOME/.ssh/authorized_keys"; then
        printf_cyan "${key_value:0:$col} exists in ~/.ssh/authorized_keys"
      else
        echo "$key" | tee -a "/root/.ssh/authorized_keys" &>/dev/null
        printf_green "Successfully added github ${key_value:0:$col}"
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
      rm -Rf "/usr/local/share/CasjaysDev/scripts"
      git clone https://github.com/casjay-dotfiles/scripts /usr/local/share/CasjaysDev/scripts -q
    fi
  fi
  yum clean all &>/dev/null || true
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__domainname() {
  local domain=""
  if [ -n "$(type -P domainname)" ]; then
    domain="$(domainname 2>/dev/null | grep -v '(none)' | grep '^')"
  elif [ -n "$(type -P hostname)" ]; then
    domain="$(hostname -d 2>/dev/null | grep -v '(none)' | grep '^')"
  fi
  echo "${domain:-$HOSTNAME}"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__yum() { yum "$@" $yum_opts &>/dev/null || return 1; }
grab_remote_file() { urlverify "$1" && curl -q -SLs "$1" || exit 1; }
backup_repo_files() { cp -Rf "/etc/yum.repos.d/." "$BACKUP_DIR" 2>/dev/null || return 0; }
rm_repo_files() { [ "${1:-$YUM_DELETE}" = "yes" ] && rm -Rf "/etc/yum.repos.d"/* &>/dev/null || return 0; }
run_external() { printf_green "Executing $*" && eval "$*" >/dev/null 2>&1 || return 1; }
save_remote_file() { urlverify "$1" && curl -q -SLs "$1" | tee "$2" &>/dev/null || exit 1; }
domain_name() { hostname -d | grep '^' || hostname -f | awk -F'.' '{$1="";OFS="." ; print $0}' | sed 's/^.//;s| |.|g' | grep '^'; }
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
  if [ "$RELEASE_TYPE" = "centos" ] && [ "$SET_HOSTNAME" != "pbx" ]; then
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
  local cfg="" efi="" grub_cfg="" grub_efi="" grub_bin="" grub_bin_name=""
  grub_cfg="$(find /boot/grub*/* -name 'grub*.cfg' 2>/dev/null | grep '^' || false)"
  grub_efi="$(find /boot/efi/EFI/* -name 'grub*.cfg' 2>/dev/null | grep '^' || false)"
  grub_bin="$(builtin type -P grub-mkconfig 2>/dev/null || builtin type -P grub2-mkconfig 2>/dev/null || false)"
  grub_bin_name="$(basename "$grub_bin" 2>/dev/null || false)"
  if [ -n "$grub_bin" ]; then
    if [ -f "/etc/default/grub" ]; then
      for opt in 'biosdevname' 'net.ifnames'; do
        if grep -shq "$opt" '/etc/default/grub'; then
          devnull sed -i '/^GRUB_CMDLINE_LINUX=/ s/'$opt'=[01]/'$opt'=0"/' /etc/default/grub
        else
          devnull sed -i '/^GRUB_CMDLINE_LINUX=/ s/"$/ '$opt'=0"/' /etc/default/grub
        fi
      done
      if ! stat -fc %T '/sys/fs/cgroup' | grep -q 'cgroup2fs' && ! grep -sq 'systemd.unified_cgroup_hierarchy' /etc/default/grub; then
        devnull sed -i '/^GRUB_CMDLINE_LINUX=/ s/"$/ systemd.unified_cgroup_hierarchy=1"/' /etc/default/grub
      fi
    fi
    if grep -sq 'GRUB_ENABLE_BLSCFG' "/etc/default/grub"; then
      sed -i 's|GRUB_ENABLE_BLSCFG=.*|GRUB_ENABLE_BLSCFG=false|g' '/etc/default/grub'
    else
      echo "GRUB_ENABLE_BLSCFG=false" >>'/etc/default/grub'
    fi
    # if grep -sq 'crashkernel=' '/etc/default/grub'; then
    #   sed -i '/^GRUB_CMDLINE_LINUX=/s/crashkernel=.*[KMG][, ]//' '/etc/default/grub'
    # fi
    rm_if_exists /boot/*rescue*
    rm_if_exists /boot/loader/entries/*
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
  execute "$e" "${run_post_message:-executing: $m}"
  setexitstatus
  set --
  unset run_post_message
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__kernel_ml() {
  local exitC=0
  local kernel="$(uname -r 2>/dev/null | grep -F 'elrepo')"
  local kernel_avail="$(yum search kernel-ml 2>&1 | awk '{print $1}' | grep '^kernel-ml-.*[.]' || return)"
  if [ -n "$kernel" ]; then
    printf_green "You are already running kernel-ml: $kernel"
  elif [ -n "$kernel_avail" ]; then
    printf_cyan "Switching to the newest kernel from elrepo - This may take a few minutes"
    pkgs="$(rpm -qa | grep -v 'kernel-ml' | grep '^kernel')"
    [ -n "$pkgs" ] && for pkg in $pkgs; do rpm -ev --nodeps $pkg >/dev/null 2>&1; done
    yum install -yyq kernel-ml* >/dev/null || exitC=1
    run_grub
  else
    printf_yellow "kernel-ml doesn't seem to be avaliable"
    exitC=1
  fi
  return $exitC
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__kernel_lt() {
  local exitC=0
  local kernel="$(uname -r 2>/dev/null | grep -F 'elrepo')"
  local kernel_avail="$(yum search kernel-lt 2>&1 | awk '{print $1}' | grep '^kernel-lt-.*[.]' || return)"
  if [ -n "$kernel" ]; then
    printf_green "You are already running kernel-lt: $kernel"
  elif [ -n "$kernel_avail" ]; then
    printf_cyan "Switching to the newest LTS kernel from elrepo - This may take a few minutes"
    pkgs="$(rpm -qa | grep -v 'kernel-lt' | grep '^kernel')"
    [ -n "$pkgs" ] && for pkg in $pkgs; do rpm -ev --nodeps $pkg >/dev/null 2>&1; done
    yum install -yyq kernel-lt* >/dev/null || exitC=1
    run_grub
  else
    printf_yellow "kernel-lt doesn't seem to be avaliable"
    exitC=1
  fi
  return $exitC
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
fix_network_device_name() {
  local device=""
  device="$(ip -4 route ls 2>/dev/null | grep default | grep -Po '(?<=dev )(\S+)' | head -n1 | grep '^' || echo 'eth0')"
  printf_green "Setting network device name to $device in $1"
  find "$1" -type f -exec sed -i 's|eth0|'$device'|g' {} +
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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
  if ! retrieve_repo_file; then
    devnull rm_if_exists "/etc/casjaysdev/updates/versions/installed.txt"
    devnull rm_if_exists "/etc/casjaysdev/updates/versions/$SCRIPT_NAME.txt"
    printf_red "The script has failed to initialize"
    exit 2
  fi
  if [ ! -f "/etc/casjaysdev/updates/versions/os_version.txt" ]; then
    echo "$RELEASE_VER" >"/etc/casjaysdev/updates/versions/os_version.txt"
  fi
fi
if [ -n "$(type -P systemmgr)" ]; then
  run_external /usr/local/share/CasjaysDev/scripts/install.sh
  run_external /usr/local/share/CasjaysDev/scripts/bin/systemmgr --config
  run_external /usr/local/share/CasjaysDev/scripts/bin/systemmgr update scripts
  run_external "__yum clean all"
fi
printf_green "Installer has been initialized"
##################################################################################################################
printf_head "Fixing initscripts"
##################################################################################################################
devnull rpm -ev --nodeps initscripts
devnull yum -yy --allowerasing install initscripts net-tools
##################################################################################################################
printf_head "Installing vnstat"
##################################################################################################################
install_pkg vnstat
system_service_enable vnstat && systemctl restart vnstat &>/dev/null
##################################################################################################################
printf_head "Configuring the kernel"
##################################################################################################################
if [ "$DEFAULT_KERNEL" = "ml" ] || [ "$DEFAULT_KERNEL" = "kernel-ml" ]; then
  __kernel_ml
  install_pkg kernel-ml-modules
  install_pkg kernel-ml-modules-extra
elif [ "$DEFAULT_KERNEL" = "lt" ] || [ "$DEFAULT_KERNEL" = "kernel-lt" ]; then
  __kernel_lt
  install_pkg kernel-lt-modules
  install_pkg kernel-lt-modules-extra
else
  DEFAULT_KERNEL="kernel"
fi
##################################################################################################################
printf_head "Disabling selinux"
##################################################################################################################
disable_selinux
##################################################################################################################
printf_head "Configuring cores for compiling"
##################################################################################################################
numberofcores=$(grep -c ^processor /proc/cpuinfo)
printf_yellow "Total cores avaliable: $numberofcores"
if [ $numberofcores -gt 1 ]; then
  if [ -f "/etc/makepkg.conf" ]; then
    sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'$(($numberofcores + 1))'"/g' /etc/makepkg.conf
    sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T '"$numberofcores"' -z -)/g' /etc/makepkg.conf
  else
    cat <<EOF >"/etc/makepkg.conf"
#########################################################################
# ARCHITECTURE, COMPILE FLAGS
#########################################################################
CARCH="x86_64"
CHOST="x86_64-pc-linux-gnu"
CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security -fstack-clash-protection -fcf-protection -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer"
CXXFLAGS="\$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
LDFLAGS="-Wl,-O1 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,-z,pack-relative-relocs"
LTOFLAGS="-flto=auto"
RUSTFLAGS="-Cforce-frame-pointers=yes"
MAKEFLAGS="-j$(($numberofcores + 1))"
DEBUG_CFLAGS="-g"
DEBUG_CXXFLAGS="\$DEBUG_CFLAGS"
DEBUG_RUSTFLAGS="-C debuginfo=2"
#########################################################################
# BUILD ENVIRONMENT
#########################################################################
BUILDENV=(!distcc color !ccache check !sign)
#DISTCC_HOSTS=""
#BUILDDIR=/tmp/makepkg
#########################################################################
# GLOBAL PACKAGE OPTIONS
#########################################################################
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge debug lto)
INTEGRITY_CHECK=(sha256)
STRIP_BINARIES="--strip-all"
STRIP_SHARED="--strip-unneeded"
STRIP_STATIC="--strip-debug"
MAN_DIRS=({usr{,/local}{,/share},opt/*}/{man,info})
DOC_DIRS=(usr/{,local/}{,share/}{doc,gtk-doc} opt/*/{doc,gtk-doc})
PURGE_TARGETS=(usr/{,share}/info/dir .packlist *.pod)
DBGSRCDIR="/usr/src/debug"
LIB_DIRS=('lib:usr/lib' 'lib32:usr/lib32')
#########################################################################
# COMPRESSION DEFAULTS
#########################################################################
COMPRESSGZ=(gzip -c -f -n)
COMPRESSBZ2=(bzip2 -c -f)
COMPRESSXZ=(xz -c -T $numberofcores -z -)
COMPRESSZST=(zstd -c -T0 --ultra -20 -)
COMPRESSLRZ=(lrzip -q)
COMPRESSLZO=(lzop -q)
COMPRESSZ=(compress -c -f)
COMPRESSLZ4=(lz4 -q)
COMPRESSLZ=(lzip -c -f)
#########################################################################
# END
#########################################################################
EOF
  fi
fi
##################################################################################################################
printf_head "Grabbing ssh key[s]: from $SSH_KEY_LOCATION for $USER"
##################################################################################################################
get_user_ssh_key
##################################################################################################################
printf_head "Configuring the system"
##################################################################################################################
retrieve_repo_file
run_external timedatectl set-timezone America/New_York
for oci in 'oci*' 'cloud*' 'oracle*'; do __yum remove -yy -q "$oci" &>/dev/null; done
for rpms in echo chrony cronie-anacron sendmail sendmail-cf esmtp; do rpm -ev --nodeps $rpms &>/dev/null; done
install_pkg cronie-noanacron
install_pkg postfix
install_pkg net-tools
install_pkg wget
install_pkg curl
install_pkg git
install_pkg nail
install_pkg e2fsprogs
install_pkg redhat-lsb
install_pkg vim
install_pkg unzip
install_pkg bind
install_pkg bind-utils
rm_if_exists /tmp/dotfiles
rm_if_exists /root/anaconda-ks.cfg /var/log/anaconda
run_external yum update -q -yy --skip-broken
[ $RELEASE_VER -ge 9 ] && install_pkg glibc-langpack-en
##################################################################################################################
printf_head "Enabling ip forwarding"
##################################################################################################################
for sysctlconf in /etc/sysctl.conf /etc/sysctl.d/*; do
  if grep -qsF 'net.ipv4.ip_forward' "$sysctlconf"; then
    devnull sed -i 's/net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g' "$sysctlconf"
  else
    sysctl_ip4_forward=0
  fi
  if grep -qsFR 'net.ipv6.conf.all.forwarding' "$sysctlconf"; then
    devnull sed -i 's/net.ipv6.conf.all.forwarding.*/net.ipv6.conf.all.forwarding=1/g' "$sysctlconf"
  else
    sysctl_ip6_forward=0
  fi
done
if [ "$sysctl_ip4_forward" = 0 ]; then
  unset sysctl_ip4_forward
  echo "net.ipv4.ip_forward=1" >>'/etc/sysctl.conf'
fi
if [ "$sysctl_ip6_forward" = 0 ]; then
  unset sysctl_ip6_forward
  echo "net.ipv6.conf.all.forwarding=1" >>'/etc/sysctl.conf'
fi
##################################################################################################################
printf_head "Installing the packages for $RELEASE_NAME"
##################################################################################################################
install_pkg awffull
install_pkg awstats
install_pkg basesystem
install_pkg bash
install_pkg bash-completion
install_pkg biosdevname
install_pkg certbot
install_pkg cockpit
install_pkg cockpit-packagekit
install_pkg cockpit-storaged
install_pkg cockpit-pcp
install_pkg cockpit-bridge
install_pkg cockpit-system
install_pkg cockpit-ws
install_pkg coreutils
install_pkg cowsay
install_pkg cracklib
install_pkg cracklib-dicts
install_pkg cronie
install_pkg cronie-noanacron
install_pkg crontabs
install_pkg curl
install_pkg ctags
install_pkg deltarpm
install_pkg dialog
install_pkg docker-ce
install_pkg ethtool
install_pkg findutils
install_pkg fortune-mod
install_pkg gawk
install_pkg gc
install_pkg gcc
install_pkg git
install_pkg gnupg2
install_pkg gnutls
install_pkg grub2
install_pkg grub2-tools-extra
install_pkg grubby
install_pkg gzip
install_pkg hardlink
install_pkg harfbuzz
install_pkg hdparm
install_pkg hostname
install_pkg htop
install_pkg httpd
install_pkg less
install_pkg logrotate
install_pkg lsof
install_pkg mailx
install_pkg make
install_pkg man-db
install_pkg man-pages
install_pkg mlocate
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
install_pkg ncurses
install_pkg ncurses-base
install_pkg ncurses-libs
install_pkg net-tools
install_pkg nginx
install_pkg ntp
install_pkg oddjob-mkhomedir
install_pkg openssh-server
install_pkg openssl
install_pkg passwd
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
install_pkg php-pgsql
install_pkg php-xml
install_pkg pinentry
install_pkg postfix
install_pkg python3-certbot-dns-rfc2136
install_pkg python3-configargparse
install_pkg python3-cryptography
install_pkg python3-enum34
install_pkg python3-funcsigs
install_pkg python3-future
install_pkg python3-idna
install_pkg python3-josepy
install_pkg python3-mock
install_pkg python3-neovim
install_pkg python3-parsedatetime
install_pkg python3-pbr
install_pkg python3-pip
install_pkg python3-psutil
install_pkg python3-pyasn1
install_pkg python3-pyrfc3339
install_pkg python3-pysocks
install_pkg python3-requests
install_pkg python3-six
install_pkg python3-virtualenv
install_pkg readline
install_pkg rootfiles
install_pkg rsync
install_pkg rsyslog
install_pkg screen
install_pkg sed
install_pkg sqlite
install_pkg sudo
install_pkg symlinks
install_pkg tar
install_pkg tzdata
install_pkg unzip
install_pkg webalizer
install_pkg wget
install_pkg which
install_pkg whois
install_pkg xz
install_pkg xz-libs
install_pkg yum-utils
install_pkg zip
install_pkg zlib
##################################################################################################################
##################################################################################################################
if [ "$SYSTEM_TYPE" = "dns" ]; then
  if devnull install_pkg ntp || devnull install_pkg ntpsec; then
    printf_cyan "Installed ntp"
    SERVICES_ENABLE="$SERVICES_ENABLE ntpd"
    [ -d "/var/lib/ntp/stats" ] || mkdir -p "/var/lib/ntp/stats"
  fi
else
  install_pkg chrony
  SERVICES_ENABLE="$SERVICES_ENABLE chrony"
fi
##################################################################################################################
printf_head "Fixing grub"
##################################################################################################################
run_grub
##################################################################################################################
printf_head "Installing custom system configs"
##################################################################################################################
run_post "systemmgr install $SYSTEMMGR_CONFIGS"
##################################################################################################################
printf_head "Installing custom dotfiles"
##################################################################################################################
run_post "dfmgr update $DFMGR_CONFIGS"
##################################################################################################################
printf_head "Installing custom web server files"
##################################################################################################################
[ -d "/tmp/configs" ] && devnull rm_if_exists "/tmp/configs"
devnull git clone -q "https://github.com/casjay-base/centos" "/tmp/configs"
run_post git clone -q "https://github.com/phpsysinfo/phpsysinfo" "/var/www/html/sysinfo"
run_post git clone -q "https://github.com/solbu/vnstat-php-frontend" "/var/www/html/vnstat"
run_post_message="Installing default server files" run_post sudo -HE STATICSITE="$(hostname -f)" bash -c "$(curl -LSs "https://github.com/casjay-templates/default-web-assets/raw/main/setup.sh")"
[ -f "/etc/httpd/modules/mod_wsgi_python3.so" ] && ln -sf /etc/httpd/modules/mod_wsgi_python3.so /etc/httpd/modules/mod_wsgi.so
##################################################################################################################
printf_head "Deleting files"
##################################################################################################################
if system_service_active named || port_in_use "53"; then
  devnull rm_if_exists /tmp/configs/etc/named*
  devnull rm_if_exists /tmp/configs/var/named*
else
  devnull rm_if_exists /etc/named* /var/named/*
fi
if [ -z "$(type -p ntp || type -p ntpd || type -p ntpq)" ]; then
  IS_INSTALLED_NTP=no
  devnull rm_if_exists /etc/ntp*
  devnull rm_if_exists /tmp/configs/etc/ntp*
fi
if [ -z "$(type -p chronyd)" ]; then
  IS_INSTALLED_CHRONY=no
  devnull rm_if_exists /etc/chrony*
  devnull rm_if_exists /tmp/configs/etc/chrony*
fi
if [ -z "$(type -P httpd)" ]; then
  IS_INSTALLED_HTTPD=no
  devnull rm_if_exists /etc/httpd*
  devnull rm_if_exists /tmp/configs/etc/httpd*
fi
if [ -z "$(type -P nginx)" ]; then
  IS_INSTALLED_NGINX=no
  devnull rm_if_exists /etc/nginx*
  devnull rm_if_exists /tmp/configs/etc/nginx*
fi
if [ -z "$(type -P named)" ]; then
  IS_INSTALLED_BIND=no
  devnull rm_if_exists /etc/named*
  devnull rm_if_exists /var/named*
  devnull rm_if_exists /tmp/configs/etc/named*
  devnull rm_if_exists /tmp/configs/var/named*
fi
if [ -z "$(type -P proftpd)" ]; then
  IS_INSTALLED_PROFTPD=no
  devnull rm_if_exists /etc/proftpd*
  devnull rm_if_exists /tmp/configs/etc/proftpd*
fi
if [ -f "/etc/certbot/dns.conf" ]; then
  devnull rm_if_exists "/tmp/configs/etc/certbot/dns.conf"
fi
for rm_file in /etc/cron*/0* /etc/cron*/dailyjobs /var/ftp/uploads /etc/httpd/conf.d/ssl.conf; do
  run_post devnull rm_if_exists "$rm_file"
done
##################################################################################################################
printf_head "setting up config files"
##################################################################################################################
set_domainname="$(domain_name)"
myhostnameshort="$SET_HOSTNAME"
myserverdomainname="$(hostname -f)"
does_lo_have_ipv6="$(ifconfig lo | grep 'inet6' | grep -q '::1' && echo yes || false)"
NETDEV="$(ip route | grep 'default' | sed -e "s/^.*dev.//" -e "s/.proto.*//")"
[ -n "$NETDEV" ] && mycurrentipaddress_6="$(ifconfig $NETDEV | grep -E 'venet|inet' | grep -v 'docker' | grep inet6 | grep -i 'global' | awk '{print $2}' | head -n1 | grep '^' || hostname -I | tr ' ' '\n' | grep -Ev '^::1|^$' | grep ':.*:' | head -n1 | grep '^' || echo '::1')"
[ -n "$NETDEV" ] && mycurrentipaddress_4="$(ifconfig $NETDEV | grep -E 'venet|inet' | grep -v '127.0.0.' | grep inet | grep -v 'inet6' | awk '{print $2}' | sed 's#addr:##g' | head -n1 | grep '^' || hostname -I | tr ' ' '\n' | grep -vE '|127\.0\.0|172\.17\.0|:.*:|^$' | head -n1 | grep '[0-9]\.[0-9]' || echo '127.0.0.1')"
devnull find /tmp/configs -type f -iname "*.sh" -exec chmod 755 {} \;
devnull find /tmp/configs -type f -iname "*.pl" -exec chmod 755 {} \;
devnull find /tmp/configs -type f -iname "*.cgi" -exec chmod 755 {} \;
devnull find /tmp/configs -type f -iname ".gitkeep" -exec rm -Rf {} \;
devnull find /tmp/configs -type f -exec sed -i "s#mydomainname#$set_domainname#g" {} \;
devnull find /tmp/configs -type f -exec sed -i "s#myhostnameshort#$myhostnameshort#g" {} \;
devnull find /tmp/configs -type f -exec sed -i "s#myserverdomainname#$myserverdomainname#g" {} \;
devnull find /tmp/configs -type f -exec sed -i "s#mycurrentipaddress_6#$mycurrentipaddress_6#g" {} \; &>/dev/null
devnull find /tmp/configs -type f -exec sed -i "s#mycurrentipaddress_4#$mycurrentipaddress_4#g" {} \; &>/dev/null
[ -n "$does_lo_have_ipv6" ] || sed -i 's|inet_interfaces.*|inet_interfaces = 127.0.0.1|g' /tmp/configs/etc/postfix/main.cf
devnull rm_if_exists /tmp/configs/etc/{fail2ban,shorewall,shorewall6}
devnull mkdir -p /etc/rsync.d /var/log/named
devnull cp -Rf /tmp/configs/{etc,root,usr,var}* /
devnull sed -i "s#myserverdomainname#$HOSTNAME#g" /etc/sysconfig/network
devnull sed -i "s#mydomain#$set_domainname#g" /etc/sysconfig/network
devnull chmod 644 -Rf /etc/cron.d/* /etc/logrotate.d/*
devnull touch /etc/postfix/mydomains.pcre
devnull chattr +i /etc/resolv.conf
if [ -z "$IS_INSTALLED_HTTPD" ] || [ -z "$IS_INSTALLED_NGINX" ]; then
  does_user_exist 'apache' && devnull chown -Rf apache:apache "/var/www" "/usr/share/httpd"
fi
if [ -z "$IS_INSTALLED_BIND" ]; then
  does_user_exist 'named' && devnull mkdir -p /etc/named /var/named /var/log/named && devnull chown -Rf named:named /etc/named* /var/named /var/log/named
fi
devnull postmap /etc/postfix/transport /etc/postfix/canonical /etc/postfix/virtual /etc/postfix/mydomains /etc/postfix/sasl/passwd
devnull newaliases &>/dev/null || newaliases.postfix -I &>/dev/null
if ! grep -sq 'kernel.domainname' "/etc/sysctl.conf"; then
  echo "kernel.domainname=$set_domainname" >>/etc/sysctl.conf
fi
##################################################################################################################
printf_head "Installing incus"
##################################################################################################################
if ! grep -Rqsi 'copr.*incus' '/etc/yum.repos.d'; then
  devnull dnf -y install epel-release
  devnull dnf -y copr enable neil/incus
  devnull dnf -y config-manager --enable crb
  devnull crb enable
  __yum makecache
fi
install_pkg incus
install_pkg incus-tools
##################################################################################################################
printf_head "Initializing incus"
##################################################################################################################
incus_setup_failed="no"
incus_setup_message="Initializing incus has failed"
[ -n "$(type -p setupmgr)" ] && setupmgr incus
echo "0:1000000:1000000000" | tee /etc/subuid /etc/subgid >/dev/null
system_service_exists "incus" && devnull systemctl enable --now incus || incus_setup_failed="yes"
[ "$(ls -A /var/lib/incus/* 2>/dev/null | wc -l)" != "0" ] && incus_setup_message="incus seems to be initialized" || { incus_setup_failed="yes" && incus_setup_message="incus seems to have already been initialized"; }
if [ "$incus_setup_failed" = "no" ]; then
  if incus admin init --network-address 127.0.0.1 --network-port 60443 --storage-backend dir --quiet --auto; then
    devnull incus network set incusbr0 ipv4.firewall false
    devnull incus network set incusbr0 ipv6.firewall false
    devnull systemctl restart incus
    printf_blue "incus has been initialized"
    unset incus_setup_failed incus_setup_message
  else
    incus_setup_failed="yes"
  fi
fi
##################################################################################################################
printf_head "Configuring the firewall"
##################################################################################################################
devnull systemctl start firewalld
devnull firewall-cmd --permanent --zone=public --add-service=ssh
devnull firewall-cmd --permanent --zone=public --add-service=http
devnull firewall-cmd --permanent --zone=public --add-service=https
devnull firewall-cmd --permanent --zone=public --remove-service=cockpit
devnull firewall-cmd --permanent --zone=trusted --change-interface=docker0
devnull firewall-cmd --permanent --zone=trusted --change-interface=incusbr0
devnull firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -p icmp -s 0.0.0.0/0 -d 0.0.0.0/0 -j ACCEPT
devnull firewall-cmd --reload
devnull systemctl stop firewalld
##################################################################################################################
printf_head "Enabling services"
##################################################################################################################
for service_enable in $SERVICES_ENABLE; do
  if [ -n "$service_enable" ] && system_service_exists "$service_enable"; then
    system_service_enable $service_enable
    systemctl restart $service_enable >/dev/null 2>&1
  fi
done
##################################################################################################################
printf_head "Disabling services"
##################################################################################################################
for service_disable in $SERVICES_DISABLE; do
  if [ -n "$service_disable" ] && system_service_exists "$service_disable"; then
    system_service_disable $service_disable
  fi
done
##################################################################################################################
printf_head "Creating containers"
##################################################################################################################
if [ "$incus_setup_failed" != "yes" ]; then
  printf_green "Creating container rhel9"
  if run_post devnull incus create images:almalinux/9 rhel9; then
    devnull incus config set rhel9 security.nesting=true security.privileged=true
    devnull incus snapshot create rhel9 default
    if devnull incus start rhel9; then
      printf_cyan "Created rhel9"
    fi
  fi
  printf_green "Creating container debian12"
  if run_post devnull incus create images:debian/12 debian12; then
    devnull incus config set debian12 security.nesting=true security.privileged=true
    devnull incus snapshot create debian12 default
    if devnull incus start debian12; then
      printf_cyan "Created debian12"
    fi
  fi
else
  printf_red "${incus_setup_message:-Initializing incus has failed}"
fi
##################################################################################################################
printf_head "Configuring applications"
##################################################################################################################
devnull timedatectl set-ntp true
##################################################################################################################
printf_head "Configuring cloudflare dns for $SET_HOSTNAME"
##################################################################################################################
if [ -n "${CLOUDFLARE_ZONE_KEY:-$CLOUDFLARE_API_KEY}" ] && [ -n "$CLOUDFLARE_DEFAULT_ZONE" ] && [ -n "$CLOUDFLARE_EMAIL" ]; then
  if [ -n "$(type -P "cloudflare")" ] && [ -n "" ]; then
    if devnull cloudflare update $SET_HOSTNAME --proxy false; then
      printf_blue "Successfully updated $SET_HOSTNAME in $CLOUDFLARE_DEFAULT_ZONE"
    elif devnull cloudflare create $SET_HOSTNAME --proxy false; then
      printf_blue "Created $SET_HOSTNAME for $CLOUDFLARE_DEFAULT_ZONE"
    fi
  fi
fi
##################################################################################################################
printf_head "Setting up ssl certificates"
##################################################################################################################
# If using letsencrypt certificates
le_domain_list="apmpproject.org,casjay.cc,casjay.coffee,casjay.email,casjay.info,casjay.link,casjay.org,casjay.pro,"
le_domain_list+="casjay.us,casjay.work,casjay.xyz,casjaydns.com,casjaydns.fyi,casjaysdev.pro,csj.lol,dockersrc.us,malaks.us,sqldb.us"
le_primary_domain="$(hostname -d 2>/dev/null | grep '^' || hostname -f 2>/dev/null | grep '^' || echo "$HOSTNAME")"
le_options="--primary $le_primary_domain "
[ "$le_primary_domain" = "$le_primary_domain" ] || le_options="--primary $le_primary_domain --domains $HOSTNAME"
[ -f "/etc/certbot/dns.conf" ] && chmod -f 600 "/etc/certbot/dns.conf" && [ -n "$(command -v acme-cli 2>/dev/null)" ] && run_post acme-cli $le_options --add $le_domain_list
le_dir_not_empty="$(find /etc/letsencrypt/live/* -maxdepth 0 -type d | grep -vE 'domain|^$' | head -n1 | grep '^' || false)"
[ -z "$le_dir_not_empty" ] && le_dir_not_empty="/etc/letsencrypt/live/$(__domainname)" || le_certs=yes
[ -L "/etc/letsencrypt/live/domain" ] || { [ -d "/etc/letsencrypt/live/domain" ] && rm -Rf "/etc/letsencrypt/live/domain"; }
if [ -d "$le_dir_not_empty" ] || [ ! -L "/etc/letsencrypt/live/domain" ]; then
  ln -s "$le_dir_not_empty" "/etc/letsencrypt/live/domain"
fi
if [ "$le_certs" = "yes" ]; then
  devnull rm_if_exists "/etc/cockpit/ws-certs.d"/*
  cat "/etc/ssl/CA/CasjaysDev/certs/localhost.crt" "/etc/ssl/CA/CasjaysDev/private/localhost.key" >/etc/cockpit/ws-certs.d/1-my-cert.cert
  find "/etc/postfix" "/etc/httpd" "/etc/nginx" -type f -exec sed -i 's#/etc/ssl/CA/CasjaysDev/certs/localhost.crt#/etc/letsencrypt/live/domain/fullchain.pem#g' {} \;
  find "/etc/postfix" "/etc/httpd" "/etc/nginx" -type f -exec sed -i 's#/etc/ssl/CA/CasjaysDev/certs/localhost.crt#/etc/letsencrypt/live/domain/fullchain.pem#g' {} \;
  find "/etc/postfix" "/etc/httpd" "/etc/nginx" -type f -exec sed -i 's#/etc/ssl/CA/CasjaysDev/private/localhost.key#/etc/letsencrypt/live/domain/privkey.pem#g' {} \;
else
  # If using self-signed certificates
  devnull rm_if_exists "/etc/cockpit/ws-certs.d"/*
  cat "/etc/ssl/CA/CasjaysDev/certs/localhost.crt" "/etc/ssl/CA/CasjaysDev/private/localhost.key" >/etc/cockpit/ws-certs.d/1-my-cert.cert
  find "/etc/postfix" "/etc/httpd" -type f -exec sed -i 's#/etc/letsencrypt/live/domain/fullchain.pem#/etc/ssl/CA/CasjaysDev/certs/localhost.crt#g' {} \;
  find "/etc/postfix" "/etc/httpd" -type f -exec sed -i 's#/etc/letsencrypt/live/domain/fullchain.pem#/etc/ssl/CA/CasjaysDev/certs/localhost.crt#g' {} \;
  find "/etc/postfix" "/etc/httpd" -type f -exec sed -i 's#/etc/letsencrypt/live/domain/privkey.pem#/etc/ssl/CA/CasjaysDev/private/localhost.key#g' {} \;
fi
if [ -f "/etc/ssl/CA/CasjaysDev/certs/ca.crt" ]; then
  if [ -d "/usr/local/share/ca-certificate" ]; then
    cp -Rf "/etc/ssl/CA/CasjaysDev/certs/ca.crt" "/usr/local/share/ca-certificate/"
  elif [ -d "/etc/pki/ca-trust/source/" ]; then
    cp -Rf "/etc/ssl/CA/CasjaysDev/certs/ca.crt" "/etc/pki/ca-trust/source/"
  elif [ -d "/etc/pki/ca-trust/source/anchors" ]; then
    cp -Rf "/etc/ssl/CA/CasjaysDev/certs/ca.crt" "/etc/pki/ca-trust/source/anchors/"
  fi
fi
[ -n "$(type -P update-ca-trust)" ] && devnull update-ca-trust && devnull update-ca-trust extract
[ -n "$(type -P dpkg-reconfigure)" ] && devnull dpkg-reconfigure ca-certificates
##################################################################################################################
printf_head "Setting up munin-node"
##################################################################################################################
mkdir -p "/var/log/munin"
chmod -f 777 "/var/log/munin"
does_user_exist 'munin' && chown -Rf "munin" "/var/log/munin"
does_group_exist "munin" && chgrp -Rf "munin" "/var/log/munin"
bash -c "$(munin-node-configure --remove-also --shell >/dev/null 2>&1)"
##################################################################################################################
printf_head "Setting up tor"
##################################################################################################################
if [ -n "$(type -P tor 2>/dev/null)" ]; then
  devnull systemctl restart tor && sleep 5
  tor_hostnames="$(find "/var/lib/tor/hidden_service" -type f -name 'hostname' 2>/dev/null | grep '^' || false)"
  if [ -n "$tor_hostnames" ]; then
    devnull rm_if_exists "/var/www/html/tor_hostname"
    for f in $tor_hostnames; do
      cat "$f" >>"/var/www/html/tor_hostname" 2>/dev/null
    done
  fi
  prinf '%s\n\%s\n' "# Generate tor hosnames" "#30 * * * * root " >"/etc/cron.d/tor_hostname"
fi
##################################################################################################################
printf_head "Setting up docker"
##################################################################################################################
if [ -n "$(type -P dockermgr 2>/dev/null)" ]; then
  run_post dockermgr init
fi
##################################################################################################################
printf_head "Setting up bind dns [named]"
##################################################################################################################
if [ -z "$(command -v named)" ]; then
  devnull rm_if_exists /etc/named
  devnull rm_if_exists /var/named
  devnull rm_if_exists /var/log/named
  devnull rm_if_exists /etc/logrotate.d/named
fi
##################################################################################################################
if [ "$SYSTEM_TYPE" = "vpn" ]; then
  system_service_disable httpd
  system_service_disable nginx
fi
if [ "$SYSTEM_TYPE" = "mail" ]; then
  printf_head "Running installer script for email server"
  [ -f "$HOME/Projects/github/dfprivate/email/install.sh" ] && eval "$HOME/Projects/github/dfprivate/email/install.sh" >/dev/null 2>&1
elif [ "$SYSTEM_TYPE" = "db" ] || [ "$set_domainname" = "sqldb.us" ]; then
  printf_head "Running installer script for database server"
  [ -f "$HOME/Projects/github/dfprivate/sql/install.sh" ] && eval "$HOME/Projects/github/dfprivate/sql/install.sh" >/dev/null 2>&1
elif [ "$SYSTEM_TYPE" = "dns" ] || [ "$set_domainname" = "casjaydns.com" ]; then
  printf_head "Running installer script for dns server"
  [ -f "$HOME/Projects/github/dfprivate/dns/install.sh" ] && eval "$HOME/Projects/github/dfprivate/dns/install.sh" >/dev/null 2>&1
fi
##################################################################################################################
printf_head "Generating default webserver for $HOSTNAME"
##################################################################################################################
if [ -z "$IS_INSTALLED_HTTPD" ] || [ -z "$IS_INSTALLED_NGINX" ]; then
  if [ -d "/var/www/nginx/domains/$HOSTNAME" ]; then
    printf_blue "Server directory already exists"
  else
    devnull gen-nginx --config
    devnull gen-nginx php $HOSTNAME
    if [ -d "/var/www/nginx/domains/$HOSTNAME" ]; then
      printf_green "Created server in /var/www/nginx/domains/$HOSTNAME"
    else
      printf_red "Failed to create default server"
    fi
  fi
fi
##################################################################################################################
printf_head "Creating directories"
##################################################################################################################
mkdir -p /mnt/backups /var/www/html/.well-known /etc/letsencrypt/live
echo "" >>/etc/fstab
#echo "10.0.254.1:/mnt/Volume_1/backups         /mnt/backups                 nfs defaults,rw 0 0" >> /etc/fstab
#echo "10.0.254.1:/var/www/html/.well-known     /var/www/html/.well-known    nfs defaults,rw 0 0" >> /etc/fstab
#echo "10.0.254.1:/etc/letsencrypt              /etc/letsencrypt             nfs defaults,rw 0 0" >> /etc/fstab
#mount -a
##################################################################################################################
printf_head "Fixing ip address"
##################################################################################################################
/root/bin/changeip.sh >/dev/null 2>&1
##################################################################################################################
printf_head "Cleaning up"
##################################################################################################################
[ -f "/etc/yum/pluginconf.d/subscription-manager.conf" ] && echo "" >"/etc/yum/pluginconf.d/subscription-manager.conf"
find "/etc" "/usr" "/var" -iname '*.rpmnew' -exec rm -Rf {} \; >/dev/null 2>&1
find "/etc" "/usr" "/var" -iname '*.rpmsave' -exec rm -Rf {} \; >/dev/null 2>&1
devnull rm -Rf /tmp/*.tar /tmp/dotfiles /tmp/configs
devnull retrieve_repo_file
chown -Rf apache:apache "/var/www"
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
exit
# end
