# OpenCTI Installation Script

This script automates the installation of OpenCTI on Ubuntu servers. It handles all the necessary prerequisites, configurations, and service setups required for a production-ready OpenCTI deployment.

## Prerequisites

- Ubuntu Server (tested on 20.04 LTS and 22.04 LTS)
- Minimum 10GB RAM (16GB recommended for production)
- Root or sudo access
- At least 50GB of free disk space
- Internet connectivity

## System Requirements

### Memory Requirements
- Minimum: 10GB RAM
- Recommended: 16GB RAM or more
- Memory allocations are automatically adjusted based on available system memory:
  - Limited mode (<16GB): 
    - OpenCTI: 3GB
    - Elasticsearch: 2GB
    - Redis: 1GB
  - Standard mode (16-32GB):
    - OpenCTI: 4GB
    - Elasticsearch: 4GB
    - Redis: 2GB
  - High memory mode (>32GB):
    - OpenCTI: 8GB
    - Elasticsearch: 8GB
    - Redis: 4GB

### Port Requirements
The following ports must be available:
- 8080: OpenCTI Web Interface
- 9200: Elasticsearch
- 6379: Redis
- 9000: MinIO
- 5672: RabbitMQ
- 15672: RabbitMQ Management Interface

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd opencti-install
```

2. Make the script executable:
```bash
chmod +x open_cti.sh
```

3. Run the installation script:
```bash
sudo ./open_cti.sh
```

### Optional Parameters

The script accepts several optional parameters:

```bash
sudo ./open_cti.sh [options]
```

Options:
- `-h, --help`: Show help message
- `-d, --directory <path>`: Specify installation directory (default: /opt/opencti)
- `-s, --skip-docker`: Skip Docker and Docker Compose installation
- `-e, --env-only`: Only generate the .env file, skip installation steps
- `-n, --node-memory <size>`: Set NodeJS memory limit (default: 4G)
- `-m, --es-memory <size>`: Set ElasticSearch memory limit (default: 2G)
- `-r, --redis-memory <size>`: Set Redis memory limit (default: 2G)

## What the Script Does

1. **System Configuration**
   - Configures system memory settings
   - Sets up swap space
   - Configures kernel parameters for Elasticsearch

2. **Prerequisites Installation**
   - Installs Java 11 (OpenJDK or AdoptOpenJDK)
   - Installs Docker and Docker Compose
   - Sets up required system packages

3. **Service Configuration**
   - Creates and configures Docker network
   - Sets up memory limits for all services
   - Configures health checks
   - Sets up persistent volumes

4. **Security**
   - Generates secure random passwords
   - Configures service authentication
   - Sets up proper file permissions

## Services

The installation includes the following services:

1. **OpenCTI Platform**
   - Main application server
   - Web interface
   - API endpoints

2. **Elasticsearch**
   - Search and analytics engine
   - Data storage and indexing
   - Configurable memory limits

3. **Redis**
   - Caching layer
   - Session management
   - Configurable memory limits

4. **RabbitMQ**
   - Message broker
   - Task queue management
   - Management interface

5. **MinIO**
   - Object storage
   - File storage service
   - S3-compatible interface

## Post-Installation

1. Access the web interface:
   - URL: http://localhost:8080
   - Default credentials:
     - Email: admin@opencti.io
     - Password: (Generated in .env file)

2. Change default credentials:
   - Log in with default credentials
   - Navigate to Settings > Users
   - Change admin password

3. Verify services:
```bash
cd /opt/opencti
docker-compose ps
```

## Troubleshooting

### Common Issues

1. **Java Installation Issues**
   - If Java installation fails, try installing manually:
   ```bash
   sudo apt-get update
   sudo apt-get install -y openjdk-11-jdk
   ```

2. **Memory Issues**
   - If services fail to start due to memory constraints:
   ```bash
   sudo ./open_cti.sh -m 2g -n 3g -r 1g
   ```

3. **Port Conflicts**
   - If ports are already in use:
   ```bash
   sudo lsof -i :<port_number>
   sudo kill <process_id>
   ```

### Logs

Service logs can be accessed using:
```bash
cd /opt/opencti
docker-compose logs [service_name]
```

## Maintenance

### Updating
To update OpenCTI:
```bash
cd /opt/opencti
docker-compose pull
docker-compose up -d
```

### Backup
Regular backups are recommended:
```bash
cd /opt/opencti
docker-compose exec elasticsearch elasticsearch-dump --input=http://localhost:9200/ --output=/backup/elasticsearch.json
```

## Security Considerations

1. Change all default passwords
2. Configure firewall rules
3. Enable HTTPS
4. Regular security updates
5. Monitor system resources

## Support

For issues and support:
- Open an issue in the repository
- Check the OpenCTI documentation
- Join the OpenCTI community

## Features

- Automated installation of OpenCTI and its dependencies
- Docker and Docker Compose installation (optional)
- Secure password generation for all services
- Environment file configuration
- Comprehensive logging
- Flexible installation options
- Memory configuration for all components
- System optimization for ElasticSearch

## Installation Options

The script supports several command-line options:

```bash
./open_cti.sh [options]
```

### Available Options

- `-h, --help`: Show help message and exit
- `-d, --directory <path>`: Specify the installation directory (default: /opt/opencti)
- `-s, --skip-docker`: Skip Docker and Docker Compose installation
- `-e, --env-only`: Only generate the .env file, skip installation steps
- `-n, --node-memory <size>`: Set NodeJS memory limit (default: 8G)
- `-m, --es-memory <size>`: Set ElasticSearch memory limit (default: 4G)
- `-r, --redis-memory <size>`: Set Redis memory limit (default: 8G)

## Usage Examples

1. Basic installation:
```bash
sudo ./open_cti.sh
```

2. Install to a custom directory:
```bash
sudo ./open_cti.sh -d /path/to/install
```

3. Skip Docker installation (if already installed):
```bash
sudo ./open_cti.sh -s
```

4. Generate only the environment file:
```bash
sudo ./open_cti.sh -e
```

5. Custom memory configuration:
```bash
sudo ./open_cti.sh -n 12G -m 6G -r 10G
```

## Installation Process

The script performs the following steps:

1. Checks for root privileges
2. Configures system settings for ElasticSearch
3. Installs prerequisites (if not skipped)
4. Installs Docker and Docker Compose (if not skipped)
5. Creates the installation directory
6. Clones the OpenCTI repository
7. Generates secure passwords and creates the .env file
8. Creates docker-compose.yml with memory limits
9. Starts the OpenCTI services

## Memory Configuration

The script configures memory limits for all components:

- OpenCTI Platform (NodeJS): 8GB default
- Worker: 2GB
- Redis: 8GB default (supports 2M stream limit)
- ElasticSearch: 4GB default
- MinIO: 1GB
- RabbitMQ: 2GB

These limits can be customized using the command-line options.

## System Configuration

The script automatically configures:
- `vm.max_map_count=1048575` for ElasticSearch
- Makes the setting persistent in `/etc/sysctl.conf`
- Applies system settings immediately

## Post-Installation

After installation:
- OpenCTI will be available at http://localhost:8080
- Default credentials:
  - Email: admin@opencti.io
  - Password: (Generated in the .env file)
- It is strongly recommended to change the default credentials after first login
- Services may take a few minutes to fully start up

## Intezer Sandbox Integration

The platform includes an integration with Intezer Sandbox for automated malware analysis. To set up the integration:

1. Run the Intezer setup script:
```bash
./intezer.sh
```

2. Configure the integration:
   - Navigate to `connectors/intezer-sandbox`
   - Edit the `.env` file with your credentials:
     - `OPENCTI_TOKEN`: Your OpenCTI API token
     - `INTEZER_API_KEY`: Your Intezer API key
     - Other settings can be customized as needed

3. Start the connector:
```bash
cd connectors/intezer-sandbox
docker-compose up -d
```

4. Monitor the integration:
```bash
docker-compose logs -f
```

### Intezer Integration Features
- Automated malware analysis of suspicious files
- Integration with OpenCTI's threat intelligence platform
- Real-time analysis results
- Configurable confidence levels
- Detailed logging and monitoring

## CrowdStrike Endpoint Security Integration

The platform includes an integration with CrowdStrike Endpoint Security for automated IOC management. To set up the integration:

1. Run the CrowdStrike setup script:
```bash
./crowdstrike.sh
```

2. Configure the integration:
   - Navigate to `connectors/crowdstrike-endpoint-security`
   - Edit the `.env` file with your credentials:
     - `OPENCTI_TOKEN`: Your OpenCTI API token
     - `CONNECTOR_ID`: A unique identifier for this connector
     - `CROWDSTRIKE_CLIENT_ID`: Your CrowdStrike API client ID
     - `CROWDSTRIKE_CLIENT_SECRET`: Your CrowdStrike API client secret
     - Other settings can be customized as needed

3. Start the connector:
```bash
cd connectors/crowdstrike-endpoint-security
docker-compose up -d
```

4. Monitor the integration:
```bash
docker-compose logs -f
```

### CrowdStrike Integration Features
- Automated IOC management between OpenCTI and CrowdStrike
- Support for various IOC types (domains, IPs, hashes)
- Configurable permanent deletion behavior
- Mobile device support (optional)
- Real-time synchronization
- Detailed logging and monitoring

## Logging

The script logs all operations to `/var/log/opencti_install.log` for debugging purposes.

## Security Notes

- All passwords are randomly generated using OpenSSL
- The script requires root privileges for system-level installations
- Default credentials should be changed immediately after installation
- The .env file contains sensitive information and should be properly secured
- Memory limits are set to prevent resource exhaustion
- System settings are optimized for ElasticSearch performance

## Troubleshooting

If you encounter issues:
1. Check the log file at `/var/log/opencti_install.log`
2. Ensure all prerequisites are met
3. Verify Docker and Docker Compose are properly installed
4. Check system resources (memory and disk space)
5. Verify system settings for ElasticSearch
6. Check memory limits in docker-compose.yml

## License

This script is provided as-is under the MIT License. 
