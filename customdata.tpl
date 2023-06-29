#!/bin/bash

# Update package lists and upgrade installed packages
sudo apt-get update -y &&

# Install required packages for accessing HTTPS repositories and basic utilities
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common &&

# Download Docker's official GPG key and add it to the system
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&

# Add Docker's official repository to the package manager's sources list
sudo add-apt-repository "deb [arch-amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&

# Update package lists again after adding the Docker repository
sudo apt-get update -y &&

# Install Docker CE, Docker CLI, and containerd.io packages
sudo sudo apt-get install docker docker-ce docker-ce-cli containerd.io -y &&

# Install Python and pip
sudo apt-get install -y python3 python3-pip &&

# Add the "ubuntu" user to the "docker" group for Docker access
sudo usermod -aG docker ubuntu