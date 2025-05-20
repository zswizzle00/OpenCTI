#!/usr/bin/env python3

import os
import sys
import json
import subprocess
import yaml
from typing import Dict, List
import argparse

# OpenCTI Ecosystem Repositories
REPOSITORIES = {
    "opencti-connector-import-file-yara": {
        "name": "Import File YARA Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-import-file-yara.git",
        "branch": "master"
    },
    "opencti-connector-import-document": {
        "name": "Import Document Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-import-document.git",
        "branch": "master"
    },
    "opencti-connector-export-file-csv": {
        "name": "Export File CSV Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-export-file-csv.git",
        "branch": "master"
    },
    "opencti-connector-export-file-txt": {
        "name": "Export File TXT Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-export-file-txt.git",
        "branch": "master"
    },
    "opencti-connector-import-file-misp": {
        "name": "Import File MISP Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-import-file-misp.git",
        "branch": "master"
    },
    "opencti-connector-import-file-pdf": {
        "name": "Import File PDF Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-import-file-pdf.git",
        "branch": "master"
    },
    "opencti-connector-import-file-docx": {
        "name": "Import File DOCX Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-import-file-docx.git",
        "branch": "master"
    },
    "opencti-connector-import-file-xlsx": {
        "name": "Import File XLSX Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-import-file-xlsx.git",
        "branch": "master"
    },
    "opencti-connector-export-file-pdf": {
        "name": "Export File PDF Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-export-file-pdf.git",
        "branch": "master"
    },
    "opencti-connector-export-file-docx": {
        "name": "Export File DOCX Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-export-file-docx.git",
        "branch": "master"
    },
    "opencti-connector-export-file-xlsx": {
        "name": "Export File XLSX Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-export-file-xlsx.git",
        "branch": "master"
    },
    "opencti-connector-export-report-pdf": {
        "name": "Export Report PDF Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-export-report-pdf.git",
        "branch": "master"
    },
    "opencti-connector-export-ttps-file-navigator": {
        "name": "Export TTPs File Navigator Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-export-ttps-file-navigator.git",
        "branch": "master"
    },
    "opencti-connector-import-document-ai": {
        "name": "Import Document AI Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-import-document-ai.git",
        "branch": "master"
    },
    "opencti-connector-enrichment-dnstwist": {
        "name": "DNSTwist Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-enrichment-dnstwist.git",
        "branch": "master"
    },
    "opencti-connector-enrichment-google-dns": {
        "name": "Google DNS Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-enrichment-google-dns.git",
        "branch": "master"
    },
    "opencti-connector-enrichment-hygiene": {
        "name": "Data Hygiene Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-enrichment-hygiene.git",
        "branch": "master"
    },
    "opencti-connector-enrichment-tagger": {
        "name": "Tagger Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-enrichment-tagger.git",
        "branch": "master"
    },
    "opencti-connector-enrichment-yara": {
        "name": "YARA Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-enrichment-yara.git",
        "branch": "master"
    },
    "opencti-connector-external-import-cve": {
        "name": "CVE External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-cve.git",
        "branch": "master"
    },
    "opencti-connector-external-import-mitre": {
        "name": "MITRE ATT&CK External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-mitre.git",
        "branch": "master"
    },
    "opencti-connector-external-import-mitre-atlas": {
        "name": "MITRE ATLAS External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-mitre-atlas.git",
        "branch": "master"
    },
    "opencti-connector-external-import-disarm": {
        "name": "DISARM Framework External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-disarm.git",
        "branch": "master"
    },
    "opencti-connector-external-import-cpe": {
        "name": "CPE External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-cpe.git",
        "branch": "master"
    },
    "opencti-connector-external-import-misp-feed": {
        "name": "MISP Feed External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-misp-feed.git",
        "branch": "master"
    },
    "opencti-connector-external-import-taxii2": {
        "name": "TAXII 2.0 External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-taxii2.git",
        "branch": "master"
    },
    "opencti-connector-external-import-abuse-ssl": {
        "name": "Abuse SSL External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-abuse-ssl.git",
        "branch": "master"
    },
    "opencti-connector-external-import-cyber-campaign-collection": {
        "name": "Cyber Campaign Collection External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-cyber-campaign-collection.git",
        "branch": "master"
    },
    "opencti-connector-external-import-cisa-known-exploited-vulnerabilities": {
        "name": "CISA Known Exploited Vulnerabilities External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-cisa-known-exploited-vulnerabilities.git",
        "branch": "master"
    },
    "opencti-connector-external-import-crtsh": {
        "name": "CRT.sh External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-crtsh.git",
        "branch": "master"
    },
    "opencti-connector-external-import-ransomwarelive": {
        "name": "Ransomware.live External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-ransomwarelive.git",
        "branch": "master"
    },
    "opencti-connector-external-import-valhalla": {
        "name": "Valhalla External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-external-import-valhalla.git",
        "branch": "master"
    }
}

def setup_config() -> Dict:
    """Create or load configuration file."""
    config_file = "opencti_config.json"
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            return json.load(f)
    
    config = {
        "repositories": {repo: True for repo in REPOSITORIES.keys()},
        "connectors_path": os.path.join(os.getcwd(), "opencti-ecosystem", "connectors")
    }
    
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=4)
    
    return config

def clone_repository(repo_name: str, repo_info: Dict, connectors_path: str) -> bool:
    """Clone a single repository directly to the connectors folder."""
    connector_path = os.path.join(connectors_path, repo_name)
    
    if os.path.exists(connector_path):
        print(f"Repository {repo_name} already exists. Skipping...")
        return True
    
    print(f"Cloning {repo_info['name']}...")
    try:
        subprocess.run(
            ["git", "clone", "-b", repo_info["branch"], repo_info["url"], connector_path],
            check=True,
            capture_output=True
        )
        print(f"Successfully cloned {repo_name}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error cloning {repo_name}: {e.stderr.decode()}")
        return False

def create_master_docker_compose(connectors_path: str) -> bool:
    """Create a master docker-compose file that includes all connectors."""
    master_compose = {
        'version': '3',
        'services': {}
    }

    # Walk through connectors directory
    for connector_name in os.listdir(connectors_path):
        connector_path = os.path.join(connectors_path, connector_name)
        if os.path.isdir(connector_path):
            compose_file = os.path.join(connector_path, 'docker-compose.yml')
            if os.path.exists(compose_file):
                try:
                    with open(compose_file, 'r') as f:
                        connector_compose = yaml.safe_load(f)
                        if connector_compose and 'services' in connector_compose:
                            # Add each service from the connector's docker-compose
                            for service_name, service_config in connector_compose['services'].items():
                                # Modify the service name to be unique
                                unique_service_name = f"{connector_name}_{service_name}"
                                master_compose['services'][unique_service_name] = service_config
                                
                                # Update the service name in the configuration
                                master_compose['services'][unique_service_name]['container_name'] = unique_service_name
                                
                                # Add connector name as a label
                                if 'labels' not in master_compose['services'][unique_service_name]:
                                    master_compose['services'][unique_service_name]['labels'] = {}
                                master_compose['services'][unique_service_name]['labels']['connector'] = connector_name
                except Exception as e:
                    print(f"Error processing {compose_file}: {str(e)}")

    # Write the master docker-compose file
    master_compose_path = os.path.join(connectors_path, 'docker-compose.master.yml')
    try:
        with open(master_compose_path, 'w') as f:
            yaml.dump(master_compose, f, default_flow_style=False)
        print(f"Created master docker-compose file at {master_compose_path}")
        return True
    except Exception as e:
        print(f"Error creating master docker-compose file: {str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(description="OpenCTI Ecosystem Manager")
    parser.add_argument("--list", action="store_true", help="List available repositories")
    args = parser.parse_args()

    config = setup_config()
    connectors_path = config["connectors_path"]

    if args.list:
        print("\nAvailable OpenCTI Ecosystem Repositories:")
        for repo_name, repo_info in REPOSITORIES.items():
            print(f"- {repo_info['name']} ({repo_name})")
        return

    if not os.path.exists(connectors_path):
        os.makedirs(connectors_path)

    print("Cloning selected repositories...")
    for repo_name, repo_info in REPOSITORIES.items():
        if config["repositories"][repo_name]:
            clone_repository(repo_name, repo_info, connectors_path)
    
    # Create master docker-compose after cloning
    create_master_docker_compose(connectors_path)
    print("\nSetup complete! You can now configure each connector manually.")
    print(f"Master docker-compose file created at: {os.path.join(connectors_path, 'docker-compose.master.yml')}")

if __name__ == "__main__":
    main() 