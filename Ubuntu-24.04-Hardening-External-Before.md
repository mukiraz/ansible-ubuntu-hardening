# Vulnerability Scan Report (Before Hardening)

## General Information

* 
**Scanner Type:** Tenable Nessus (Nessus Essentials) 


* 
**Report Name:** Ubuntu-24.04-Hardening-External-Before 


* 
**Scan Date:** Thu, 04 Jun 2026 20:30:51 EDT 


* 
**Target Host:** `[MASKED_IP_ADDRESS]` *(Original IP removed for security)* 



---

## Executive Summary

The external scan performed against the target host detected a total of **4 findings**. This includes **1 Low-severity** vulnerability and **3 Informational** findings. No Critical, High, or Medium risk vulnerabilities were identified.

| Severity | Count |
| --- | --- |
| **CRITICAL** | 0 

 |
| **HIGH** | 0 

 |
| **MEDIUM** | 0 

 |
| **LOW** | 1 

 |
| **INFO** | 3 

 |

---

## Scan Findings & Enumeration Details

The following table lists the plugins triggered during the pre-hardening scan.

| Severity | CVSS v3.0 | Plugin ID | Plugin Name / Detected Feature |
| --- | --- | --- | --- |
| **LOW** | 2.1* 

 | 10114 

 | ICMP Timestamp Request Remote Date Disclosure 

 |
| **INFO** | N/A 

 | 12053 

 | Host Fully Qualified Domain Name (FQDN) Resolution `[MASKED_FQDN]` 

 |
| **INFO** | N/A 

 | 19506 

 | Nessus Scan Information 

 |
| **INFO** | N/A 

 | 10287 

 | Traceroute Information `[MASKED_ROUTE_DETAILS]` 

 |

** Indicates the v3.0 score was not available; the v2.0 score is shown.* 