# OpenCTI Ecosystem Manager

This script manages the OpenCTI ecosystem of connectors, providing an easy way to clone, update, and manage multiple OpenCTI connectors.

## Features

- Clone individual OpenCTI connectors from their respective repositories
- Update existing connectors
- Create a master docker-compose file that combines all connector configurations
- Start and stop the entire ecosystem with a single command
- List available connectors
- Manage API keys for connectors that require them
- Configure common values across all connectors

## Prerequisites

- Python 3.x
- Git
- Docker and Docker Compose
- PyYAML package (`pip install pyyaml`)

## Usage

The script provides several command-line options:

```bash
# Clone all connectors
python opencti_ecosystem.py

# Update existing connectors
python opencti_ecosystem.py --update

# List available connectors
python opencti_ecosystem.py --list

# Start the ecosystem (starts all connectors)
python opencti_ecosystem.py --start

# Stop the ecosystem (stops all connectors)
python opencti_ecosystem.py --stop

# Configure API keys for connectors
python opencti_ecosystem.py --configure

# Set up common configuration values
python opencti_ecosystem.py --setup-common
```

## Directory Structure

The script creates the following structure:
```
opencti-ecosystem/
├── connectors/
│   ├── opencti-connector-import-file-yara/
│   ├── opencti-connector-import-document/
│   ├── opencti-connector-export-file-csv/
│   └── ... (other connectors)
│   └── docker-compose.master.yml
├── opencti_config.json
└── opencti_common_config.json
```

## Configuration

### Basic Configuration

The script creates a `opencti_config.json` file that stores:
- List of repositories to clone
- Installation paths
- Connector preferences

You can modify this file to:
- Enable/disable specific connectors
- Change installation paths
- Customize connector settings

### Common Configuration

The script creates an `opencti_common_config.json` file that stores common configuration values used across all connectors:

```json
{
    "opencti": {
        "url": "http://opencti:8080",
        "token": "your-token",
        "user_id": "your-user-id",
        "user_password": "your-password"
    },
    "redis": {
        "hostname": "redis",
        "port": 6379,
        "password": "your-redis-password"
    },
    "rabbitmq": {
        "hostname": "rabbitmq",
        "port": 5672,
        "username": "your-rabbitmq-username",
        "password": "your-rabbitmq-password"
    }
}
```

These values are used to automatically update all connector docker-compose files, replacing any "ChangeMe" values with the configured values.

To set up common configuration values:
1. Run `python opencti_ecosystem.py --setup-common`
2. Enter the values when prompted
3. The script will update all connector docker-compose files with these values

### API Key Configuration

Some connectors require API keys to function. The script handles these in two ways:

1. **Automatic Configuration During Clone**:
   - When cloning a connector that requires API keys, the script will prompt for the required keys
   - Keys are stored in the connector's `config.yml` file

2. **Manual Configuration**:
   - Use `python opencti_ecosystem.py --configure` to set up API keys for existing connectors
   - The script will prompt for each required API key
   - Keys are stored securely in the connector's configuration

Connectors that require API keys are marked with "(Requires API Key)" in the connector list.

## Available Connectors

The script supports various types of connectors:

### Import Connectors
- File Import (YARA, Document, MISP, PDF, DOCX, XLSX)
- External Import (CVE, MITRE ATT&CK, MITRE ATLAS, DISARM, CPE, MISP Feed, TAXII 2.0)
- Additional External Import (Abuse SSL, Cyber Campaign Collection, CISA Known Exploited Vulnerabilities, CRT.sh, Ransomware.live, Valhalla)

### Export Connectors
- File Export (CSV, TXT, PDF, DOCX, XLSX)
- Report Export (PDF)
- TTPs File Navigator

### Enrichment Connectors
- DNSTwist
- Google DNS
- Data Hygiene
- Tagger
- YARA

### API Key Required Connectors
- AbuseIPDB IP Blacklist
- AlienVault
- CrowdStrike
- SOCPrime
- Intezer Sandbox
- IPInfo
- IPQS
- Shodan
- URLScan
- Google SecOps SIEM
- CrowdStrike Endpoint Security

## Contributing

Feel free to submit issues and enhancement requests! 