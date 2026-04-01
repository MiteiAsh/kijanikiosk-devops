# Integration Challenges Resolution

## Challenge A: ProtectSystem=strict and EnvironmentFile

**Problem:** ProtectSystem=strict makes /etc read-only.

**Solution:** Keep config at /opt/kijanikiosk/config which is not protected.

## Challenge B: Health Directory ACLs

**Problem:** New health directory needs access model.

**Solution:** Added ACLs for kk-logs to write, group to read:
setfacl -m u:kk-logs:rwx /opt/kijanikiosk/health
setfacl -d -m u:kk-logs:rwx /opt/kijanikiosk/health

## Challenge C: logrotate and PrivateTmp

**Problem:** PrivateTmp=true and reload may not work.

**Solution:** Use systemctl kill -s USR1 for custom signal.

## Challenge D: Package Holds

**Problem:** curl was on hold.

**Solution:** Temporarily unhold, install, then re-hold.
