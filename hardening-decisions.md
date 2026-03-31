# Hardening Decisions

| Decision | Implementation | Reason | Trade-off |
|----------|---------------|--------|----------|
| ACL-based access control | kk-api rwx, kk-payments r-x | Prevent unauthorized log modification | Slight complexity in setup |
| Logrotate configuration | daily rotation with su directive | Ensures log integrity | Requires correct permissions |
| Service separation | 3 independent systemd services | Isolation of responsibilities | More configuration overhead |

## Gaps / Limitations
- No full SELinux enforcement
- Limited runtime monitoring
- Basic health check implementation only
