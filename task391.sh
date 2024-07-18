#!/bin/bash

# Script to set up CI environment with Jenkins, test databases, and code quality checks
# Ensure script is run with sudo or appropriate permissions

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Function to check for required commands
check_command() {
    command -v $1 >/dev/null 2>&1 || handle_error "$1 command is required but not installed."
}

# Update and install required packages
install_packages() {
    echo "Updating package lists and installing required packages..."
    sudo apt-get update -y || handle_error "error : packages not updated."
    sudo apt-get install -y openjdk-11-jdk wget gnupg2 || handle_error "Error: Unable to install necessary packages."
}

# Install and configure Docker
install_docker() {
    echo "Installing Docker..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    sudo apt-get update -y || handle_error "error: package update failed."
    sudo apt-get install -y apt-transport-https ca-certificates curl gnup lsb-release || handle_error "error - dependency(s) not installed."

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || handle_error "error -GPG keys not added."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || handle_error "error:repository setup incomplete."
    sudo apt-get update -y || handle_error "error : packages not updated."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io || handle_error "error: Docker installation failed."
    sudo systemctl start docker || handle_error "error: Unable to start Docker service."
    sudo systemctl enable docker || handle_error "error: Unable to enable Docker service."
    sudo usermod -aG docker $USER || handle_error "error: Unable to add user to Docker group."
}

# Install and configure Jenkins
install_jenkins() {
    echo "Installing Jenkins..."
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add - || handle_error "Unable to add Jenkins key."
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list' || handle_error "err- Jenkins repository not added."
    sudo apt-get update -y || handle_error "Unable to update package lists."
    sudo apt-get install -y jenkins || handle_error "Failed to install Jenkins."
    sudo systemctl start jenkins || handle_error "Unable to start Jenkins service."
    sudo systemctl enable jenkins || handle_error "Unable to enable Jenkins service."
}

# Set up test databases using Docker
setup_test_databases() {
    echo "Setting up test databases with Docker..."
    sudo docker run --name ci-mysql -e MYSQL_PASS=root -e MYSQL_DB=testdb -d mysql:5.7 || handle_error "MySQL setup failed."
    sudo docker run --name ci-postgres -e PG_PASS=root -e PG_DB=testdb -d postgres:11 || handle_error "Postgres setup failed"
}

# Install code quality tools
install_code_quality_tools() {
    echo "Installing code quality tools..."
    sudo apt-get install -y pylint || handle_error "error: Unable to install Pylint."
    sudo apt-get install -y flake8 || handle_error "error: Unable to install Flake8."
}

# Main function to orchestrate setup
main() {
    # Check for root permissions
    if [[ $EUID -ne 0 ]]; then
        handle_error "This script must be run as root"
    fi

    # Check for required commands
    check_command "wget"

    # Perform setup steps
    install_packages
    install_docker
    install_jenkins
    setup_test_databases
    install_code_quality_tools

    echo "CI environment setup complete. Please log out and log back in to apply Docker group changes."
}

# Execute the main function
main
