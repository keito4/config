#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  SUDO=sudo
else
  SUDO=
fi

pkg_manager=
if command -v apt-get >/dev/null 2>&1;   then pkg_manager=apt
elif command -v dnf >/dev/null 2>&1;     then pkg_manager=dnf
elif command -v yum >/dev/null 2>&1;     then pkg_manager=yum
elif command -v apk >/dev/null 2>&1;     then pkg_manager=apk
elif command -v pacman >/dev/null 2>&1;  then pkg_manager=pacman
elif command -v zypper >/dev/null 2>&1;  then pkg_manager=zypper
else
  echo "Unsupported package manager"; exit 1
fi

case "$pkg_manager" in
  apt)
    $SUDO apt-get update
    $SUDO apt-get upgrade -y
    $SUDO apt-get install -y openssh-server git apt-transport-https ca-certificates curl gnupg-agent software-properties-common make gcc python3 python-is-python3 tig
    ;;
  dnf|yum)
    $SUDO $pkg_manager -y update
    $SUDO $pkg_manager install -y openssh-server git curl gnupg2 make gcc python3 tig
    ;;
  apk)
    $SUDO apk update
    $SUDO apk add --no-cache openssh git curl gnupg make gcc python3 py3-pip tig
    ;;
  pacman)
    $SUDO pacman -Syu --noconfirm
    $SUDO pacman -S --noconfirm openssh git curl gnupg make gcc python3 tig
    ;;
  zypper)
    $SUDO zypper --non-interactive refresh
    $SUDO zypper --non-interactive install openssh git curl gpg2 make gcc python3 tig
    ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | $SUDO sh
fi
if getent group docker >/dev/null 2>&1; then
  $SUDO usermod -aG docker "${SUDO_USER:-$(whoami)}" || true
fi

if ! command -v kubeadm >/dev/null 2>&1; then
  case "$pkg_manager" in
    apt)
      curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | $SUDO apt-key add -
      echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | $SUDO tee /etc/apt/sources.list.d/kubernetes.list
      $SUDO apt-get update
      $SUDO apt-get install -y kubelet kubeadm kubectl
      ;;
    dnf|yum)
      cat <<EOF | $SUDO tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=0
EOF
      $SUDO $pkg_manager install -y kubelet kubeadm kubectl
      $SUDO systemctl enable kubelet
      ;;
    apk|pacman|zypper)
      ARCH=$(uname -m)
      curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/$ARCH/kubectl
      chmod +x /usr/local/bin/kubectl
      ;;
  esac
fi

if swapon --show | grep -q '^'; then
  $SUDO swapoff -a
fi
