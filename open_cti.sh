#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help                 Show this help message and exit"
    echo "  -d, --directory <path>     Specify the installation directory (default: /opt/opencti)"
    echo "  -s, --skip-docker         Skip Docker and Docker Compose installation"
    echo "  -e, --env-only            Only generate the .env file, skip installation steps"
    exit 0
}

# Default values
INSTALL_DIR="/opt/opencti"
SKIP_DOCKER=false
ENV_ONLY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -d|--directory)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -s|--skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        -e|--env-only)
            ENV_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Create log file
LOG_FILE="/var/log/opencti_install.log"
touch "$LOG_FILE"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install prerequisites
install_prerequisites() {
    log "Installing prerequisites..."
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        git \
        python3-pip \
        python3-venv \
        software-properties-common

    # Install Python dependencies
    pip3 install -r requirements.txt --break-system-packages
}

# Function to install Docker
install_docker() {
    if ! command_exists docker; then
        log "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    else
        log "Docker is already installed"
    fi
}

# Main installation process
main() {
    log "Starting OpenCTI installation..."

    if [ "$SKIP_DOCKER" = false ]; then
        install_prerequisites
        install_docker
    fi

    if [ "$ENV_ONLY" = true ]; then
        log "Generating .env file only..."
        # Add your .env generation logic here
        exit 0
    fi

    # Create installation directory
    log "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Clone OpenCTI repository
    log "Cloning OpenCTI repository..."
    git clone https://github.com/OpenCTI-Platform/opencti.git .

    # Generate .env file
    log "Generating .env file..."
    # Add your .env generation logic here

    # Start OpenCTI
    log "Starting OpenCTI services..."
    docker compose up -d

    log "Installation completed successfully!"
}

# Run main function
main 