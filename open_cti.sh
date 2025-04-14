#!/bin/bash

# Exit immediately if a command fails
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file for debugging
LOG_FILE="/var/log/opencti_install.log"

# Defaults for argument parsing
INSTALL_DIR="/opt/opencti"
SKIP_DOCKER_INSTALL=false
ENV_FILE_ONLY=false

# Function to log messages
log_message() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to display help
show_help() {
    echo -e "${YELLOW}Usage: $0 [options]${NC}"
    echo "Options:"
    echo "  -h, --help                Show this help message and exit"
    echo "  -d, --directory <path>    Specify the installation directory (default: /opt/opencti)"
    echo "  -s, --skip-docker         Skip Docker and Docker Compose installation"
    echo "  -e, --env-only            Only generate the .env file, skip installation steps"
    exit 0
}

# Parse arguments
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
            SKIP_DOCKER_INSTALL=true
            shift
            ;;
        -e|--env-only)
            ENV_FILE_ONLY=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

log_message "${GREEN}Starting OpenCTI Installation...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_message "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install required packages
install_prerequisites() {
    log_message "${YELLOW}Checking and installing prerequisites...${NC}"
    apt-get update >> "$LOG_FILE" 2>&1 || { log_message "${RED}Failed to update package list${NC}"; exit 1; }
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git python3 python3-pip build-essential libssl-dev libffi-dev python3-dev >> "$LOG_FILE" 2>&1
}

# Install Docker
install_docker() {
    if ! command_exists docker; then
        log_message "${YELLOW}Installing Docker...${NC}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update >> "$LOG_FILE" 2>&1 || { log_message "${RED}Failed to update Docker package list${NC}"; exit 1; }
        apt-get install -y docker-ce docker-ce-cli containerd.io >> "$LOG_FILE" 2>&1 || { log_message "${RED}Failed to install Docker${NC}"; exit 1; }
        systemctl enable docker
        systemctl start docker
    fi
}

# Install Docker Compose
install_docker_compose() {
    if ! command_exists docker-compose; then
        log_message "${YELLOW}Installing Docker Compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
}

# Securely generate random passwords
generate_password() {
    openssl rand -base64 12
}

# Create environment file
create_env_file() {
    log_message "${YELLOW}Creating environment configuration...${NC}"
    mkdir -p "$INSTALL_DIR/opencti"
    cat > "$INSTALL_DIR/opencti/.env" << EOL
# OpenCTI Configuration
OPENCTI_ADMIN_EMAIL=admin@opencti.io
OPENCTI_ADMIN_PASSWORD=$(generate_password)
OPENCTI_ADMIN_TOKEN=$(generate_password)
OPENCTI_BASE_URL=http://localhost:8080

# RabbitMQ Configuration
RABBITMQ_DEFAULT_USER=opencti
RABBITMQ_DEFAULT_PASS=$(generate_password)

# Redis Configuration
REDIS_PASSWORD=$(generate_password)

# Elasticsearch Configuration
ELASTICSEARCH_URL=http://elasticsearch:9200
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=$(generate_password)

# MinIO Configuration
MINIO_ROOT_USER=opencti
MINIO_ROOT_PASSWORD=$(generate_password)
EOL
    log_message "${GREEN}.env file created at $INSTALL_DIR/opencti/.env${NC}"
}

# Main function to coordinate the setup
main() {
    if $ENV_FILE_ONLY; then
        create_env_file
        log_message "${GREEN}Environment file generation complete. Exiting as requested.${NC}"
        exit 0
    fi

    install_prerequisites

    if ! $SKIP_DOCKER_INSTALL; then
        install_docker
        install_docker_compose
    else
        log_message "${YELLOW}Skipping Docker installation as requested.${NC}"
    fi

    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
    fi

    log_message "${YELLOW}Cloning OpenCTI repository...${NC}"
    cd "$INSTALL_DIR"
    if [ ! -d "opencti" ]; then
        git clone https://github.com/OpenCTI-Platform/opencti.git || { log_message "${RED}Failed to clone repository${NC}"; exit 1; }
    fi

    create_env_file

    log_message "${YELLOW}Starting OpenCTI...${NC}"
    cd "$INSTALL_DIR/opencti"
    docker-compose up -d || { log_message "${RED}Failed to start OpenCTI${NC}"; exit 1; }

    log_message "${GREEN}OpenCTI installation completed!${NC}"
    log_message "${GREEN}Please wait a few minutes for all services to start up.${NC}"
    log_message "${GREEN}You can access OpenCTI at: http://localhost:8080${NC}"
    log_message "${YELLOW}Default credentials:${NC}"
    log_message "Email: admin@opencti.io"
    log_message "Password: (Generated in the .env file)"
    log_message "${YELLOW}Please change these credentials after your first login!${NC}"
}

# Execute main function
main
