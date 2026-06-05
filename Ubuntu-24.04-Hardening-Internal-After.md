# Vulnerability Scan Report (Internal After Hardening)

## General Information

* 
**Scanner Type:** Tenable Nessus (Nessus Essentials) 


* 
**Report Name:** Ubuntu-24.04-Hardening-Internal-After 


* 
**Scan Date:** Thu, 04 Jun 2026 21:05:59 EDT 


* 
**Target Host:** `[MASKED_IP_ADDRESS]` *(Original IP removed for security)* 



---

## Executive Summary

The internal credentialed scan performed against the target host detected a total of **51 informational findings**. No Critical, High, Medium, or Low risk vulnerabilities were identified during this assessment.

Because this was an authenticated internal scan, Nessus successfully logged into the host via SSH using valid credentials , allowing it to perform a deeper inspection of local packages, running processes, and system configurations.

| Severity | Count |
| --- | --- |
| **CRITICAL** | 0 

 |
| **HIGH** | 0 

 |
| **MEDIUM** | 0 

 |
| **LOW** | 0 

 |
| **INFO** | 51 

 |

---

## Scan Findings & Enumeration Details

The following table lists the plugins triggered during the internal scan. All findings are classified as **INFO** (Informational).

| Severity | CVSS v3.0 | Plugin ID | Plugin Name / Detected Feature |
| --- | --- | --- | --- |
| **INFO** | N/A | 156000 | Apache Log4j Installed (Linux / Unix) 

 |
| **INFO** | N/A | 34098 | BIOS Info (SSH) 

 |
| **INFO** | N/A | 39520 | Backported Security Patch Detection (SSH) 

 |
| **INFO** | N/A | 45590 | Common Platform Enumeration (CPE) 

 |
| **INFO** | N/A | 182774 | Curl Installed (Linux / Unix) 

 |
| **INFO** | N/A | 55472 | Device Hostname `[MASKED_HOSTNAME]` 

 |
| **INFO** | N/A | 54615 | Device Type 

 |
| **INFO** | N/A | 25203 | Enumerate IPv4 Interfaces via SSH 

 |
| **INFO** | N/A | 33276 | Enumerate MAC Addresses via SSH 

 |
| **INFO** | N/A | 170170 | Enumerate the Network Interface configuration via SSH 

 |
| **INFO** | N/A | 179200 | Enumerate the Network Routing configuration via SSH 

 |
| **INFO** | N/A | 168980 | Enumerate the PATH Variables 

 |
| **INFO** | N/A | 35716 | Ethernet Card Manufacturer Detection 

 |
| **INFO** | N/A | 86420 | Ethernet MAC Addresses 

 |
| **INFO** | N/A | 12053 | Host Fully Qualified Domain Name (FQDN) Resolution `[MASKED_FQDN]` 

 |
| **INFO** | N/A | 171410 | IP Assignment Method Detection 

 |
| **INFO** | N/A | 151883 | Libgcrypt Installed (Linux/UNIX) 

 |
| **INFO** | N/A | 157358 | Linux Mounted Devices 

 |
| **INFO** | N/A | 193143 | Linux Time Zone Information 

 |
| **INFO** | N/A | 95928 | Linux User List Enumeration 

 |
| **INFO** | N/A | 19506 | Nessus Scan Information 

 |
| **INFO** | N/A | 209654 | OS Fingerprints Detected 

 |
| **INFO** | N/A | 11936 | OS Identification 

 |
| **INFO** | N/A | 97993 | OS Identification and Installed Software Enumeration over SSH (Using New SSH Library) 

 |
| **INFO** | N/A | 117887 | OS Security Patch Assessment Available 

 |
| **INFO** | N/A | 181418 | OpenSSH Detection 

 |
| **INFO** | N/A | 168007 | OpenSSL Installed (Linux) 

 |
| **INFO** | N/A | 179139 | Package Manager Packages Report (nix) 

 |
| **INFO** | N/A | 277650 | Remote Services Not Using Post-Quantum Ciphers 

 |
| **INFO** | N/A | 70657 | SSH Algorithms and Languages Supported 

 |
| **INFO** | N/A | 102094 | SSH Commands Require Privilege Escalation 

 |
| **INFO** | N/A | 149334 | SSH Password Authentication Accepted 

 |
| **INFO** | N/A | 10881 | SSH Protocol Versions Supported 

 |
| **INFO** | N/A | 90707 | SSH SCP Protocol Detection 

 |
| **INFO** | N/A | 153588 | SSH SHA-1 HMAC Algorithms Enabled 

 |
| **INFO** | N/A | 10267 | SSH Server Type and Version Information 

 |
| **INFO** | N/A | 22964 | Service Detection 

 |
| **INFO** | N/A | 22869 | Software Enumeration (SSH) 

 |
| **INFO** | N/A | 163103 | System Restart Required 

 |
| **INFO** | N/A | 110385 | Target Credential Issues by Authentication Protocol - Insufficient Privilege 

 |
| **INFO** | N/A | 141118 | Target Credential Status by Authentication Protocol - Valid Credentials Provided 

 |
| **INFO** | N/A | 56468 | Time of Last System Startup 

 |
| **INFO** | N/A | 10287 | Traceroute Information `[MASKED_ROUTE_DETAILS]` 

 |
| **INFO** | N/A | 192709 | Tukaani XZ Utils Installed (Linux / Unix) 

 |
| **INFO** | N/A | 198218 | Ubuntu Pro Subscription Detection 

 |
| **INFO** | N/A | 110483 | Unix/Linux Running Processes Information 

 |
| **INFO** | N/A | 152743 | Unix Software Discovery Commands Not Available 

 |
| **INFO** | N/A | 186361 | VMWare Tools or Open VM Tools Installed (Linux) 

 |
| **INFO** | N/A | 20094 | VMware Virtual Machine Detection 

 |
| **INFO** | N/A | 189731 | Vim Installed (Linux) 

 |
| **INFO** | N/A | 182848

 | libcurl Installed (Linux / Unix) 

 |