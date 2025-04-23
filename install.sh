#!/bin/bash
set -euo pipefail

REPOSITORY=https://github.com/tribela/ansible-local

fix_envs() {
	export PYTHONUNBUFFERED=True
	if [[ -t 1 ]]; then
		export ANSIBLE_FORCE_COLOR=True
	fi
}

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

is_sudo_without_pass() {
	if SUDO_ASKPASS=${SUDO_ASKPASS:-/bin/false} sudo -A -n true &>/dev/null; then
		echo "sudo without password is enabled"
		return 0
	else
		echo "sudo without password is not enabled"
		return 1
	fi
}

fix_envs

echo "Ensure ansible is installed"
ensure_ansible
echo "Install galaxy requirements"
ansible-pull -U "$REPOSITORY" boot.yml

ARGS=()
if ! is_sudo_without_pass; then
	ARGS+=(-K)
fi

echo "Go!"
ansible-pull -U "$REPOSITORY" "${ARGS[@]}" "$@"

echo "All done!"
