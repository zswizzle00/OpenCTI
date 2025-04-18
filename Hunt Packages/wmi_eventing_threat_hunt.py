#!/usr/bin/env python3
"""
WMI Eventing Threat Hunt Script
Based on the Threat Hunter Playbook article: https://threathunterplaybook.com/hunts/windows/190810-WMIEventing/notebook.html
"""

import pandas as pd
import numpy as np
import requests
from zipfile import ZipFile
from io import BytesIO
import matplotlib.pyplot as plt
import seaborn as sns
import os
from datetime import datetime, timedelta
import argparse
from dotenv import load_dotenv
import json
import sys

# Import Sumo Logic SDK
try:
    from sumologic import SumoLogic
except ImportError:
    print("Sumo Logic SDK not installed. Please install it using: pip install sumologic-sdk")

# Import Google Cloud Security Center
try:
    from google.cloud import securitycenter
    from google.cloud.securitycenter_v1 import SecurityCenterClient
except ImportError:
    print("Google Cloud Security Center SDK not installed. Please install it using: pip install google-cloud-securitycenter")

def setup_environment():
    """Set up the environment and display options"""
    # Set display options for better readability
    pd.set_option('display.max_columns', None)
    pd.set_option('display.max_rows', 100)
    pd.set_option('display.width', 1000)
    
    # Create output directory if it doesn't exist
    if not os.path.exists('output'):
        os.makedirs('output')

def load_credentials():
    """Load credentials from environment variables"""
    load_dotenv()
    return {
        'sumo_access_id': os.getenv('SUMO_ACCESS_ID'),
        'sumo_access_key': os.getenv('SUMO_ACCESS_KEY'),
        'sumo_endpoint': os.getenv('SUMO_ENDPOINT'),
        'google_project_id': os.getenv('GOOGLE_PROJECT_ID'),
        'google_organization_id': os.getenv('GOOGLE_ORGANIZATION_ID')
    }

def connect_to_sumo_logic(credentials):
    """Connect to Sumo Logic instance"""
    if not all([credentials['sumo_access_id'], credentials['sumo_access_key'], credentials['sumo_endpoint']]):
        print("Missing Sumo Logic credentials. Please set SUMO_ACCESS_ID, SUMO_ACCESS_KEY, and SUMO_ENDPOINT environment variables.")
        return None
    
    try:
        return SumoLogic(
            credentials['sumo_access_id'],
            credentials['sumo_access_key'],
            credentials['sumo_endpoint']
        )
    except Exception as e:
        print(f"Error connecting to Sumo Logic: {str(e)}")
        return None

def connect_to_google_securitycenter(credentials):
    """Connect to Google Security Center instance"""
    if not credentials['google_organization_id']:
        print("Missing Google organization ID. Please set GOOGLE_ORGANIZATION_ID environment variable.")
        return None, None
    
    try:
        client = SecurityCenterClient()
        org_name = f"organizations/{credentials['google_organization_id']}"
        return client, org_name
    except Exception as e:
        print(f"Error connecting to Google Security Center: {str(e)}")
        return None, None

def fetch_sumo_logic_data(sumo_client, time_range_hours=24):
    """Fetch WMI event data from Sumo Logic"""
    if not sumo_client:
        return None
    
    try:
        # Define the search query for WMI events
        query = """
        _sourceCategory=Windows/System
        | where _raw matches "WMI"
        | parse "*" as event_data
        | json field=event_data "Channel", "EventID", "Hostname", "User", "EventNamespace", "Name", "Query", "Type", "Destination", "Operation", "Consumer", "Filter"
        | where Channel in ("Microsoft-Windows-Sysmon/Operational", "Microsoft-Windows-WMI-Activity/Operational")
        """
        
        # Calculate time range
        end_time = datetime.now()
        start_time = end_time - timedelta(hours=time_range_hours)
        
        # Execute the search
        search_job = sumo_client.search_job(query, fromTime=start_time, toTime=end_time)
        results = sumo_client.search_job_records(search_job)
        
        # Convert results to DataFrame
        df = pd.DataFrame(results)
        return df
    
    except Exception as e:
        print(f"Error fetching data from Sumo Logic: {str(e)}")
        return None

def fetch_google_securitycenter_data(client, org_name, time_range_hours=24):
    """Fetch WMI event data from Google Security Center"""
    if not client or not org_name:
        return None
    
    try:
        # Calculate time range
        end_time = datetime.now()
        start_time = end_time - timedelta(hours=time_range_hours)
        
        # Create the filter for WMI events
        filter_str = (
            'category="WMI" OR '
            'sourceProperties.description:"Windows Management Instrumentation" OR '
            'sourceProperties.eventType:"WMI_EVENT"'
        )
        
        # List findings
        findings_iterator = client.list_findings(
            request={
                "parent": org_name,
                "filter": filter_str,
                "orderBy": "eventTime desc"
            }
        )
        
        # Convert findings to DataFrame
        findings = []
        for finding in findings_iterator:
            finding_dict = {
                '@timestamp': finding.event_time,
                'Channel': finding.category,
                'EventID': finding.finding_id,
                'Hostname': finding.resource_name,
                'User': finding.source_properties.get('principal_email', ''),
                'Message': finding.source_properties.get('description', '')
            }
            findings.append(finding_dict)
        
        return pd.DataFrame(findings)
    
    except Exception as e:
        print(f"Error fetching data from Google Security Center: {str(e)}")
        return None

def download_dataset():
    """Download and extract the dataset"""
    print("Downloading dataset...")
    url = 'https://raw.githubusercontent.com/OTRF/Security-Datasets/master/datasets/atomic/windows/persistence/host/empire_wmi_local_event_subscriptions_elevated_user.zip'
    zipFileRequest = requests.get(url)
    zipFile = ZipFile(BytesIO(zipFileRequest.content))
    datasetJSONPath = zipFile.extract(zipFile.namelist()[0])
    return datasetJSONPath

def analyze_wmi_filters(df):
    """Analyze WMI event filters"""
    print("\nAnalyzing WMI Event Filters...")
    wmi_filters = df[
        (df['Channel'] == 'Microsoft-Windows-Sysmon/Operational') & 
        (df['EventID'] == 19)
    ][['@timestamp', 'Hostname', 'User', 'EventNamespace', 'Name', 'Query']]
    
    print(f"Found {len(wmi_filters)} WMI event filters")
    wmi_filters.to_csv('output/wmi_filters.csv', index=False)
    return wmi_filters

def analyze_wmi_consumers(df):
    """Analyze WMI event consumers"""
    print("\nAnalyzing WMI Event Consumers...")
    wmi_consumers = df[
        (df['Channel'] == 'Microsoft-Windows-Sysmon/Operational') & 
        (df['EventID'] == 20)
    ][['@timestamp', 'Hostname', 'User', 'Name', 'Type', 'Destination']]
    
    print(f"Found {len(wmi_consumers)} WMI event consumers")
    wmi_consumers.to_csv('output/wmi_consumers.csv', index=False)
    return wmi_consumers

def analyze_wmi_bindings(df):
    """Analyze WMI consumer bindings"""
    print("\nAnalyzing WMI Consumer Bindings...")
    wmi_bindings = df[
        (df['Channel'] == 'Microsoft-Windows-Sysmon/Operational') & 
        (df['EventID'] == 21)
    ][['@timestamp', 'Hostname', 'User', 'Operation', 'Consumer', 'Filter']]
    
    print(f"Found {len(wmi_bindings)} WMI consumer bindings")
    wmi_bindings.to_csv('output/wmi_bindings.csv', index=False)
    return wmi_bindings

def analyze_wmi_activity(df):
    """Analyze WMI activity events"""
    print("\nAnalyzing WMI Activity Events...")
    wmi_activity = df[
        (df['Channel'] == 'Microsoft-Windows-WMI-Activity/Operational') & 
        (df['EventID'] == 5861)
    ][['@timestamp', 'Hostname', 'Message']]
    
    print(f"Found {len(wmi_activity)} WMI activity events")
    wmi_activity.to_csv('output/wmi_activity.csv', index=False)
    return wmi_activity

def create_temporal_analysis(df):
    """Create temporal analysis visualization"""
    print("\nCreating temporal analysis visualization...")
    df['@timestamp'] = pd.to_datetime(df['@timestamp'])
    
    plt.figure(figsize=(12, 6))
    df['@timestamp'].hist(bins=50)
    plt.title('Distribution of WMI Events Over Time')
    plt.xlabel('Timestamp')
    plt.ylabel('Number of Events')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig('output/wmi_events_temporal.png')
    plt.close()

def generate_report():
    """Generate a summary report"""
    print("\nGenerating summary report...")
    report = f"""
WMI Eventing Threat Hunt Report
Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Analysis Results:
----------------
1. WMI Event Filters: {len(pd.read_csv('output/wmi_filters.csv'))} events found
2. WMI Event Consumers: {len(pd.read_csv('output/wmi_consumers.csv'))} events found
3. WMI Consumer Bindings: {len(pd.read_csv('output/wmi_bindings.csv'))} events found
4. WMI Activity Events: {len(pd.read_csv('output/wmi_activity.csv'))} events found

Output Files:
-------------
- wmi_filters.csv: Detailed WMI event filters
- wmi_consumers.csv: Detailed WMI event consumers
- wmi_bindings.csv: Detailed WMI consumer bindings
- wmi_activity.csv: Detailed WMI activity events
- wmi_events_temporal.png: Temporal distribution visualization

Next Steps:
----------
1. Review the CSV files for suspicious patterns
2. Check for unusual WMI event timing
3. Investigate any unexpected WMI consumers
4. Look for patterns in WMI bindings that might indicate persistence
"""
    
    with open('output/report.txt', 'w') as f:
        f.write(report)
    
    print("Analysis complete! Check the 'output' directory for results.")

def main():
    """Main function to run the WMI eventing threat hunt"""
    parser = argparse.ArgumentParser(description='WMI Eventing Threat Hunt Tool')
    parser.add_argument('--source', choices=['file', 'sumo', 'google'], default='file',
                      help='Data source to use (default: file)')
    parser.add_argument('--time-range', type=int, default=24,
                      help='Time range in hours for Sumo Logic or Google Security Center queries (default: 24)')
    args = parser.parse_args()
    
    print("Starting WMI Eventing Threat Hunt...")
    
    # Setup environment
    setup_environment()
    
    try:
        df = None
        
        if args.source == 'file':
            # Use local dataset
            dataset_path = download_dataset()
            df = pd.read_json(dataset_path, lines=True)
            print(f"Dataset loaded with {len(df)} records")
        
        elif args.source == 'sumo':
            # Connect to Sumo Logic
            credentials = load_credentials()
            sumo_client = connect_to_sumo_logic(credentials)
            df = fetch_sumo_logic_data(sumo_client, args.time_range)
            if df is not None:
                print(f"Retrieved {len(df)} records from Sumo Logic")
        
        elif args.source == 'google':
            # Connect to Google Security Center
            credentials = load_credentials()
            client, org_name = connect_to_google_securitycenter(credentials)
            df = fetch_google_securitycenter_data(client, org_name, args.time_range)
            if df is not None:
                print(f"Retrieved {len(df)} records from Google Security Center")
        
        if df is None:
            print("No data available for analysis")
            sys.exit(1)
        
        # Run analyses
        analyze_wmi_filters(df)
        analyze_wmi_consumers(df)
        analyze_wmi_bindings(df)
        analyze_wmi_activity(df)
        create_temporal_analysis(df)
        
        # Generate report
        generate_report()
        
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        raise

if __name__ == "__main__":
    main() 