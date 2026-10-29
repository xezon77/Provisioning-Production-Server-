#!/usr/bin/env bash
set -Eeuo pipefail

# Task 10: ACME production server provisioning
# Stage 1: safe base OS configuration
# Target: Ubuntu 24.04 LTS

HOSTNAME_TARGET="acme-prod-01"
TIMEZONE_TARGET="Asia/Kolkata"
OWNER="InfraCloudEdge"
SUPPORT_CONTACT="infracloudedge@gmail.com"

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

die() {
    log "ERROR: $*"
    exit 1
}

[[ $EUID -eq 0 ]] || die "Run with sudo: sudo ./provision.sh"

[[ -r /etc/os-release ]] || die "Cannot identify operating system"
source /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || die "Ubuntu is required"

log "Starting Task 10 base configuration"

# 1. Set hostname and timezone.
hostnamectl set-hostname "$HOSTNAME_TARGET"
timedatectl set-timezone "$TIMEZONE_TARGET"

# Enable network time synchronization through systemd.
timedatectl set-ntp true

# 2. Refresh package metadata and install security-update tooling.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get full-upgrade -y
apt-get install -y unattended-upgrades nginx \
    python3 python3-venv curl logrotate rsync \
    ufw fail2ban lvm2

# Enable unattended security updates.
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

systemctl enable --now apt-daily.timer apt-daily-upgrade.timer
if [[ -f /var/run/reboot-required ]]; then
    log "WARNING: A reboot is required after package upgrades."
fi
systemctl enable --now apt-daily.timer apt-daily-upgrade.timer

# 3. Apply persistent kernel parameters.
cat > /etc/sysctl.d/99-acme-prod.conf <<'EOF'
fs.file-max = 2097152
net.core.somaxconn = 1024
EOF

sysctl --system

# 4. Configure open-file limits for the application service account.
# The account is created now; the application service will use it later.
if ! id acme >/dev/null 2>&1; then
    useradd --system --user-group \
        --home-dir /nonexistent \
        --shell /usr/sbin/nologin acme
fi

cat > /etc/security/limits.d/90-acme-app.conf <<'EOF'
acme soft nofile 65536
acme hard nofile 65536
EOF

# systemd services do not automatically inherit PAM limits.
# The final acme-app.service will also specify LimitNOFILE=65536.

# 5. Configure a custom MOTD.
cat > /etc/motd <<EOF
====================================================
  ACME Production Server
  Host:    $HOSTNAME_TARGET
  Role:    Application server
  Owner:   $OWNER
  Support: $SUPPORT_CONTACT
====================================================
Authorized access only. Activity may be monitored.
EOF

# 6. Validate important outcomes.
[[ "$(hostname)" == "$HOSTNAME_TARGET" ]] ||
    die "Hostname verification failed"

[[ "$(timedatectl show -p Timezone --value)" == "$TIMEZONE_TARGET" ]] ||
    die "Timezone verification failed"

timedatectl show -p NTPSynchronized --value

sysctl fs.file-max net.core.somaxconn
systemctl is-enabled apt-daily.timer apt-daily-upgrade.timer
systemctl is-active nginx

log "Stage 1 completed."
log "Review NTP synchronization and reboot requirements before proceeding."
