#!/bin/bash

# Clear Screen
tput reset 2>/dev/null || clear

# Colours (or Colors in en_US)
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NORMAL='\033[0m'

# Abort Function
function abort(){
    [ ! -z "$@" ] && echo -e ${RED}"${@}"${NORMAL}
    exit 1
}

# Banner
function __bannerTop() {
	echo -e \
	${GREEN}"
	██████╗░██╗░░░██╗███╗░░░███╗██████╗░██████╗░██╗░░██╗
	██╔══██╗██║░░░██║████╗░████║██╔══██╗██╔══██╗╚██╗██╔╝
	██║░░██║██║░░░██║██╔████╔██║██████╔╝██████╔╝░╚███╔╝░
	██║░░██║██║░░░██║██║╚██╔╝██║██╔═══╝░██╔══██╗░██╔██╗░
	██████╔╝╚██████╔╝██║░╚═╝░██║██║░░░░░██║░░██║██╔╝╚██╗
	╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝
	"${NORMAL}
}

# Welcome Banner
printf "\e[32m" && __bannerTop && printf "\e[0m"

# Minor Sleep
sleep 1

if [[ "$OSTYPE" == "linux-gnu" ]]; then

    if command -v apt > /dev/null 2>&1; then

        # Read distro metadata when available.
        if [[ -r /etc/os-release ]]; then
            # shellcheck disable=SC1091
            source /etc/os-release
        fi

        if [[ "${ID:-}" == "ubuntu" && "${VERSION_CODENAME:-}" == "resolute" ]]; then
            echo -e ${PURPLE}"Ubuntu 26.04 LTS (Resolute Raccoon) Detected"${NORMAL}
        else
            echo -e ${PURPLE}"Ubuntu/Debian Based Distro Detected"${NORMAL}
        fi

        sleep 1
        echo -e ${BLUE}">> Updating apt repos..."${NORMAL}
        sleep 1
        sudo apt-get update || abort "Setup Failed!"

        # Several archive/development utilities are in Universe or Multiverse
        # on Ubuntu. Enable both so a fresh install has the same capabilities.
        sudo apt-get install -y software-properties-common || abort "Setup Failed!"
        if [[ "${ID:-}" == "ubuntu" ]] && command -v add-apt-repository > /dev/null 2>&1; then
            sudo add-apt-repository -y universe > /dev/null 2>&1 || true
            sudo add-apt-repository -y multiverse > /dev/null 2>&1 || true
            sudo apt-get update || abort "Setup Failed!"
        fi

        sleep 1
        echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
        sleep 1

        package_has_candidate() {
            local candidate
            candidate="$(LC_ALL=C apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
            [[ -n "${candidate}" && "${candidate}" != "(none)" ]]
        }

        first_available_package() {
            local package
            for package in "$@"; do
                if package_has_candidate "${package}"; then
                    printf '%s\n' "${package}"
                    return 0
                fi
            done
            return 1
        }

        # Ubuntu 26.04 (Resolute) uses 7zip and lz4. Keep fallbacks for older
        # Ubuntu/Debian releases where the legacy package names still exist.
        SEVENZIP_PACKAGE="$(first_available_package 7zip p7zip-full || true)"
        LZ4_PACKAGE="$(first_available_package lz4 liblz4-tool || true)"
        RAR_EXTRACT_PACKAGE="$(first_available_package unrar unrar-free || true)"
        SEVENZIP_RAR_PACKAGE="$(first_available_package 7zip-rar p7zip-rar || true)"

        REQUIRED_PACKAGES=(
            zip unzip
            device-tree-compiler liblzma-dev brotli
            axel gawk aria2 detox cpio rename
            liblz4-dev jq git-lfs
        )

        OPTIONAL_PACKAGES=(
            unace sharutils rar uudeview mpack arj cabextract
        )

        APT_PACKAGES=("${REQUIRED_PACKAGES[@]}")

        [[ -n "${SEVENZIP_PACKAGE}" ]] && APT_PACKAGES+=("${SEVENZIP_PACKAGE}")
        [[ -n "${LZ4_PACKAGE}" ]] && APT_PACKAGES+=("${LZ4_PACKAGE}")
        [[ -n "${RAR_EXTRACT_PACKAGE}" ]] && APT_PACKAGES+=("${RAR_EXTRACT_PACKAGE}")
        [[ -n "${SEVENZIP_RAR_PACKAGE}" ]] && APT_PACKAGES+=("${SEVENZIP_RAR_PACKAGE}")

        for package in "${OPTIONAL_PACKAGES[@]}"; do
            if package_has_candidate "${package}"; then
                APT_PACKAGES+=("${package}")
            fi
        done

        sudo apt-get install -y "${APT_PACKAGES[@]}" || abort "Setup Failed!"

    elif command -v dnf > /dev/null 2>&1; then

        echo -e ${PURPLE}"Fedora Based Distro Detected"${NORMAL}
        sleep 1
	    echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	    sleep 1

	    # "dnf" automatically updates repos before installing packages
        sudo dnf install -y unace unrar zip unzip sharutils uudeview arj cabextract file-roller dtc brotli axel aria2 detox cpio lz4 xz-devel p7zip p7zip-plugins git-lfs || abort "Setup Failed!"

    elif command -v pacman > /dev/null 2>&1; then

        echo -e ${PURPLE}"Arch or Arch Based Distro Detected"${NORMAL}
        sleep 1
	    echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	    sleep 1

        sudo pacman -Syyu --needed --noconfirm >/dev/null || abort "Setup Failed!"
        sudo pacman -Sy --noconfirm unace unrar p7zip sharutils uudeview arj cabextract file-roller dtc brotli axel gawk aria2 detox cpio lz4 jq git-lfs || abort "Setup Failed!"

    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then

    echo -e ${PURPLE}"macOS Detected"${NORMAL}
    sleep 1
	echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	sleep 1
    brew install protobuf xz brotli lz4 aria2 detox coreutils p7zip gawk git-lfs || abort "Setup Failed!"

fi

sleep 1

# Install `uv`
if ! command -v uv > /dev/null ; then
    echo -e ${BLUE}">> Installing uv for python packages..."${NORMAL}
    sleep 1
    bash -c "$(curl -sL https://astral.sh/uv/install.sh)" || abort "Setup Failed!"
fi

# Done!
echo -e ${GREEN}"Setup Complete!"${NORMAL}

# Exit
exit 0
