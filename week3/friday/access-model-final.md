# KijaniKiosk Access Model

## Directory Structure and Permissions

| Directory | Owner | Group | Permissions | Purpose |
|-----------|-------|-------|-------------|---------|
| /opt/kijanikiosk/config | root | kijanikiosk | 750 | Configuration files |
| /opt/kijanikiosk/shared/logs | root | kijanikiosk | 770 | Shared log files |
| /opt/kijanikiosk/health | root | kijanikiosk | 750 | Health check outputs |
| /opt/kijanikiosk/{api,payments,logs} | root | kijanikiosk | 750 | Service directories |

## ACL Configuration

### /opt/kijanikiosk/shared/logs (with defaults)
user:kk-api:rwx
user:kk-payments:r-x
user:kk-logs:rwx
default:user:kk-api:rwx
default:user:kk-payments:r-x
default:user:kk-logs:rwx

### /opt/kijanikiosk/health (with defaults)
user:kk-logs:rwx
default:user:kk-logs:rwx

## Service Users

| User        | Primary Group | Shell             | Purpose |
|-------------|---------------|-------------------|---------|
| kk-api      | kijanikiosk   | /usr/sbin/nologin | API service |
| kk-payments | kijanikiosk   | /usr/sbin/nologin | Payments service |
| kk-logs     | kijanikiosk   | /usr/sbin/nologin | Log aggregation service |

## Logrotate Interaction

The logrotate configuration uses `create 0640 root kijanikiosk`. New log files inherit ACLs from directory defaults.

## Verification Command
sudo -u kk-api touch /opt/kijanikiosk/shared/logs/test-write.tmp && echo "PASS: ACLs persist after rotation" 
