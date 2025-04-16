from datetime import datetime, timedelta
from google.cloud import securitycenter
from google.cloud import logging
import pandas as pd
from typing import List, Dict, Any

def search_security_findings(
    client: securitycenter.SecurityCenterClient,
    organization_id: str,
    query: str,
    time_window: int = 24
) -> List[Dict[str, Any]]:
    """
    Search for security findings within a specified time window.
    
    Args:
        client: Security Center client
        organization_id: Organization ID
        query: Search query
        time_window: Hours to look back (default: 24)
    
    Returns:
        List of findings matching the query
    """
    parent = f"organizations/{organization_id}"
    filter_str = f"state = \"ACTIVE\" AND event_time >= \"{(datetime.utcnow() - timedelta(hours=time_window)).isoformat()}Z\""
    if query:
        filter_str += f" AND {query}"
    
    findings = []
    for finding in client.list_findings(request={"parent": parent, "filter": filter_str}):
        findings.append({
            "name": finding.name,
            "category": finding.category,
            "state": finding.state,
            "severity": finding.severity,
            "event_time": finding.event_time,
            "source_properties": dict(finding.source_properties)
        })
    
    return findings

def analyze_process_tree(
    client: securitycenter.SecurityCenterClient,
    organization_id: str,
    process_id: str,
    time_window: int = 1
) -> pd.DataFrame:
    """
    Analyze process tree for a given process ID.
    
    Args:
        client: Security Center client
        organization_id: Organization ID
        process_id: Process ID to analyze
        time_window: Hours to look back (default: 1)
    
    Returns:
        DataFrame containing process tree information
    """
    query = f"resource.type = \"process\" AND process.pid = \"{process_id}\""
    findings = search_security_findings(client, organization_id, query, time_window)
    
    process_data = []
    for finding in findings:
        props = finding["source_properties"]
        process_data.append({
            "pid": props.get("process.pid", ""),
            "ppid": props.get("process.parent.pid", ""),
            "command": props.get("process.command", ""),
            "user": props.get("process.user", ""),
            "start_time": props.get("process.start_time", ""),
            "event_time": finding["event_time"]
        })
    
    return pd.DataFrame(process_data)

def search_network_connections(
    client: securitycenter.SecurityCenterClient,
    organization_id: str,
    ip_address: str = None,
    port: int = None,
    time_window: int = 24
) -> List[Dict[str, Any]]:
    """
    Search for network connections matching specified criteria.
    
    Args:
        client: Security Center client
        organization_id: Organization ID
        ip_address: IP address to search for
        port: Port number to search for
        time_window: Hours to look back (default: 24)
    
    Returns:
        List of network connections matching the criteria
    """
    query_parts = ["resource.type = \"network_connection\""]
    if ip_address:
        query_parts.append(f"network.remote_ip = \"{ip_address}\"")
    if port:
        query_parts.append(f"network.remote_port = {port}")
    
    return search_security_findings(client, organization_id, " AND ".join(query_parts), time_window)

def get_user_activity(
    client: securitycenter.SecurityCenterClient,
    organization_id: str,
    username: str,
    time_window: int = 24
) -> pd.DataFrame:
    """
    Get activity for a specific user.
    
    Args:
        client: Security Center client
        organization_id: Organization ID
        username: Username to search for
        time_window: Hours to look back (default: 24)
    
    Returns:
        DataFrame containing user activity
    """
    query = f"principal.user = \"{username}\""
    findings = search_security_findings(client, organization_id, query, time_window)
    
    activity_data = []
    for finding in findings:
        props = finding["source_properties"]
        activity_data.append({
            "event_type": finding["category"],
            "resource": props.get("resource.name", ""),
            "action": props.get("action", ""),
            "event_time": finding["event_time"],
            "severity": finding["severity"]
        })
    
    return pd.DataFrame(activity_data) 