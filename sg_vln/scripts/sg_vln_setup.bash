#!/bin/bash
# This script should be run in order to install the necessary components to build and run the sg_vln docker

RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
BOLD='\e[1m'
RESET='\e[0m' # Resets all text attributes

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

check_pkgs() {
    for pkg in "$@"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            echo -e "[${GREEN}${BOLD}OK${RESET}] $pkg is installed"
        else
            echo "[MISSING] $pkg is NOT installed"
            return 1   # exit function immediately
        fi
    done
    return 0   # all good
}

echo "Welcome to the sg_vln setup script!"

echo "Checking for docker apt repo..."
if [[ -e "/etc/apt/keyrings/docker.asc" ]]; then
  echo -e "[${GREEN}${BOLD}OK${RESET}] Docker keyring detected"
else
  echo "Adding docker keyring as it was not found..."
  # Add Docker's official GPG key:
  sudo apt-get update -y
  sudo apt-get install ca-certificates curl -y
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
fi

docker_pkgs=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
echo "Checking for Docker pkgs..."
if check_pkgs "${docker_pkgs[@]}"; then
  echo -e "[${GREEN}${BOLD}OK${RESET}] Docker pkgs already installed."
else
  echo "Installing Docker pkgs"
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
fi

# Check if user is in the docker group already
if id -nG "$USER" | grep -qw docker; then
  echo -e "[${GREEN}${BOLD}OK${RESET}] User '$USER' already has non-sudo Docker access."
else
  echo "[INFO] User '$USER' is not in the docker group."

  # Make sure the docker group exists
  if ! getent group docker >/dev/null 2>&1; then
      echo "[INFO] Creating group 'docker'..."
      sudo groupadd docker
  fi

  echo "[INFO] Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"
  newgrp docker #refresh group so that logout and log back in isn't necessary
fi

echo "Checking for Nvidia Container Toolkit apt repo..."
if [[ -e "/etc/apt/sources.list.d/nvidia-container-toolkit.list" ]]; then
  echo -e "[${GREEN}${BOLD}OK${RESET}] Nvidia Container Toolkit apt repo detected."
else
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update -y
fi

export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1

nvidia_container_toolkit_pkgs=(nvidia-container-toolkit \
      nvidia-container-toolkit-base \
      libnvidia-container-tools \
      libnvidia-container1)

if check_pkgs "${nvidia_container_toolkit_pkgs[@]}"; then
  echo -e "[${GREEN}${BOLD}OK${RESET}] Nvidia Container Toolkit pkgs already installed."
else
  echo "Installing Nvidia Container Toolkit pkgs"
  sudo apt-get install -y \
      nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION} 
fi

echo "Checking if docker runtime is configured for nvidia-container-toolkit..."
if grep -q 'nvidia-container-runtime' /etc/docker/daemon.json; then
    echo -e "[${GREEN}${BOLD}OK${RESET}] Runtime already configured."
else
    echo "Configuring runtime..."
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
fi

echo -e "[${GREEN}${BOLD}FINISHED${RESET}] Setup Complete!"