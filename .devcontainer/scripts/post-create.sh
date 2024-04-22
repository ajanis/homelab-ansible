#!/bin/bash

BASE_DIR="/tmp"
SYS_ARCH="$(uname -m)"
PKG_NAME="session-manager-plugin.deb"
PKG_URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest"

case "${SYS_ARCH}" in
arm64)
	PKG_URL_ARCH="ubuntu_arm64"
	;;
*)
	PKG_URL_ARCH="ubuntu_64bit"
	;;
esac

if ${INSTALL_AWS:=false}; then
	echo
	echo "Fetching session-manager-plugin package for ${SYS_ARCH}..."
	echo
	sudo curl --no-progress-meter "${PKG_URL}/${PKG_URL_ARCH}/${PKG_NAME}" -o "${BASE_DIR}/${PKG_NAME}"
	echo "Installing AWS cli package..."
	echo
	sudo apt install -y vim awscli
	echo "Installing the AWS SSM connection plugin..."
	echo
	sudo dpkg -i "${BASE_DIR}/${PKG_NAME}"
	echo
fi
