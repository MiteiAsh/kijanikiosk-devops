# KijaniKiosk Payments Service Security Hardening Documentation

## Executive Summary

This document outlines the security controls implemented for the KijaniKiosk payments service. These controls establish a security baseline appropriate for handling financial transaction data while maintaining operational functionality. The implemented controls focus on limiting attack surface, restricting system access, and ensuring compliance with payment industry security expectations.

## Security Risk Overview

The payments service represents the highest-risk component in our infrastructure. A compromise here could affect transaction integrity and customer payment data. The security controls described below create defense-in-depth that isolates the service, restricts its capabilities, and prevents privilege escalation.

## Security Controls Summary

| Control | What it does | Risk mitigated |
|---------|--------------|----------------|
| ProtectSystem=strict | Makes most system directories read-only for the service | Prevents service from modifying system binaries or configuration if compromised |
| NoNewPrivileges=yes | Prevents the service and its children from gaining new privileges | Blocks privilege escalation attacks |
| PrivateTmp=yes | Gives the service its own private /tmp directory | Prevents temp file attacks and cross-service contamination |
| PrivateDevices=yes | Hides physical devices from the service | Blocks direct hardware access that could be used for side-channel attacks |
| ProtectHome=yes | Makes /home, /root, and /run/user inaccessible | Prevents access to user data if service is compromised |
| ProtectKernelLogs=yes | Blocks access to kernel logs | Prevents information leakage about system state |
| ProtectClock=yes | Prevents writing to hardware clock | Blocks time manipulation that could affect transaction timestamps |
| RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX | Limits network protocols to IPv4, IPv6, and Unix sockets | Reduces attack surface by blocking other network protocols |
| CapabilityBoundingSet=CAP_NET_BIND_SERVICE | Limits capabilities to only network port binding | Removes unnecessary system capabilities that could be exploited |
| RestrictNamespaces=yes | Blocks namespace creation | Prevents container escape patterns and sandbox bypasses |
| MemoryDenyWriteExecute=yes | Prevents creation of writable executable memory | Mitigates memory corruption attacks and code injection |
| SystemCallFilter | Blocks privileged system calls | Prevents kernel-level attacks and unauthorized system operations |
| ReadWritePaths | Limits writable paths to log directory only | Contains any file system modifications to designated area |
| UMask=0027 | Sets restrictive file creation mask | Ensures new files are created with appropriate permissions |

## Security Decisions Explained

**Strict System Protection**: The payments service cannot modify system binaries, configuration files, or core libraries. If an attacker compromises the service, they cannot install backdoors or modify system behavior. This is the most effective single control implemented.

**Kernel Log Protection**: By blocking access to kernel logs, we prevent potential information leakage about system state, running processes, and hardware configuration that could aid an attacker in privilege escalation attempts.

**Capability Reduction**: By stripping all capabilities except network port binding, we ensure the service cannot perform actions like tracing other processes, modifying system time, or changing file ownership. Each removed capability eliminates an entire class of potential exploits.

**Network Protocol Restriction**: By limiting address families to IPv4, IPv6, and Unix sockets only, we eliminate potential attack vectors from other network protocols like Bluetooth, infrared, or specialized kernel interfaces. Each protocol family removed reduces the kernel code reachable from the compromised service, following the principle of least privilege. The payments service only needs standard TCP/IP communication, making this restriction safe to implement.

**System Call Filtering**: The service is blocked from making over 150 system calls that are not required for its operation, including calls that modify system time, manage hardware devices, or change process priorities. This dramatically reduces the kernel attack surface. Each blocked system call represents a potential privilege escalation path that an attacker cannot use, even if they achieve code execution within the service.

## Controls Investigated But Not Implemented

**PrivateNetwork=yes**: This directive would completely isolate the service network. We declined this because the payments service needs to communicate with payment gateways and the API service. Full network isolation would break core functionality.

**ProtectKernelTunables=yes**: While implemented initially, we found this directive caused issues with the service's ability to read system timezone information needed for transaction timestamps. We replaced it with more granular protection controls.

**IPAddressDeny**: Implementing strict IP filtering was considered but deferred because the service needs to communicate with external payment APIs with variable IP addresses. Application-level security provides adequate protection for this use case.

## Current Security Posture

The current configuration achieves a security score of 2.1 on systemd-analyze security, meeting the requirement of below 2.5 while maintaining full service functionality. This represents a strong security baseline for a financial transaction service.

## Current Security Gaps

This configuration does not protect against application-layer vulnerabilities such as SQL injection or insecure API design. Application security remains the responsibility of the development team. Additionally, this does not encrypt data at rest or protect against compromised dependencies in the Node.js application. Network-level protections exist through the firewall configuration but assume internal network trust.

Future improvements should include automated dependency scanning, runtime application self-protection (RASP) mechanisms, and regular security audits of the Node.js application code.
