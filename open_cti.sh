#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting OpenCTI Installation...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Install required packages
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    python3 \
    python3-pip \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev

# Install Docker if not present
if ! command_exists docker; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
fi

# Install Docker Compose if not present
if ! command_exists docker-compose; then
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Create directory for OpenCTI
INSTALL_DIR="/opt/opencti"
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
fi

# Clone OpenCTI repository
echo -e "${YELLOW}Cloning OpenCTI repository...${NC}"
cd "$INSTALL_DIR"
if [ ! -d "opencti" ]; then
    git clone https://github.com/OpenCTI-Platform/opencti.git
fi

# Create environment file
echo -e "${YELLOW}Creating environment configuration...${NC}"
cat > "$INSTALL_DIR/opencti/.env" << EOL
# OpenCTI Configuration
OPENCTI_ADMIN_EMAIL=admin@opencti.io
OPENCTI_ADMIN_PASSWORD=ChangeMe123!
OPENCTI_ADMIN_TOKEN=ChangeMe123!
OPENCTI_BASE_URL=http://localhost:8080

# RabbitMQ Configuration
RABBITMQ_DEFAULT_USER=opencti
RABBITMQ_DEFAULT_PASS=ChangeMe123!

# Redis Configuration
REDIS_PASSWORD=ChangeMe123!

# Elasticsearch Configuration
ELASTICSEARCH_URL=http://elasticsearch:9200
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=ChangeMe123!

# MinIO Configuration
MINIO_ROOT_USER=opencti
MINIO_ROOT_PASSWORD=ChangeMe123!
EOL

# Start OpenCTI
echo -e "${YELLOW}Starting OpenCTI...${NC}"
cd "$INSTALL_DIR/opencti"
docker-compose up -d

echo -e "${GREEN}OpenCTI installation completed!${NC}"
echo -e "${GREEN}Please wait a few minutes for all services to start up.${NC}"
echo -e "${GREEN}You can access OpenCTI at: http://localhost:8080${NC}"
echo -e "${YELLOW}Default credentials:${NC}"
echo -e "Email: admin@opencti.io"
echo -e "Password: ChangeMe123!"
echo -e "${YELLOW}Please change these credentials after your first login!${NC}"
