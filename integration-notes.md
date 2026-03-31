The kijanikiosk system integrates three services: kk-api, kk-payments, and kk-logs.

kk-api handles application requests and writes operational logs to the shared directory.
kk-logs manages centralized logging access and ensures log structure consistency.
kk-payments processes sensitive transactions with restricted read-only access to logs.

All services interact through a shared logging directory at /opt/kijanikiosk/shared/logs.

Logrotate ensures log files are rotated daily without disrupting active services.
