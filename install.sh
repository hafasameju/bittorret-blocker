#!/bin/bash

# بررسی دسترسی روت
if [ "$EUID" -ne 0 ]; then
  echo "این اسکریپت باید با sudo یا root اجرا شود."
  exit 1
fi

echo "[+] نصب در حال شروع است..."

# ایجاد اسکریپت مسدودسازی BitTorrent
cat << 'EOF' > /usr/local/bin/block-bittorrent.sh
#!/bin/bash
bittorrent_signatures=(
  "BitTorrent" "BitTorrent protocol" "peer_id=" ".torrent"
  "announce" "info_hash" "tracker"
  "get_peers" "find_node"
  "BitComet" "BitLord" "Azureus" "Transmission" "uTorrent"
)

for sig in "${bittorrent_signatures[@]}"; do
  iptables -C FORWARD -m string --algo bm --string "$sig" -j DROP 2>/dev/null     || iptables -A FORWARD -m string --algo bm --string "$sig" -j DROP
  iptables -C OUTPUT  -m string --algo bm --string "$sig" -j DROP 2>/dev/null     || iptables -A OUTPUT  -m string --algo bm --string "$sig" -j DROP
done

if command -v netfilter-persistent >/dev/null; then
  netfilter-persistent save
elif command -v iptables-save >/dev/null; then
  iptables-save > /etc/iptables/rules.v4
fi

echo "[✔] قوانین مسدودسازی BitTorrent اعمال شدند."
EOF

chmod +x /usr/local/bin/block-bittorrent.sh

# ایجاد و نصب سرویس systemd
cat << 'EOF' > /etc/systemd/system/block-bittorrent.service
[Unit]
Description=Block BitTorrent Traffic via iptables
After=network.target

[Service]
ExecStart=/usr/local/bin/block-bittorrent.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable block-bittorrent.service
systemctl start block-bittorrent.service

echo "[✔] سرویس فعال شد و در هر بوت اجرا خواهد شد."
