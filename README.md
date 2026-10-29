# ACME Production Server Provisioning

## 1. Overview

This project contains the Bash script for Stage 1 of ACME production server provisioning.

The script configures Ubuntu, package updates, unattended security updates, kernel parameters, an application account, open-file limits, and the message of the day.

## 2. Repository Contents

- `provision.sh` - base OS provisioning script.
- `README.md` - usage and verification instructions.
- `break-fix-log.md` - troubleshooting records and evidence.

## 3. Prerequisites

- Ubuntu 24.04 LTS.
- Root or sudo privileges.
- Network access to package repositories.
- Sufficient disk space.
- An approved maintenance window and recovery access.

## 4. Configuration

- Hostname: `acme-prod-01`
- Timezone: `Asia/Kolkata`
- Application account: `acme`
- Owner: `InfraCloudEdge`

## 5. Validate the Script

Check syntax without executing the script:

    bash -n provision.sh

Review the script:

    less provision.sh

## 6. Execution

Run only on an approved test server or during an authorized maintenance window:

    sudo ./provision.sh

The script upgrades packages and changes system configuration. Review its effects before execution.

## 7. Verification

Check hostname and timezone:

    hostnamectl
    timedatectl

Check kernel parameters:

    sysctl fs.file-max net.core.somaxconn

Check the application account and limits:

    id acme
    cat /etc/security/limits.d/90-acme-app.conf

Check update timers:

    systemctl is-enabled apt-daily.timer apt-daily-upgrade.timer
    systemctl is-active apt-daily.timer apt-daily-upgrade.timer

Check Nginx:

    systemctl is-active nginx

## 8. Operational Safety

- Full package upgrades can remove packages or change system components.
- Back up important configuration before making changes.
- Confirm recovery access before modifying production systems.
- Check whether a reboot is required after upgrades.
- Systemd services need their own LimitNOFILE setting where applicable.
- The APT timer enablement command appears twice in the script and should be reviewed.

## 9. Scope and Limitations

This script implements Stage 1 base OS configuration only. It does not itself deploy the ACME application or configure its application service, LVM mounts, backup jobs, or health checks.

## 10. Troubleshooting

See `break-fix-log.md` for symptoms, diagnostic evidence, root causes, fixes, and verification results.

Never record a fix as successful until the relevant verification has actually passed.
