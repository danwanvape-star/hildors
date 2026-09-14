#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl xz-utils ffmpeg openssl

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
curl -fsSLo "$work_dir/SHASUMS256.txt" https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt
node_archive="$(awk '/linux-x64\.tar\.xz$/ {print $2}' "$work_dir/SHASUMS256.txt")"
test -n "$node_archive"
curl -fsSLo "$work_dir/$node_archive" "https://nodejs.org/dist/latest-v24.x/$node_archive"
(cd "$work_dir" && grep "  $node_archive$" SHASUMS256.txt | sha256sum -c -)
rm -rf /opt/node-v24
mkdir -p /opt/node-v24
tar -xJf "$work_dir/$node_archive" -C /opt/node-v24 --strip-components=1
ln -sfn /opt/node-v24/bin/node /usr/local/bin/node
ln -sfn /opt/node-v24/bin/npm /usr/local/bin/npm

if ! id -u hildors >/dev/null 2>&1; then
  useradd --system --home-dir /var/lib/hildors-api --shell /usr/sbin/nologin hildors
fi
install -d -o root -g root -m 0755 /opt/hildors/backend
rm -rf /opt/hildors/backend/src /opt/hildors/backend/public
tar -xzf /tmp/hildors-backend-deploy.tgz -C /opt/hildors/backend
chown -R root:root /opt/hildors/backend
chmod -R go-w /opt/hildors/backend

install -d -o root -g hildors -m 0750 /etc/hildors
install -o root -g hildors -m 0640 /tmp/team-staging.env.example /etc/hildors/team-staging.env
if [[ ! -s /etc/hildors/admin-token ]]; then
  openssl rand -base64 32 > /etc/hildors/admin-token
fi
chown root:hildors /etc/hildors/admin-token
chmod 0640 /etc/hildors/admin-token

install -o root -g root -m 0644 /tmp/hildors-team-staging.service /etc/systemd/system/hildors-team-staging.service
systemd-analyze verify /etc/systemd/system/hildors-team-staging.service
systemctl daemon-reload
systemctl enable --now hildors-team-staging.service
systemctl restart hildors-team-staging.service

node --version
ffmpeg -version | head -n 1
curl -fsS http://127.0.0.1:8787/health
printf '\n'
curl -fsS http://127.0.0.1:8787/ready
printf '\n'
