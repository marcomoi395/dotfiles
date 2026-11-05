#!/usr/bin/env bash
# Kiểm tra và tự sửa phím tăng/giảm âm lượng Niri cho PipeWire.
set -Eeuo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/niri"
bind_file="$config_dir/dms/binds.kdl"
[[ -f "$bind_file" && -f "$config_dir/config.kdl" ]] || {
    echo "Không tìm thấy cấu hình Niri trong $config_dir" >&2
    exit 1
}
command -v python3 >/dev/null || { echo 'Cần python3.' >&2; exit 1; }

sink_status=''
if command -v wpctl >/dev/null; then
    sink_status=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>&1) || sink_status='Không tìm thấy sink PipeWire mặc định.'
else
    sink_status='Chưa cài wpctl.'
fi

result=$(python3 - "$config_dir/config.kdl" "$bind_file" <<'PY'
import os
import re
import shutil
import sys
import tempfile
from datetime import datetime
from pathlib import Path

config, bind_file = map(Path, sys.argv[1:])
if not re.search(r'^\s*include(?:\s+optional=true)?\s+"dms/binds\.kdl"\s*$', config.read_text(), re.M):
    raise SystemExit(f'Niri không include {bind_file}')

lines = bind_file.read_text().splitlines(keepends=True)
expected = {
    'XF86AudioLowerVolume': 'spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "3%-"',
    'XF86AudioRaiseVolume': 'spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "3%+"',
}
changed = False
for key, command in expected.items():
    matches = [i for i, line in enumerate(lines) if re.match(rf'^\s*{key}(?:\s|$)', line)]
    if len(matches) != 1:
        raise SystemExit(f'Cần đúng một bind {key}; tìm thấy {len(matches)}.')
    i = matches[0]
    match = re.search(r'\{\s*(spawn\b.*?);\s*\}', lines[i])
    if not match:
        raise SystemExit(f'Không đọc được lệnh trong bind {key}; không sửa file.')
    if match.group(1) != command:
        lines[i] = lines[i][:match.start(1)] + command + lines[i][match.end(1):]
        changed = True

if not changed:
    print('OK: phím tăng/giảm đã điều khiển PipeWire.')
else:
    backup = bind_file.with_name(bind_file.name + '.bak.' + datetime.now().strftime('%Y%m%d-%H%M%S'))
    if backup.exists():
        backup = bind_file.with_name(backup.name + f'.{os.getpid()}')
    shutil.copy2(bind_file, backup)
    fd, temp_name = tempfile.mkstemp(dir=bind_file.parent, prefix=bind_file.name + '.')
    try:
        with os.fdopen(fd, 'w') as temp:
            temp.writelines(lines)
        os.chmod(temp_name, bind_file.stat().st_mode)
        os.replace(temp_name, bind_file)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)
    print(f'FIXED: đã chuyển phím tăng/giảm sang wpctl. Bản sao: {backup}')
PY
)
printf '%s\n' "$result"

if [[ "$result" == FIXED:* ]]; then
    if command -v niri >/dev/null && niri msg action load-config-file; then
        echo 'Đã nạp lại cấu hình Niri.'
    else
        echo 'Chưa nạp được Niri; chạy script trong phiên Niri để áp dụng.' >&2
        exit 1
    fi
fi
printf 'PipeWire: %s\n' "$sink_status"
