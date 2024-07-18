#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1 || handle_error "$1 is required but not installed."
}

# Function to detect the host OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        else
            handle_error "Unsupported Linux distribution."
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VER=$(sw_vers -productVersion)
    else
        handle_error "Unsupported OS."
    fi
}

# Function to install packages on Linux
install_packages_linux() {
    case "$ID" in
        ubuntu | debian)
            sudo apt update || handle_error "Failed to update package list."
            sudo apt install -y "$@" || handle_error "Failed to install packages."
            ;;
        centos | fedora | rhel)
            sudo yum install -y "$@" || handle_error "Failed to install packages."
            ;;
        *)
            handle_error "Unsupported Linux distribution: $ID"
            ;;
    esac
}

# Function to install packages on macOS
install_packages_macos() {
    check_command brew || handle_error "Homebrew is required but not installed."
    brew install "$@" || handle_error "Failed to install packages."
}

# Function to install packages
install_packages() {
    if [[ "$OS" == "macOS" ]]; then
        install_packages_macos "$@"
    else
        install_packages_linux "$@"
    fi
}

# Function to configure services
configure_services() {
    echo "Configuring services..."
    # Add service configuration commands here
}

# Function to set up test databases
setup_test_databases() {
    echo "Setting up test databases..."
    install_packages mysql-server postgresql

    sudo service mysql start || handle_error "Failed to start MySQL."
    sudo service postgresql start || handle_error "Failed to start PostgreSQL."

    # Initialize MySQL
    MYSQL_DIR="/var/lib/mysql"
    if [ ! -d "$MYSQL_DIR/mysql" ]; then
        sudo mysqld --initialize-insecure --user=mysql 
        || handle_error "Error: MySQL initialization failed."
    else
        echo "MySQL data directory already exists. Skipping initialization."
    fi

    # Initialize PostgreSQL
    PG_DIR="/var/lib/postgresql/14/main"
    if [ ! -d "$PG_DIR" ]; then
        sudo -u postgres initdb -D "$PG_DIR" 
        || handle_error "Error: PostgreSQL initialization failed."
    else
        echo "PostgreSQL data directory already exists. Skipping initialization."
    fi
}

# Function to customize setup based on developer roles
# add more roles and their corresponding tech here 
customize_setup() {
    echo "Select your role:"
    echo "1. Backend Developer"
    echo "2. Frontend Developer"
    echo "3. Full Stack Developer"
    read -rp "Enter the number corresponding to your role: " role

    case $role in
        1)
            install_packages python3 nodejs
            ;;
        2)
            install_packages nodejs npm
            ;;
        3)
            install_packages python3 nodejs npm
            ;;
        *)
            handle_error "Invalid role selected."
            ;;
    esac
}

# Main function to start the  setup
main() {
    detect_os
    echo "Detected OS: $OS $VER"

    check_command sudo

    if ! sudo -v; then
        handle_error "This script must be run with sudo privileges."
    fi

    install_packages git curl wget
    configure_services
    setup_test_databases
    customize_setup

    echo "Development environment setup complete."
}

# Execute the main function
main
