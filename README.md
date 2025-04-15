# OpenCTI Installation Script

A bash script to automate the installation and configuration of OpenCTI, an open-source threat intelligence platform.

## Features

- Automated installation of OpenCTI and its dependencies
- Docker and Docker Compose installation (optional)
- Secure password generation for all services
- Environment file configuration
- Comprehensive logging
- Flexible installation options

## Prerequisites

- Ubuntu-based Linux distribution
- Root or sudo access
- Internet connection
- At least 4GB RAM (8GB recommended)
- At least 20GB free disk space

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

## Installation Process

The script performs the following steps:

1. Checks for root privileges
2. Installs prerequisites (if not skipped)
3. Installs Docker and Docker Compose (if not skipped)
4. Creates the installation directory
5. Clones the OpenCTI repository
6. Generates secure passwords and creates the .env file
7. Starts the OpenCTI services

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

## Troubleshooting

If you encounter issues:
1. Check the log file at `/var/log/opencti_install.log`
2. Ensure all prerequisites are met
3. Verify Docker and Docker Compose are properly installed
4. Check system resources (memory and disk space)

## License

This script is provided as-is under the MIT License. 
