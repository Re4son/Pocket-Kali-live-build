#!/usr/bin/env bash

PROG_NAME="$(basename $0)"
ARGS="$@"
VERSION="4.16-1.0"


function print_version() {
    printf "\tPocket-Kali Re4son-Kernel Installer: $PROG_NAME $VERSION\n\n"
    exit 0
}


function print_help() {
    printf "\n\tUsage: ${PROG_NAME} [option]\n"
    printf "\t\t\t   (No option)\tInstall Re4son-Kernel\n"
    printf "\t\t\t\t-h\tPrint this help\n"
    printf "\t\t\t\t-v\tPrint version of this installer\n"
    printf "\t\t\t\t-a\tOnly install haveged to add entropy preventing hangs during boot\n"
    printf "\t\t\t\t-d\tOnly remove haveged\n"
    printf "\t\t\t\t-t\tOnly install touch rotation fix\n"
    printf "\t\t\t\t-r\tOnly remove touch rotation fix\n"
    printf "\t\t\t\t-s\tOnly scale gdm3 login screen\n"
    printf "\t\t\t\t-u\tOnly undo scaling of gdm3 login screen\n"
    exit 1
}

function ask() {
    # http://djm.me/ask
    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question
        printf "\t++++ "
        read -p "$1 [$prompt] " REPLY

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

function exitonerr {
    # via: http://stackoverflow.com/a/5196108
    "$@"
    local status=$?

    if [ $status -ne 0 ]; then
        echo "Error completing: $1" >&2
        exit 1
    fi

    return $status
}

function check_deb_inst() {
## checks if deb package is installed     ##
## and returns "yes" if yes, "no" if not  ##
## usage = check_deb_inst <pkg>           ##
    pkg="$1"
    PKG_STATUS=$(dpkg-query -W --showformat='${Status}\n' ${pkg}|grep "ok installed")
    if [ "" == "$PKG_STATUS" ]; then
        echo "no"
    else
	echo "yes"
    fi
}

function debver_ge() {
## compares installed version of deb package with given number      ##
## and returns "yes" when installed version is greater or equal     ##
## otherwise it returns "no"                                        ##
## usage = debver_ge <pkg> <min version>                            ##

    pkg="$1"
    minver="$2"
    if $(dpkg --compare-versions $(dpkg-query -f='${Version}' --show ${pkg}) ge ${minver}); then
	echo "yes"
    else
        echo "no"
    fi
}


function install_goodix_fix {
    printf "\n\t**** Installing touchscreen-suspend-fix\" ****\n"
    if [ ! -f /lib/systemd/system-sleep/touchscreen-fix ]; then
        cp -f ./hotfixes/touchscreen-fix /lib/systemd/system-sleep/
        chmod 755  /lib/systemd/system-sleep/touchscreen-fix
    fi
    printf "\t**** Fix installed ****\n\n"
    return 0
}

function remove_goodix_fix {
    if [ -f /lib/systemd/system-sleep/touchscreen-fix ]; then
        printf "\n\t**** Remove superseded touchscreen-suspend-fix ****\n"
        rm -f /lib/systemd/system-sleep/touchscreen-fix
        printf "\t**** Fix removed                               ****\n\n"
    fi
    return 0
}

function install_kernel() {

    printf "\n\t**** Installing Re4son-Kernel and Headers ****\n"
    exitonerr apt install ./*.deb
    printf "\t**** Installation completed               ****\n\n"
    return 0
}

function install_pcspkr_fix {
    printf "\n\t**** Removing annoying \"pcspkr\" boot message ****\n"
    if [ ! -f /etc/modprobe.d/blacklist-pcspkr.conf ]; then
        cp -f ./hotfixes/blacklist-pcspkr.conf /etc/modprobe.d/
    fi
    printf "\t**** Annoying message removed                  ****\n\n"
    return 0
}

function install_goodix_udev {
    printf "\n\t**** Installing udev rule to fix touch rotation ****\n"
    if [ ! -f /etc/udev/rules.d/99-goodix-touchscreen.rules ]; then
        cp -f ./hotfixes/99-goodix-touchscreen.rules /etc/udev/rules.d/ 
    fi
    printf "\t**** udev rule installed                        ****\n\n"
    return 0
}

function remove_goodix_udev {
    printf "\n\t**** Removing udev rule to fix touch rotation ****\n"
    if [ -f /etc/udev/rules.d/99-goodix-touchscreen.rules ]; then
        rm -f /etc/udev/rules.d/99-goodix-touchscreen.rules 
    fi
    printf "\t**** udev rule removed                        ****\n\n"
    return 0
}

function install_gdm3_scaling {
    printf "\n\t**** Scaling gdm3 login screen ****\n"
    if [ ! -f  /usr/share/gdm/greeter/autostart/xrandr.desktop ]; then
        cp -f ./hotfixes/xrandr.desktop /usr/share/gdm/greeter/autostart/ 
    fi
    printf "\t**** Gdm3 login screen scaled  ****\n\n"
    return 0
}

function remove_gdm3_scaling {
    printf "\n\t**** Resetting gdm3 login screen scaling ****\n"
    if [ -f /usr/share/gdm/greeter/autostart/xrandr.desktop ]; then
        rm -f /usr/share/gdm/greeter/autostart/xrandr.desktop 
    fi
    printf "\t**** Gdm3 login screen scaling reset     ****\n\n"
    return 0
}

function install_haveged {
    printf "\n\t**** Installing haveged to add entropy         ****\n"
    if [ $(check_deb_inst "haveged") != "yes" ]; then
        apt update && apt install haveged -y
	systemctl enable haveged && systemctl start haveged
    fi
    printf "\t**** haveged installed and enabled as service  ****\n\n"
    return 0
}

function remove_haveged {
    printf "\n\t**** Removing haveged   ****\n"
    if [ $(check_deb_inst "haveged") == "yes" ]; then
	systemctl stop haveged && systemctl disable haveged
        apt remove haveged -y
    fi
    printf "\t**** haveged removed    ****\n\n"
    return 0
}


############
##        ##
##  MAIN  ##

if [[ $EUID -ne 0 ]]; then
   printf "\n\t${PROG_NAME} must be run as root. try: sudo install.sh\n\n"
   exit 1
fi

args=$(getopt -uo 'hvadtrsu' -- $*)

set -- $args

for i
do
    case "$i"
    in
        -h)
            print_help
            exit 0
            ;;
        -v)
            print_version
            exit 0
            ;;
        -a)
            install_haveged
            exit 0
            ;;
        -d)
            remove_haveged
            exit 0
            ;;
        -t)
            install_goodix_udev
            exit 0
            ;;
        -r)
            remove_goodix_udev
            exit 0
            ;;
        -s)
            install_gdm3_scaling
            exit 0
            ;;
        -u)
            remove_gdm3_scaling
            exit 0
            ;;
    esac
done

printf "\n"
if ask "Install Re4son-Kernel?" "Y"; then
    install_kernel
    # goodix-fix replaced by kernel commit 06ea1b86587ddd27330064d0cbb8f22a2a8977d3
    # let's remove workaround if it has been installed by previous kernels
    remove_goodix_fix
    install_pcspkr_fix
fi
if [ $(check_deb_inst "haveged") != "yes" ]; then
    if ask "There is a known issue with low entropy causing extreme delays during boot, install haveged to fix it?" "Y"; then
	install_haveged
    fi
fi

if [ $(debver_ge "gnome-shell" "3.28") == "yes" ]; then
    if [ ! -f /etc/udev/rules.d/99-goodix-touchscreen.rules ]; then
        if ask "The touch screen calibration may be off, fix it?" "Y"; then
            install_goodix_udev
        fi
    fi
    if [ ! -f  /usr/share/gdm/greeter/autostart/xrandr.desktop ]; then
        if ask "The gdm3 login screen scaling  may be off, fix it?" "Y"; then
        install_gdm3_scaling
        fi
    fi
fi
if ask "Reboot to apply changes?" "Y"; then
    reboot
fi
printf "\n"


