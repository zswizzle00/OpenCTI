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
    "opencti": {
        "name": "OpenCTI Platform",
        "url": "https://github.com/OpenCTI-Platform/opencti.git",
        "branch": "master",
        "required": True
    },
    "opencti-graphql": {
        "name": "OpenCTI GraphQL API",
        "url": "https://github.com/OpenCTI-Platform/opencti-graphql.git",
        "branch": "master",
        "required": True
    },
    "opencti-frontend": {
        "name": "OpenCTI Frontend",
        "url": "https://github.com/OpenCTI-Platform/opencti-frontend.git",
        "branch": "master",
        "required": True
    },
    "opencti-worker": {
        "name": "OpenCTI Worker",
        "url": "https://github.com/OpenCTI-Platform/opencti-worker.git",
        "branch": "master",
        "required": True
    },
    "opencti-connector-export-file-stix": {
        "name": "Export File STIX Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-export-file-stix.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-import-file-stix": {
        "name": "Import File STIX Connector",
        "url": "https://github.com/OpenCTI-Platform/connector-import-file-stix.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-import-file-yara": {
        "name": "Import File YARA Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-import-document": {
        "name": "Import Document Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-export-file-csv": {
        "name": "Export File CSV Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-export-file-txt": {
        "name": "Export File TXT Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-import-file-misp": {
        "name": "Import File MISP Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-import-file-pdf": {
        "name": "Import File PDF Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-import-file-docx": {
        "name": "Import File DOCX Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-import-file-xlsx": {
        "name": "Import File XLSX Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-export-file-pdf": {
        "name": "Export File PDF Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-export-file-docx": {
        "name": "Export File DOCX Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-export-file-xlsx": {
        "name": "Export File XLSX Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-export-report-pdf": {
        "name": "Export Report PDF Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-export-ttps-file-navigator": {
        "name": "Export TTPs File Navigator Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-import-document-ai": {
        "name": "Import Document AI Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-enrichment-dnstwist": {
        "name": "DNSTwist Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-enrichment-google-dns": {
        "name": "Google DNS Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-enrichment-hygiene": {
        "name": "Data Hygiene Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-enrichment-tagger": {
        "name": "Tagger Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-enrichment-yara": {
        "name": "YARA Enrichment Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-external-import-cve": {
        "name": "CVE External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-external-import-mitre": {
        "name": "MITRE ATT&CK External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-external-import-mitre-atlas": {
        "name": "MITRE ATLAS External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-external-import-disarm": {
        "name": "DISARM Framework External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-external-import-cpe": {
        "name": "CPE External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-external-import-misp-feed": {
        "name": "MISP Feed External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
    },
    "opencti-connector-external-import-taxii2": {
        "name": "TAXII 2.0 External Import Connector",
        "url": "https://github.com/OpenCTI-Platform/connectors.git",
        "branch": "master",
        "required": False
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
        "install_path": os.path.join(os.getcwd(), "opencti-ecosystem"),
        "connectors_path": os.path.join(os.getcwd(), "opencti-ecosystem", "connectors")
    }
    
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=4)
    
    return config

def clone_repository(repo_name: str, repo_info: Dict, install_path: str, connectors_path: str) -> bool:
    """Clone a single repository and copy to connectors folder if it's a connector."""
    repo_path = os.path.join(install_path, repo_name)
    
    if os.path.exists(repo_path):
        print(f"Repository {repo_name} already exists. Skipping...")
        return True
    
    print(f"Cloning {repo_info['name']}...")
    try:
        subprocess.run(
            ["git", "clone", "-b", repo_info["branch"], repo_info["url"], repo_path],
            check=True,
            capture_output=True
        )
        print(f"Successfully cloned {repo_name}")

        # If it's a connector, copy it to the connectors folder
        if "connector" in repo_name:
            connector_path = os.path.join(connectors_path, repo_name)
            if not os.path.exists(connector_path):
                os.makedirs(connector_path)
            
            # Copy only necessary files
            for item in os.listdir(repo_path):
                if item not in ['.git', '.github']:
                    src = os.path.join(repo_path, item)
                    dst = os.path.join(connector_path, item)
                    if os.path.isdir(src):
                        subprocess.run(["cp", "-r", src, dst], check=True)
                    else:
                        subprocess.run(["cp", src, dst], check=True)
            print(f"Copied connector to {connector_path}")

        return True
    except subprocess.CalledProcessError as e:
        print(f"Error cloning {repo_name}: {e.stderr.decode()}")
        return False

def update_repository(repo_path: str, connectors_path: str) -> bool:
    """Update an existing repository and sync with connectors folder."""
    if not os.path.exists(repo_path):
        return False
    
    print(f"Updating repository at {repo_path}...")
    try:
        subprocess.run(
            ["git", "pull"],
            cwd=repo_path,
            check=True,
            capture_output=True
        )
        print(f"Successfully updated {repo_path}")

        # If it's a connector, update the connectors folder
        repo_name = os.path.basename(repo_path)
        if "connector" in repo_name:
            connector_path = os.path.join(connectors_path, repo_name)
            if os.path.exists(connector_path):
                # Remove old files
                subprocess.run(["rm", "-rf", connector_path], check=True)
                os.makedirs(connector_path)
                
                # Copy updated files
                for item in os.listdir(repo_path):
                    if item not in ['.git', '.github']:
                        src = os.path.join(repo_path, item)
                        dst = os.path.join(connector_path, item)
                        if os.path.isdir(src):
                            subprocess.run(["cp", "-r", src, dst], check=True)
                        else:
                            subprocess.run(["cp", src, dst], check=True)
                print(f"Updated connector in {connector_path}")

        return True
    except subprocess.CalledProcessError as e:
        print(f"Error updating {repo_path}: {e.stderr.decode()}")
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

def start_ecosystem(connectors_path: str) -> bool:
    """Start the entire ecosystem using the master docker-compose file."""
    master_compose_path = os.path.join(connectors_path, 'docker-compose.master.yml')
    if not os.path.exists(master_compose_path):
        print("Master docker-compose file not found. Creating it...")
        if not create_master_docker_compose(connectors_path):
            return False

    print("Starting OpenCTI ecosystem...")
    try:
        subprocess.run(
            ["docker-compose", "-f", master_compose_path, "up", "-d"],
            cwd=connectors_path,
            check=True,
            capture_output=True
        )
        print("Successfully started OpenCTI ecosystem")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error starting ecosystem: {e.stderr.decode()}")
        return False

def stop_ecosystem(connectors_path: str) -> bool:
    """Stop the entire ecosystem using the master docker-compose file."""
    master_compose_path = os.path.join(connectors_path, 'docker-compose.master.yml')
    if not os.path.exists(master_compose_path):
        print("Master docker-compose file not found.")
        return False

    print("Stopping OpenCTI ecosystem...")
    try:
        subprocess.run(
            ["docker-compose", "-f", master_compose_path, "down"],
            cwd=connectors_path,
            check=True,
            capture_output=True
        )
        print("Successfully stopped OpenCTI ecosystem")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error stopping ecosystem: {e.stderr.decode()}")
        return False

def main():
    parser = argparse.ArgumentParser(description="OpenCTI Ecosystem Manager")
    parser.add_argument("--update", action="store_true", help="Update existing repositories")
    parser.add_argument("--list", action="store_true", help="List available repositories")
    parser.add_argument("--start", action="store_true", help="Start the ecosystem")
    parser.add_argument("--stop", action="store_true", help="Stop the ecosystem")
    args = parser.parse_args()

    config = setup_config()
    install_path = config["install_path"]
    connectors_path = config["connectors_path"]

    if args.list:
        print("\nAvailable OpenCTI Ecosystem Repositories:")
        for repo_name, repo_info in REPOSITORIES.items():
            status = "Required" if repo_info["required"] else "Optional"
            print(f"- {repo_info['name']} ({repo_name}) [{status}]")
        return

    if not os.path.exists(install_path):
        os.makedirs(install_path)
    if not os.path.exists(connectors_path):
        os.makedirs(connectors_path)

    if args.update:
        print("Updating existing repositories...")
        for repo_name in config["repositories"]:
            if config["repositories"][repo_name]:
                repo_path = os.path.join(install_path, repo_name)
                update_repository(repo_path, connectors_path)
    elif args.start:
        start_ecosystem(connectors_path)
    elif args.stop:
        stop_ecosystem(connectors_path)
    else:
        print("Cloning selected repositories...")
        for repo_name, repo_info in REPOSITORIES.items():
            if config["repositories"][repo_name]:
                clone_repository(repo_name, repo_info, install_path, connectors_path)
        # Create master docker-compose after cloning
        create_master_docker_compose(connectors_path)

if __name__ == "__main__":
    main() 