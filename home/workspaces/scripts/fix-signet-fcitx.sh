#!/usr/bin/env bash
# =============================================================================
#  fix-signet-fcitx.sh
#  Sửa lỗi KHÔNG GÕ ĐƯỢC TIẾNG VIỆT (fcitx5 + Unikey) trong app Signet
#  ----------------------------------------------------------------------------
#  NGUYÊN NHÂN: hãng Signet đóng gói SAI plugin input method
#    - App bundle Qt 6.8.x nhưng plugin fcitx5 đi kèm được build bằng Qt 6.9
#      (thiếu version node `Qt_6.9`) + GCC 13+ (cần CXXABI_1.3.15)
#    - libstdc++.so.6 bundle quá cũ (chỉ tới CXXABI_1.3.9)
#    - Plugin thiếu 2 thư viện: libFcitx5Qt6DBusAddons, libQt6WaylandClient
#    => Qt không nạp được plugin -> fallback input context mặc định -> không gõ được TV
#
#  CÁCH FIX: thay plugin bằng bản fcitx5-qt build đúng cho Qt 6.8.x (từ kho
#  Ubuntu 25.04), bổ sung thư viện thiếu, thay libstdc++ cũ, gán RUNPATH cho
#  plugin trỏ vào thư mục lib của app. Tất cả file cũ được backup.
#
#  CÁCH DÙNG:
#    ./fix-signet-fcitx.sh                     # app ở ~/Signet
#    ./fix-signet-fcitx.sh /đường/dẫn/Signet   # app ở chỗ khác
#
#  TƯƠNG THÍCH: mọi bản Ubuntu/Debian (đã kiểm chứng 24.04 → 26.04+):
#    - Nếu Qt hệ thống cùng phiên bản với Qt của app -> dùng plugin fcitx5 hệ thống.
#    - App Qt 6.8.x trên hệ thống Qt khác -> tự tải plugin fcitx5-qt 6.8 từ kho
#      Ubuntu 25.04 (có fallback old-releases.ubuntu.com sau khi 25.04 EOL).
#    - Yêu cầu hệ thống có GCC 13+/CXXABI_1.3.15 (Ubuntu 24.04 trở lên).
#
#  YÊU CẦU: curl hoặc wget, dpkg-deb, patchelf, binutils (objdump/readelf)
#  KIỂM TRA: sau khi chạy, mở lại Signet, bật Unikey (Ctrl+Space) và gõ thử.
#  LƯU Ý:  nếu app Signet tự cập nhật (App Update), hãy chạy lại script này.
# =============================================================================
set -euo pipefail

SIGNET_DIR="${1:-${SIGNET_DIR:-$HOME/Signet}}"
MIRROR="${UBUNTU_MIRROR:-http://archive.ubuntu.com/ubuntu}"
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/signet-fcitx-fix"
BACKUP_DIR="$WORK/backup-$(date +%Y%m%d-%H%M%S)"

# --- Phiên bản các gói Ubuntu 25.04 (plucky) đã kiểm chứng hoạt động ---------
PLUCKY_FCITX_FRONTEND="fcitx5-frontend-qt6_5.1.9-1build2_amd64.deb"
PLUCKY_FCITX_LIB="libfcitx5-qt6-1_5.1.9-1build2_amd64.deb"
PLUCKY_WAYLAND="libqt6waylandclient6_6.8.3-0ubuntu1_amd64.deb"

log() { printf '\033[1;36m[fix]\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
die() {
    printf '\033[1;31m[LỖI]\033[0m %s\n' "$*" >&2
    exit 1
}

need() { command -v "$1" >/dev/null 2>&1 || die "Thiếu lệnh '$1'. Cài: sudo apt install $2"; }

# =============================================================================
echo
log "=== Sửa gõ tiếng Việt (fcitx5) cho Signet tại: $SIGNET_DIR ==="

# --- Kiểm tra bundle app ------------------------------------------------------
[ -x "$SIGNET_DIR/Signet" ] || die "Không thấy '$SIGNET_DIR/Signet'. Truyền đúng đường dẫn: $0 /đường/dẫn/Signet"
[ -d "$SIGNET_DIR/lib" ] || die "Thiếu thư mục '$SIGNET_DIR/lib' — đây không phải bundle Signet chuẩn."
[ -d "$SIGNET_DIR/plugins/platforminputcontexts" ] || die "Thiếu plugins/platforminputcontexts."

need curl "curl"
need dpkg-deb "dpkg"
need patchelf "patchelf"
need objdump "binutils"
need readelf "binutils"
need strings "binutils"

APP_QT=$(strings "$SIGNET_DIR/lib/libQt6Core.so.6" 2>/dev/null | grep -E '^6\.[0-9]+\.[0-9]+$' | head -1) || true
APP_QT=${APP_QT:-?}
log "Qt của app Signet: $APP_QT"

SYS_QT=$(strings /usr/lib/x86_64-linux-gnu/libQt6Core.so.6 2>/dev/null | grep -E '^6\.[0-9]+\.[0-9]+$' | head -1) || true
SYS_QT=${SYS_QT:-?}
log "Qt hệ thống: $SYS_QT"
APP_QT_MINOR=$(echo "$APP_QT" | cut -d. -f1-2)
SYS_QT_MINOR=$(echo "$SYS_QT" | cut -d. -f2 2>/dev/null || echo "?")

# --- fcitx5 + biến môi trường -------------------------------------------------
pgrep -x fcitx5 >/dev/null 2>&1 || warn "fcitx5 chưa chạy. Hãy chạy: fcitx5 -d (hoặc mở lại session)"
[ "${QT_IM_MODULE:-}" = "fcitx" ] || warn "QT_IM_MODULE chưa là fcitx trong shell này."
[ "${GTK_IM_MODULE:-}" = "fcitx" ] || warn "GTK_IM_MODULE chưa là fcitx (chỉ cần cho app GTK)."
[ "${XMODIFIERS:-}" = "@im=fcitx" ] || warn "XMODIFIERS chưa set @im=fcitx (chỉ cần cho app X11 cũ)."
warn "Lưu ý: nếu mở Signet từ terminal, hãy dùng: env QT_IM_MODULE=fcitx GTK_IM_MODULE=fcitx XMODIFIERS=@im=fcitx $SIGNET_DIR/Signet"

# --- Nếu app đang chạy, nhắc khởi động lại sau khi fix -------------------------
if pgrep -f "/Signet/Signet" >/dev/null 2>&1; then
    warn "Signet đang chạy — hãy ĐÓNG app trước khi fix, rồi chạy lại script."
fi

PLUGIN="$SIGNET_DIR/plugins/platforminputcontexts/libfcitx5platforminputcontextplugin.so"

# =============================================================================
# Bước 0: Kiểm tra plugin hiện tại có thực sự hỏng không (idempotent)
# =============================================================================
# Kiểm tra 1 thư viện cụ thể của plugin có resolve về thư mục lib của app không
# (ldd hiển thị đường dẫn chứa ../.. chưa normalize nên phải dùng realpath)
lib_resolves_to_bundle() { # $1 = soname (vd: libQt6Core.so.6)
    local line resolved
    read -r line < <(ldd "$PLUGIN" 2>/dev/null | sed -n "s|.*$1 => \([^ ]*\).*|\1|p" | grep .)
    [ -z "$line" ] && return 1
    resolved=$(realpath "$line" 2>/dev/null) || return 1
    [ "$resolved" = "$(realpath "$SIGNET_DIR/lib/$1" 2>/dev/null)" ]
}

plugin_ok() {
    [ -f "$PLUGIN" ] || return 1
    lib_resolves_to_bundle libQt6Core.so.6 || return 1
    lib_resolves_to_bundle libFcitx5Qt6DBusAddons.so.1 || return 1
    # và có RUNPATH tới lib app
    readelf -d "$PLUGIN" 2>/dev/null | grep '$ORIGIN/../../lib' >/dev/null || return 1
    # version node plugin phải <= app Qt minor (bài học từ bug: 6.9 plugin vs 6.8 app)
    local need_minor
    need_minor=$(objdump -T "$PLUGIN" 2>/dev/null | grep "UND.*qt_version_tag" | grep -oE 'Qt_6\.[0-9]+' | sed -n '1p' | cut -d. -f2) || true
    [ -n "$need_minor" ] && [ "$need_minor" -le "${APP_QT_MINOR##*.}" ] || return 1
    return 0
}

if plugin_ok; then
    ok "Plugin fcitx5 của Signet đã hoạt động đúng — không cần sửa gì."
    exit 0
fi

# =============================================================================
# Bước 1: Chọn nguồn plugin phù hợp với Qt của app
# =============================================================================
mkdir -p "$WORK"
APP_MINOR_NUM=$(echo "$APP_QT_MINOR" | cut -d. -f2 2>/dev/null || echo "?")

# Nếu Qt hệ thống cùng minor với Qt của app (6.8↔6.8, 6.9↔6.9, 6.10↔6.10, ...)
# thì dùng plugin fcitx5 của chính hệ thống — tương thích chắc chắn 100%.
# (Ví dụ: Ubuntu 26.04 LTS dùng Qt 6.10 — nếu app bundle cũng là Qt 6.10 thì nhánh này chạy)
if [ "$SYS_QT_MINOR" = "$APP_MINOR_NUM" ]; then
    log "Qt hệ thống ($SYS_QT) cùng phiên bản với app ($APP_QT) — dùng plugin fcitx5 hệ thống."
    PLUGIN_SRC="/usr/lib/x86_64-linux-gnu/qt6/plugins/platforminputcontexts/libfcitx5platforminputcontextplugin.so"
    DBUS_SRC="/usr/lib/x86_64-linux-gnu/libFcitx5Qt6DBusAddons.so.1"
    WAYLAND_SRC="/usr/lib/x86_64-linux-gnu/libQt6WaylandClient.so.6"
    [ -f "$PLUGIN_SRC" ] || die "Không thấy plugin hệ thống $PLUGIN_SRC. Cài: sudo apt install fcitx5-frontend-qt6"
    [ -f "$DBUS_SRC" ] || die "Không thấy $DBUS_SRC — cài: sudo apt install libfcitx5-qt6-1"
    [ -f "$WAYLAND_SRC" ] || die "Không thấy $WAYLAND_SRC — cài: sudo apt install libqt6waylandclient6"
elif [ "$APP_MINOR_NUM" = "8" ]; then
    log "Qt hệ thống ($SYS_QT) khác Qt của app ($APP_QT) — tải plugin fcitx5-qt build cho Qt 6.8 từ kho Ubuntu 25.04 (plucky)."
    # Hàm tải có fallback: sau khi Ubuntu 25.04 EOL, pool được chuyển sang old-releases.ubuntu.com
    fetch_deb() { # $1 = tên file, $2 = đường dẫn pool (dạng pool/universe/...)
        local out="$WORK/$1" base url
        for base in "$MIRROR" "http://old-releases.ubuntu.com/ubuntu"; do
            url="$base/$2"
            log "Tải $1 (từ $url) ..."
            if curl -fsSL --max-time 120 -o "$out" "$url" 2>/dev/null; then
                return 0
            fi
            warn "Nguồn $url không có — thử nguồn khác..."
        done
        return 1
    }
    [ -f "$WORK/$PLUCKY_FCITX_FRONTEND" ] ||
        fetch_deb "$PLUCKY_FCITX_FRONTEND" "pool/universe/f/fcitx5-qt/$PLUCKY_FCITX_FRONTEND" ||
        die "Tải thất bại $PLUCKY_FCITX_FRONTEND (kiểm tra mạng hoặc set UBUNTU_MIRROR=...)"
    [ -f "$WORK/$PLUCKY_FCITX_LIB" ] ||
        fetch_deb "$PLUCKY_FCITX_LIB" "pool/universe/f/fcitx5-qt/$PLUCKY_FCITX_LIB" ||
        die "Tải thất bại $PLUCKY_FCITX_LIB (kiểm tra mạng hoặc set UBUNTU_MIRROR=...)"
    # libqt6waylandclient6 nằm ở pool qt6-wayland, KHÔNG phải fcitx5-qt
    [ -f "$WORK/$PLUCKY_WAYLAND" ] ||
        fetch_deb "$PLUCKY_WAYLAND" "pool/universe/q/qt6-wayland/$PLUCKY_WAYLAND" ||
        die "Tải thất bại $PLUCKY_WAYLAND (kiểm tra mạng hoặc set UBUNTU_MIRROR=...)"
    rm -rf "$WORK/x1" "$WORK/x2" "$WORK/x3"
    dpkg-deb -x "$WORK/$PLUCKY_FCITX_FRONTEND" "$WORK/x1"
    dpkg-deb -x "$WORK/$PLUCKY_FCITX_LIB" "$WORK/x2"
    dpkg-deb -x "$WORK/$PLUCKY_WAYLAND" "$WORK/x3"
    PLUGIN_SRC="$WORK/x1/usr/lib/x86_64-linux-gnu/qt6/plugins/platforminputcontexts/libfcitx5platforminputcontextplugin.so"
    DBUS_SRC="$WORK/x2/usr/lib/x86_64-linux-gnu/libFcitx5Qt6DBusAddons.so.1"
    WAYLAND_SRC="$WORK/x3/usr/lib/x86_64-linux-gnu/libQt6WaylandClient.so.6"
else
    die "Qt của app là $APP_QT nhưng Qt hệ thống là $SYS_QT (khác minor) — không có nguồn plugin fcitx5 tương thích. Hãy báo nhà phát hành Signet sửa bundle (plugin fcitx5 của họ build sai Qt)."
fi

[ -f "$PLUGIN_SRC" ] || die "Không tìm thấy plugin nguồn: $PLUGIN_SRC"

# Kiểm tra chéo: version node plugin phải <= minor Qt của app
NEED_NODE=$(objdump -T "$PLUGIN_SRC" 2>/dev/null | grep "UND.*qt_version_tag" | grep -oE 'Qt_6\.[0-9]+' | sed -n '1p') || true
if [ -n "$NEED_NODE" ]; then
    NEED_MINOR=${NEED_NODE#Qt_6.}
    [ "$NEED_MINOR" -le "${APP_QT_MINOR##*.}" ] ||
        die "Plugin $NEED_NODE không tương thích app Qt $APP_QT — dừng để tránh làm hỏng."
    ok "Plugin nguồn dùng version node $NEED_NODE — tương thích app Qt $APP_QT."
fi

# =============================================================================
# Bước 2: libstdc++ — plugin mới build bằng GCC mới, bundle cũ không đủ CXXABI
# =============================================================================
PLUGIN_CXXABI=$(objdump -T "$PLUGIN_SRC" 2>/dev/null | grep UND | grep -oE 'CXXABI_1\.3\.[0-9]+' | sort -V | tail -1 || true)
BUNDLE_CXXABI=$(strings "$SIGNET_DIR/lib/libstdc++.so.6" 2>/dev/null | grep -E '^CXXABI_1\.3\.[0-9]+$' | sort -V | tail -1 || true)
log "Plugin cần CXXABI tối thiểu: ${PLUGIN_CXXABI:-không rõ} | libstdc++ bundle: ${BUNDLE_CXXABI:-không rõ}"

SYS_LIBSTDCXX=$(ls /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.* 2>/dev/null | sort -V | tail -1 || true)
if [ -z "$SYS_LIBSTDCXX" ]; then
    warn "Không tìm thấy libstdc++ hệ thống — nếu plugin báo lỗi CXXABI hãy tự cập nhật libstdc++ bundle."
elif [ -n "$PLUGIN_CXXABI" ] && [ -n "$BUNDLE_CXXABI" ] && [ "$PLUGIN_CXXABI" != "$BUNDLE_CXXABI" ]; then
    # So sánh phiên bản: plugin cần >= bundle thì mới phải thay
    if [ "$(printf '%s\n%s\n' "$PLUGIN_CXXABI" "$BUNDLE_CXXABI" | sort -V | tail -1)" = "$PLUGIN_CXXABI" ] &&
        [ "$PLUGIN_CXXABI" != "$BUNDLE_CXXABI" ]; then
        # Kiểm tra libstdc++ hệ thống có đủ CXXABI plugin cần không (distro quá cũ thì chịu)
        SYS_CXXABI_MAX=$(strings "$SYS_LIBSTDCXX" 2>/dev/null | grep -E '^CXXABI_1\.3\.[0-9]+$' | sort -V | tail -1)
        if [ -z "$SYS_CXXABI_MAX" ] ||
            [ "$(printf '%s\n%s\n' "$PLUGIN_CXXABI" "$SYS_CXXABI_MAX" | sort -V | tail -1)" != "$SYS_CXXABI_MAX" ]; then
            die "libstdc++ hệ thống ($SYS_CXXABI_MAX) không đủ CXXABI $PLUGIN_CXXABI mà plugin cần — cần hệ thống có GCC 13+ (Ubuntu 24.04 trở lên)."
        fi
        mkdir -p "$BACKUP_DIR"
        cp -a "$SIGNET_DIR/lib/libstdc++.so.6" "$BACKUP_DIR/libstdc++.so.6.bak"
        cp "$SYS_LIBSTDCXX" "$SIGNET_DIR/lib/libstdc++.so.6"
        ok "Đã thay libstdc++.so.6 bundle (cũ: $BUNDLE_CXXABI → mới: $PLUGIN_CXXABI). Backup tại $BACKUP_DIR"
    fi
else
    ok "libstdc++ bundle đã đủ ($BUNDLE_CXXABI) — giữ nguyên."
fi

# =============================================================================
# Bước 3: Copy plugin + thư viện thiếu vào bundle (có backup)
# =============================================================================
mkdir -p "$BACKUP_DIR"
copy_with_backup() { # $1=src $2=dst
    [ -f "$1" ] || die "Thiếu file nguồn: $1"
    if [ -e "$2" ]; then cp -a "$2" "$BACKUP_DIR/$(basename "$2").bak"; fi
    cp -a "$1" "$2"
    ok "Đã đặt $(basename "$2") vào bundle (backup tại $BACKUP_DIR)."
}

copy_with_backup "$PLUGIN_SRC" "$PLUGIN"
copy_with_backup "$DBUS_SRC" "$SIGNET_DIR/lib/libFcitx5Qt6DBusAddons.so.1"
# giữ cả file thật mà symlink trỏ tới (cp -a giữ symlink; cần file thật đi kèm)
for f in "${DBUS_SRC%.so.1}".so.*; do
    [ -f "$f" ] && [ "$(basename "$f")" != "libFcitx5Qt6DBusAddons.so.1" ] &&
        cp -a "$f" "$SIGNET_DIR/lib/" 2>/dev/null || true
done
copy_with_backup "$WAYLAND_SRC" "$SIGNET_DIR/lib/libQt6WaylandClient.so.6"
for f in "$WAYLAND_SRC"*; do
    [ -f "$f" ] && [ "$(basename "$f")" != "libQt6WaylandClient.so.6" ] &&
        cp -a "$f" "$SIGNET_DIR/lib/" 2>/dev/null || true
done

# =============================================================================
# Bước 4: Gán RUNPATH cho plugin -> deps resolve từ lib của app (bắt buộc!)
# =============================================================================
patchelf --set-rpath '$ORIGIN/../../lib' "$PLUGIN"
ok "Đã gán RUNPATH \$ORIGIN/../../lib cho plugin (deps sẽ lấy từ lib của app, không phải system)."

# =============================================================================
# Bước 5: Kiểm tra lại
# =============================================================================
echo
log "=== Kiểm tra lần cuối ==="
if lib_resolves_to_bundle libQt6Core.so.6; then
    ok "Plugin resolve libQt6Core về bundle app."
else
    die "Plugin KHÔNG resolve libQt6Core về bundle — kiểm tra lại RUNPATH."
fi
if lib_resolves_to_bundle libFcitx5Qt6DBusAddons.so.1; then
    ok "libFcitx5Qt6DBusAddons resolve từ bundle."
else
    warn "libFcitx5Qt6DBusAddons không resolve từ bundle (có thể vẫn chạy nếu version khớp)."
fi
if command -v python3 >/dev/null 2>&1; then
    if env -u LD_LIBRARY_PATH python3 - "$PLUGIN" <<'EOF' >/dev/null 2>&1
import ctypes, sys
ctypes.CDLL(sys.argv[1])
EOF
    then
        ok "Thử nạp plugin bằng dlopen: THÀNH CÔNG."
    else
        warn "dlopen plugin thất bại — xem lỗi bên dưới:"
        env -u LD_LIBRARY_PATH python3 - "$PLUGIN" <<'EOF' 2>&1 | tail -3
import ctypes, sys
try:
    ctypes.CDLL(sys.argv[1])
except Exception as e:
    print("dlopen error:", e); raise SystemExit(1)
EOF
    fi
fi

# =============================================================================
echo
ok "HOÀN TẤT! Backup nằm tại: $BACKUP_DIR"
echo "--------------------------------------------------------------------------"
echo "  Cách dùng:"
echo "    1. Đóng Signet (nếu đang chạy) rồi mở lại BÌNH THƯỜNG — không cần prefix."
echo "    2. Đảm bảo fcitx5 đang chạy (fcitx5 -d nếu chưa)."
echo "    3. Bật Unikey trong fcitx5 (thường Ctrl+Space hoặc Super+Space),"
echo "       kiểm tra bằng:  fcitx5-remote -n"
echo "    4. Vào Signet, gõ thử tiếng Việt."
echo "    5. Nếu app Signet cập nhật (App Update) làm mất fix, hãy chạy lại:"
echo "       $0 $SIGNET_DIR"
echo "--------------------------------------------------------------------------"
