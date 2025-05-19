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

# Function to generate random password
generate_password() {
    openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16
}

# Function to generate .env file
generate_env_file() {
    local env_file="$INSTALL_DIR/.env"
    log "Generating .env file..."
    
    # Generate secure passwords
    local admin_password=$(generate_password)
    local admin_token=$(generate_password)
    local minio_password=$(generate_password)
    local rabbitmq_password=$(generate_password)
    
    # Create .env file
    cat > "$env_file" << EOF
# OpenCTI Configuration
OPENCTI_ADMIN_EMAIL=admin@opencti.io
OPENCTI_ADMIN_PASSWORD=${admin_password}
OPENCTI_ADMIN_TOKEN=${admin_token}

# MinIO Configuration
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=${minio_password}

# RabbitMQ Configuration
RABBITMQ_DEFAULT_USER=opencti
RABBITMQ_DEFAULT_PASS=${rabbitmq_password}
EOF

    log "Generated .env file with secure passwords"
    log "Please save these credentials securely:"
    log "OpenCTI Admin Password: ${admin_password}"
    log "OpenCTI Admin Token: ${admin_token}"
    log "MinIO Root Password: ${minio_password}"
    log "RabbitMQ Password: ${rabbitmq_password}"
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
        software-properties-common \
        openssl
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

    # Create installation directory
    log "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Copy docker-compose.yml
    log "Copying docker-compose.yml..."
    cp "$(dirname "$0")/docker-compose.yml" .

    # Generate .env file
    generate_env_file

    if [ "$ENV_ONLY" = true ]; then
        log "Environment file generated. Exiting..."
        exit 0
    fi

    # Start OpenCTI
    log "Starting OpenCTI services..."
    docker compose up -d

    log "Installation completed successfully!"
    log "OpenCTI will be available at http://localhost:8080"
    log "Please check the log file for the generated credentials"
}

# Run main function
main 