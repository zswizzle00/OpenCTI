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

# Function to check Docker Compose version
check_docker_compose() {
    if command_exists docker-compose; then
        VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d'.' -f1,2)
        if (( $(echo "$VERSION < 2.0" | bc -l) )); then
            log "Docker Compose version $VERSION detected. Installing Docker Compose V2..."
            curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        fi
    fi
}

# Function to configure ElasticSearch
configure_elasticsearch() {
    log "Configuring ElasticSearch..."
    echo "vm.max_map_count=1048575" >> /etc/sysctl.conf
    sysctl -w vm.max_map_count=1048575
}

# Function to configure RabbitMQ
configure_rabbitmq() {
    log "Configuring RabbitMQ..."
    mkdir -p "$INSTALL_DIR/rabbitmq"
    cat > "$INSTALL_DIR/rabbitmq/rabbitmq.conf" << EOF
max_message_size = 536870912
consumer_timeout = 86400000
EOF
}

# Function to generate .env file
generate_env_file() {
    local env_file="$INSTALL_DIR/.env"
    log "Generating .env file..."
    
    # Generate random UUIDs
    ADMIN_TOKEN=$(uuidgen)
    HEALTHCHECK_KEY=$(uuidgen)
    MINIO_ROOT_USER=$(uuidgen)
    MINIO_ROOT_PASSWORD=$(uuidgen)
    CONNECTOR_HISTORY_ID=$(uuidgen)
    CONNECTOR_EXPORT_FILE_STIX_ID=$(uuidgen)
    CONNECTOR_EXPORT_FILE_CSV_ID=$(uuidgen)
    CONNECTOR_IMPORT_FILE_STIX_ID=$(uuidgen)
    CONNECTOR_EXPORT_FILE_TXT_ID=$(uuidgen)
    CONNECTOR_IMPORT_DOCUMENT_ID=$(uuidgen)
    CONNECTOR_ANALYSIS_ID=$(uuidgen)
    
    # Create .env file
    cat > "$env_file" << EOF
OPENCTI_ADMIN_EMAIL=admin@opencti.io
OPENCTI_ADMIN_PASSWORD=ChangeMePlease
OPENCTI_ADMIN_TOKEN=$ADMIN_TOKEN
OPENCTI_BASE_URL=http://localhost:8080
OPENCTI_HEALTHCHECK_ACCESS_KEY=$HEALTHCHECK_KEY
MINIO_ROOT_USER=$MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=guest
ELASTIC_MEMORY_SIZE=4G
CONNECTOR_HISTORY_ID=$CONNECTOR_HISTORY_ID
CONNECTOR_EXPORT_FILE_STIX_ID=$CONNECTOR_EXPORT_FILE_STIX_ID
CONNECTOR_EXPORT_FILE_CSV_ID=$CONNECTOR_EXPORT_FILE_CSV_ID
CONNECTOR_IMPORT_FILE_STIX_ID=$CONNECTOR_IMPORT_FILE_STIX_ID
CONNECTOR_EXPORT_FILE_TXT_ID=$CONNECTOR_EXPORT_FILE_TXT_ID
CONNECTOR_IMPORT_DOCUMENT_ID=$CONNECTOR_IMPORT_DOCUMENT_ID
CONNECTOR_ANALYSIS_ID=$CONNECTOR_ANALYSIS_ID
SMTP_HOSTNAME=localhost
EOF
    
    log "Successfully generated .env file"
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
        openssl \
        uuid-runtime \
        bc
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
        check_docker_compose
    fi

    # Create installation directory
    log "Creating installation directory: $INSTALL_DIR"
    if [ -d "$INSTALL_DIR" ]; then
        log "Directory exists. Cleaning up..."
        rm -rf "$INSTALL_DIR"/*
    else
        mkdir -p "$INSTALL_DIR"
    fi
    cd "$INSTALL_DIR"

    # Clone OpenCTI Docker repository
    log "Cloning OpenCTI Docker repository..."
    git clone https://github.com/OpenCTI-Platform/docker.git .
    
    # Configure ElasticSearch and RabbitMQ
    configure_elasticsearch
    configure_rabbitmq

    # Generate .env file
    generate_env_file

    if [ "$ENV_ONLY" = true ]; then
        log "Environment file generated. Exiting..."
        exit 0
    fi

    # Start OpenCTI
    log "Starting OpenCTI services..."
    docker-compose up -d

    log "Installation completed successfully!"
    log "OpenCTI will be available at http://localhost:8080"
    log "Please check the log file for the generated credentials"
}

# Run main function
main 