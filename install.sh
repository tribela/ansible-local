#!/bin/bash
set -euo pipefail

REPOSITORY=https://github.com/tribela/ansible-local
REQUIREMENTS="$(mktemp --suffix=.yml)"

cleanup() {
	rm -rf "$REQUIREMENTS" || true
}

trap cleanup EXIT

ensure_ansible() {
	if which ansible &>/dev/null; then
		return 0
	fi

	if which brew &>/dev/null; then
		echo "Install Ansible using brew"
		brew install ansible
		return 0
	fi

	if ! which pipx &>/dev/null; then
		echo "Install pipx"
		if ! which pip3; then
			echo "pip3 not found. Please install pip3 and try again"
			return 1
		fi
		pip3 install --user -y pipx
	fi

	echo "Install Ansible using pipx"
	pipx install ansible

	ansible --version &>/dev/null
}

echo "Ensure ansible is installed"
ensure_ansible
echo "Download galaxy requirements"
wget -O "$REQUIREMENTS" $REPOSITORY/raw/refs/heads/main/requirements.yml
echo "Installing galaxy requirements"
ansible-galaxy install -r "$REQUIREMENTS"
echo "Go!"
ansible-pull -U "$REPOSITORY" -K "$@"

echo "All done!"
