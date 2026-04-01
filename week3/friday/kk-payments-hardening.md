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
