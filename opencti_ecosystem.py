#!/usr/bin/env python3

import os
import sys
import json
import subprocess
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
        "install_path": os.path.join(os.getcwd(), "opencti-ecosystem")
    }
    
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=4)
    
    return config

def clone_repository(repo_name: str, repo_info: Dict, install_path: str) -> bool:
    """Clone a single repository."""
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
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error cloning {repo_name}: {e.stderr.decode()}")
        return False

def update_repository(repo_path: str) -> bool:
    """Update an existing repository."""
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
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error updating {repo_path}: {e.stderr.decode()}")
        return False

def main():
    parser = argparse.ArgumentParser(description="OpenCTI Ecosystem Manager")
    parser.add_argument("--update", action="store_true", help="Update existing repositories")
    parser.add_argument("--list", action="store_true", help="List available repositories")
    args = parser.parse_args()

    config = setup_config()
    install_path = config["install_path"]

    if args.list:
        print("\nAvailable OpenCTI Ecosystem Repositories:")
        for repo_name, repo_info in REPOSITORIES.items():
            status = "Required" if repo_info["required"] else "Optional"
            print(f"- {repo_info['name']} ({repo_name}) [{status}]")
        return

    if not os.path.exists(install_path):
        os.makedirs(install_path)

    if args.update:
        print("Updating existing repositories...")
        for repo_name in config["repositories"]:
            if config["repositories"][repo_name]:
                repo_path = os.path.join(install_path, repo_name)
                update_repository(repo_path)
    else:
        print("Cloning selected repositories...")
        for repo_name, repo_info in REPOSITORIES.items():
            if config["repositories"][repo_name]:
                clone_repository(repo_name, repo_info, install_path)

if __name__ == "__main__":
    main() 