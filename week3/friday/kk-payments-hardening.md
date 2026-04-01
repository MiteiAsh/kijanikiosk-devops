# kk-payments Hardening Iteration Log

## Starting Score: 3.1

## Hardening Iterations

### Iteration 1: System Call Filtering
Added: `SystemCallFilter=~@privileged @resources @swap @reboot @raw-io`
**Score: 2.8**

### Iteration 2: Kernel Protection
Added: `ProtectKernelLogs=yes`, `ProtectClock=yes`, `ProtectHostname=yes`
**Score: 2.5**

### Iteration 3: Process Restrictions
Added: `RestrictSUIDSGID=yes`, `LockPersonality=yes`, `RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX`
**Score: 2.3**

### Iteration 4: UMask
Added: `UMask=0027`
**Score: 2.1** ✅

## Final Score: 2.1 (Target: < 2.5)

## Directives Not Used

| Directive | Reason |
|-----------|--------|
| PrivateNetwork=yes | Service needs network access to payment gateways |
| IPAddressDeny | Payment APIs have variable IP addresses |
## Final Score: 2.1 ✅ (Target: < 2.5)

## systemd-analyze security Output
```
  NAME                                                        DESCRIPTION                                                                                                EXPOSURE
✓ SystemCallFilter=~@swap                                     System call deny list defined for service, and @swap is included                                           
✓ SystemCallFilter=~@resources                                System call deny list defined for service, and @resources is included                                      
✓ SystemCallFilter=~@reboot                                   System call deny list defined for service, and @reboot is included                                         
✓ SystemCallFilter=~@raw-io                                   System call deny list defined for service, and @raw-io is included                                         
✓ SystemCallFilter=~@privileged                               System call deny list defined for service, and @privileged is included                                     
✗ SystemCallFilter=~@obsolete                                 System call deny list defined for service, and @obsolete is not included (e.g. afs_syscall is allowed)          0.1
✗ SystemCallFilter=~@mount                                    System call deny list defined for service, and @mount is not included (e.g. fsconfig is allowed)                0.2
✓ SystemCallFilter=~@module                                   System call deny list defined for service, and @module is included                                         
✗ SystemCallFilter=~@debug                                    System call deny list defined for service, and @debug is not included (e.g. lookup_dcookie is allowed)          0.2
✗ SystemCallFilter=~@cpu-emulation                            System call deny list defined for service, and @cpu-emulation is not included (e.g. modify_ldt is allowed)      0.1
✓ SystemCallFilter=~@clock                                    System call deny list defined for service, and @clock is included                                          
✗ RemoveIPC=                                                  Service user may leave SysV IPC objects around                                                                  0.1
✗ RootDirectory=/RootImage=                                   Service runs within the host's root directory                                                                   0.1
✓ User=/DynamicUser=                                          Service runs under a static non-root user identity                                                         
✓ RestrictRealtime=                                           Service realtime scheduling access is restricted                                                           
✓ CapabilityBoundingSet=~CAP_SYS_TIME                         Service processes cannot change the system clock                                                           
✓ NoNewPrivileges=                                            Service processes cannot acquire new privileges                                                            
✓ AmbientCapabilities=                                        Service process does not receive ambient capabilities                                                      
✓ CapabilityBoundingSet=~CAP_BPF                              Service may load BPF programs                                                                              
✗ SystemCallArchitectures=                                    Service may execute system calls with all ABIs                                                                  0.2
✗ RestrictAddressFamilies=~AF_UNIX                            Service may allocate local sockets                                                                              0.1
✗ RestrictAddressFamilies=~AF_(INET|INET6)                    Service may allocate Internet sockets                                                                           0.3
✓ ProtectSystem=                                              Service has strict read-only access to the OS file hierarchy                                               
✓ SupplementaryGroups=                                        Service has no supplementary groups                                                                        
✓ CapabilityBoundingSet=~CAP_SYS_RAWIO                        Service has no raw I/O access                                                                              
✓ CapabilityBoundingSet=~CAP_SYS_PTRACE                       Service has no ptrace() debugging abilities                                                                
✓ CapabilityBoundingSet=~CAP_SYS_(NICE|RESOURCE)              Service has no privileges to change resource use parameters                                                
✓ CapabilityBoundingSet=~CAP_NET_ADMIN                        Service has no network configuration privileges                                                            
✓ CapabilityBoundingSet=~CAP_AUDIT_*                          Service has no audit subsystem access                                                                      
✓ CapabilityBoundingSet=~CAP_SYS_ADMIN                        Service has no administrator privileges                                                                    
✓ PrivateTmp=                                                 Service has no access to other software's temporary files                                                  
✓ CapabilityBoundingSet=~CAP_SYSLOG                           Service has no access to kernel logging                                                                    
✓ ProtectHome=                                                Service has no access to home directories                                                                  
✓ PrivateDevices=                                             Service has no access to hardware devices                                                                  
✗ ProtectProc=                                                Service has full access to process tree (/proc hidepid=)                                                        0.2
✗ ProcSubset=                                                 Service has full access to non-process /proc files (/proc subset=)                                              0.1
✗ CapabilityBoundingSet=~CAP_NET_(BIND_SERVICE|BROADCAST|RAW) Service has elevated networking privileges                                                                      0.1
✗ PrivateNetwork=                                             Service has access to the host's network                                                                        0.5
✗ PrivateUsers=                                               Service has access to other users                                                                               0.2
✗ DeviceAllow=                                                Service has a device ACL with some special devices: char-rtc:r                                                  0.1
✓ KeyringMode=                                                Service doesn't share key material with other services                                                     
✓ Delegate=                                                   Service does not maintain its own delegated control group subtree                                          
✗ IPAddressDeny=                                              Service does not define an IP address allow list                                                                0.2
✓ NotifyAccess=                                               Service child processes cannot alter service state                                                         
✓ ProtectClock=                                               Service cannot write to the hardware clock or system clock                                                 
✓ CapabilityBoundingSet=~CAP_SYS_PACCT                        Service cannot use acct()                                                                                  
✓ CapabilityBoundingSet=~CAP_KILL                             Service cannot send UNIX signals to arbitrary processes                                                    
✓ ProtectKernelLogs=                                          Service cannot read from or write to the kernel log ring buffer                                            
✓ CapabilityBoundingSet=~CAP_WAKE_ALARM                       Service cannot program timers that wake up the system                                                      
✓ CapabilityBoundingSet=~CAP_(DAC_*|FOWNER|IPC_OWNER)         Service cannot override UNIX file/IPC permission checks                                                    
✓ ProtectControlGroups=                                       Service cannot modify the control group file system                                                        
✓ CapabilityBoundingSet=~CAP_LINUX_IMMUTABLE                  Service cannot mark files immutable                                                                        
✓ CapabilityBoundingSet=~CAP_IPC_LOCK                         Service cannot lock memory into RAM                                                                        
✓ ProtectKernelModules=                                       Service cannot load or read kernel modules                                                                 
✓ CapabilityBoundingSet=~CAP_SYS_MODULE                       Service cannot load kernel modules                                                                         
✓ CapabilityBoundingSet=~CAP_SYS_TTY_CONFIG                   Service cannot issue vhangup()                                                                             
✓ CapabilityBoundingSet=~CAP_SYS_BOOT                         Service cannot issue reboot()                                                                              
✓ CapabilityBoundingSet=~CAP_SYS_CHROOT                       Service cannot issue chroot()                                                                              
✓ PrivateMounts=                                              Service cannot install system mounts                                                                       
✓ CapabilityBoundingSet=~CAP_BLOCK_SUSPEND                    Service cannot establish wake locks                                                                        
✓ MemoryDenyWriteExecute=                                     Service cannot create writable executable memory mappings                                                  
✓ RestrictNamespaces=~user                                    Service cannot create user namespaces                                                                      
✓ RestrictNamespaces=~pid                                     Service cannot create process namespaces                                                                   
✓ RestrictNamespaces=~net                                     Service cannot create network namespaces                                                                   
✓ RestrictNamespaces=~uts                                     Service cannot create hostname namespaces                                                                  
✓ RestrictNamespaces=~mnt                                     Service cannot create file system namespaces                                                               
✓ CapabilityBoundingSet=~CAP_LEASE                            Service cannot create file leases                                                                          
✓ CapabilityBoundingSet=~CAP_MKNOD                            Service cannot create device nodes                                                                         
✓ RestrictNamespaces=~cgroup                                  Service cannot create cgroup namespaces                                                                    
✓ RestrictNamespaces=~ipc                                     Service cannot create IPC namespaces                                                                       
✓ ProtectHostname=                                            Service cannot change system host/domainname                                                               
✓ CapabilityBoundingSet=~CAP_(CHOWN|FSETID|SETFCAP)           Service cannot change file ownership/access mode/capabilities                                              
✓ CapabilityBoundingSet=~CAP_SET(UID|GID|PCAP)                Service cannot change UID/GID identities/capabilities                                                      
✓ LockPersonality=                                            Service cannot change ABI personality                                                                      
✓ ProtectKernelTunables=                                      Service cannot alter kernel tunables (/proc/sys, …)                                                        
✓ RestrictAddressFamilies=~AF_PACKET                          Service cannot allocate packet sockets                                                                     
✓ RestrictAddressFamilies=~AF_NETLINK                         Service cannot allocate netlink sockets                                                                    
✓ RestrictAddressFamilies=~…                                  Service cannot allocate exotic sockets                                                                     
✓ CapabilityBoundingSet=~CAP_MAC_*                            Service cannot adjust SMACK MAC                                                                            
✓ RestrictSUIDSGID=                                           SUID/SGID file creation by service is restricted                                                           
✗ UMask=                                                      Files created by service are group-readable by default                                                          0.1

→ Overall exposure level for kk-payments.service: 2.1 OK 🙂
```
