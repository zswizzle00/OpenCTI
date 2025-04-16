# Suspicious Process Creation Investigation Playbook

## Overview
This playbook provides step-by-step guidance for investigating suspicious process creation events detected by the YARA-L rule.

## Investigation Steps

### 1. Initial Triage
- Review the alert details in Google SecOps SIEM
- Check the process command line for suspicious patterns
- Verify the parent process and its legitimacy
- Check the execution time and user context

### 2. Process Analysis
- Examine the process tree
- Check for unusual process relationships
- Look for suspicious command-line arguments
- Verify process hashes against known good/bad lists

### 3. Network Analysis
- Check for outbound connections
- Look for DNS queries
- Examine network traffic patterns
- Check for data exfiltration attempts

### 4. System Impact
- Check for file modifications
- Look for registry changes
- Examine scheduled tasks
- Check for persistence mechanisms

### 5. User Context
- Verify user account legitimacy
- Check for privilege escalation
- Review user's recent activities
- Look for suspicious login patterns

### 6. Response Actions
- Document findings
- Isolate affected systems if necessary
- Collect forensic evidence
- Update detection rules if needed

## Recommended Tools
- Google SecOps SIEM
- VirusTotal
- Process Explorer
- Network monitoring tools

## References
- MITRE ATT&CK Techniques
- Internal security policies
- Previous incident reports 