#!/bin/bash

echo "Installing development dependencies..."

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi

# Install Helm
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz | tar xz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64
fi

# Install Terraform
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform
fi

# Install Java 17
if ! command -v java &> /dev/null; then
    echo "Installing Java 17..."
    sudo apt update
    sudo apt install openjdk-17-jdk -y
fi

# Install Maven
if ! command -v mvn &> /dev/null; then
    echo "Installing Maven..."
    sudo apt install maven -y
fi

# Install Node.js and npm
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "All dependencies installed successfully!"