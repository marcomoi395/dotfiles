#!/usr/bin/env bash
# Ubuntu 26.04 / cấu hình LazyVim hiện tại. Chạy bằng tài khoản dùng Neovim.
# --check: chỉ kiểm tra; không cài gói, không sửa cấu hình.
set -Eeuo pipefail
trap 'printf "Lỗi tại dòng %s. Sửa lỗi rồi chạy lại script.\n" "$LINENO" >&2' ERR
mode=${1:-install}
case "$mode" in install|--check) ;; *) echo "Dùng: bash $0 [--check]" >&2; exit 2 ;; esac
command -v nvim >/dev/null || { echo 'Chưa có nvim trong PATH.' >&2; exit 1; }
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/${NVIM_APPNAME:-nvim}"
[[ -f "$config_dir/lua/config/lazy.lua" ]] || { echo "Không tìm thấy $config_dir/lua/config/lazy.lua" >&2; exit 1; }
export PATH="$HOME/.local/bin:$data_dir/mason/bin:$PATH"
export NVIM_DEPS_MODE="$mode"
tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

if [[ "$mode" == install ]]; then
    [[ $EUID -ne 0 ]] || { echo 'Chạy bằng tài khoản dùng nvim; script tự gọi sudo cho apt.' >&2; exit 1; }
    command -v apt-get >/dev/null || { echo 'Script này cần Ubuntu/Debian với apt-get.' >&2; exit 1; }
    backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nvim-deps-backups/$(date +%Y%m%d-%H%M%S)-$$"
    mkdir -p "$backup_dir" "$HOME/.local/bin"
    cp -a "$config_dir" "$backup_dir/config"
    printf 'Bản sao cấu hình: %s\n' "$backup_dir/config"
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
        ca-certificates git curl unzip tar gzip xz-utils build-essential \
        nodejs npm golang-go openjdk-21-jdk python3-venv python3-pip \
        ripgrep fd-find xclip wl-clipboard sqlite3 postgresql-client default-mysql-client
    node -e 'if (Number(process.versions.node.split(".")[0]) < 22) process.exit(1)'
    command -v fd >/dev/null || ln -s /usr/bin/fdfind "$HOME/.local/bin/fd"

    runtime_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim-runtimes"
    mkdir -p "$runtime_dir"
    # Dart SDK chính thức; xác minh checksum trước khi giải nén.
    if ! command -v dart >/dev/null; then
        case "$(uname -m)" in x86_64) dart_arch=x64 ;; aarch64|arm64) dart_arch=arm64 ;; *) echo 'Kiến trúc Dart chưa hỗ trợ.' >&2; exit 1 ;; esac
        curl -fL --retry 3 -o "$tmp_dir/dart-version.json" https://storage.googleapis.com/dart-archive/channels/stable/release/latest/VERSION
        dart_version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$tmp_dir/dart-version.json")
        [[ "$dart_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
        dart_url="https://storage.googleapis.com/dart-archive/channels/stable/release/$dart_version/sdk/dartsdk-linux-$dart_arch-release.zip"
        curl -fL --retry 3 -o "$tmp_dir/dart.zip" "$dart_url"
        curl -fL --retry 3 -o "$tmp_dir/dart.sha256" "$dart_url.sha256sum"
        dart_hash=$(awk 'NR==1 {print $1}' "$tmp_dir/dart.sha256")
        [[ "$dart_hash" =~ ^[a-fA-F0-9]{64}$ ]] || exit 1
        printf '%s  %s\n' "$dart_hash" "$tmp_dir/dart.zip" | sha256sum -c -
        unzip -q "$tmp_dir/dart.zip" -d "$tmp_dir/dart"
        # Không ghi đè SDK đã tồn tại nhưng chưa được đưa vào PATH.
        if [[ ! -e "$runtime_dir/dart-sdk" ]]; then
            mv "$tmp_dir/dart/dart-sdk" "$runtime_dir/dart-sdk"
        fi
        ln -s "$runtime_dir/dart-sdk/bin/dart" "$HOME/.local/bin/dart"
    fi
    # Gói npm chính thức của Deno; phục vụ RunCode cho TypeScript.
    if ! command -v deno >/dev/null; then
        npm install --prefix "$runtime_dir/deno" --no-audit --no-fund deno@2
        ln -s "$runtime_dir/deno/node_modules/.bin/deno" "$HOME/.local/bin/deno"
    fi
fi

cat > "$tmp_dir/deps.lua" <<'LUA'
local function run()
  local check = vim.env.NVIM_DEPS_MODE == '--check'
  vim.opt.rtp:prepend(vim.fn.stdpath('config'))
  vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')
  assert(vim.fn.has('nvim-0.11.2') == 1, 'LazyVim cần Neovim >= 0.11.2')
  local lazy = require('lazy')
  local setup = lazy.setup
  lazy.setup = function(opts)
    opts.install.missing = false
    opts.checker.enabled = false
    opts.change_detection = { enabled = false }
    -- Chặn tác vụ nền: script tự cài và đợi hoàn tất từng nhóm.
    for _, name in ipairs({'mason.nvim', 'mason-lspconfig.nvim', 'nvim-lspconfig', 'nvim-treesitter'}) do
      table.insert(opts.spec, {name, config = function() end})
    end
    -- Parser được cài riêng bên dưới; tránh build trước khi sửa commit tương thích.
    table.insert(opts.spec, {'nvim-treesitter', build = false})
    return setup(opts)
  end
  require('config.lazy')
  local config = require('lazy.core.config')
  local function verify_plugins()
    for name, plugin in pairs(config.plugins) do
      assert(vim.uv.fs_stat(plugin.dir), 'Thiếu plugin: ' .. name)
      for _, task in ipairs(plugin._.tasks or {}) do
        assert(not task:has_errors(), 'Cài/build plugin lỗi: ' .. name)
      end
    end
  end
  if not check then
    local manager = require('lazy.manage')
    manager.install({wait = true, lockfile = true})
    verify_plugins()
    -- Lockfile cũ có thể ghim Treesitter cho Neovim 0.12 trên máy dùng 0.11.
    -- Dùng commit tương thích do LazyVim chỉ định; restore sẽ lưu lại lockfile.
    local plugin = config.plugins['nvim-treesitter']
    local entry = require('lazy.manage.lock').get(plugin)
    if vim.fn.has('nvim-0.12') == 0 and plugin.commit and entry and entry.commit ~= plugin.commit then
      print('Sửa Treesitter cho Neovim 0.11: ' .. plugin.commit)
      entry.commit = plugin.commit
    end
    manager.restore({wait = true})
  end
  verify_plugins()
  lazy.load({plugins = {'mason.nvim', 'mason-lspconfig.nvim'}})
  require('mason').setup({})
  local registry = require('mason-registry')
  if not check then
    local refreshed, refresh_ok = false, false
    registry.refresh(function(ok) refresh_ok = ok; refreshed = true end)
    assert(vim.wait(300000, function() return refreshed end, 100), 'Mason registry timeout')
    assert(refresh_ok, 'Không cập nhật được Mason registry')
  end
  local wanted = {['tree-sitter-cli'] = true}
  for _, name in ipairs(LazyVim.opts('mason.nvim').ensure_installed or {}) do wanted[name] = true end
  local map = require('mason-lspconfig.mappings').get_mason_map().lspconfig_to_package
  for name, opts in pairs(LazyVim.opts('nvim-lspconfig').servers) do
    if name ~= '*' and opts ~= false and (type(opts) ~= 'table' or (opts.enabled ~= false and opts.mason ~= false)) and map[name] then
      wanted[map[name]] = true
    end
  end
  local packages, missing = {}, {}
  for _, name in ipairs(vim.fn.sort(vim.tbl_keys(wanted))) do
    local pkg = registry.get_package(name)
    packages[#packages + 1] = pkg
    if not pkg:is_installed() then
      missing[#missing + 1] = name
      if not check and not pkg:is_installing() then pkg:install() end
    end
  end
  print('Mason thiếu: ' .. (#missing == 0 and '(không)' or table.concat(missing, ', ')))
  if not check then
    assert(vim.wait(1800000, function()
      for _, pkg in ipairs(packages) do if pkg:is_installing() then return false end end
      return true
    end, 500), 'Mason cài đặt quá 30 phút')
    for _, pkg in ipairs(packages) do assert(pkg:is_installed(), 'Mason cài thất bại: ' .. pkg.name) end
  end
  lazy.load({plugins = {'nvim-treesitter'}})
  local ts = require('nvim-treesitter')
  local opts = LazyVim.opts('nvim-treesitter')
  ts.setup(opts)
  local installed = ts.get_installed('parsers')
  local parsers = vim.tbl_filter(function(lang) return not vim.tbl_contains(installed, lang) end, opts.ensure_installed)
  print('Parser thiếu: ' .. (#parsers == 0 and '(không)' or table.concat(parsers, ', ')))
  if not check and #parsers > 0 then
    ts.install(parsers, {summary = true}):wait(1800000)
    installed = ts.get_installed('parsers')
    for _, lang in ipairs(parsers) do assert(vim.tbl_contains(installed, lang), 'Parser cài thất bại: ' .. lang) end
  end
  if not check then
    local preview = config.plugins['markdown-preview.nvim']
    if preview and vim.fn.executable(preview.dir .. '/app/bin/markdown-preview-linux') == 0 then
      require('lazy.manage').build({plugins = {'markdown-preview.nvim'}, wait = true})
      verify_plugins()
      assert(vim.fn.executable(preview.dir .. '/app/bin/markdown-preview-linux') == 1, 'Markdown preview build thất bại')
    end
  end
  print('Kiểm tra plugin hoàn tất.')
  return not check or (#missing == 0 and #parsers == 0)
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
elseif err == false then
  vim.cmd('cquit 1')
else
  vim.cmd('qa!')
end
LUA
export NVIM_DEPS_LUA="$tmp_dir/deps.lua"
audit_status=0
nvim --headless -u NONE '+set loadplugins' '+lua dofile(vim.env.NVIM_DEPS_LUA)' || audit_status=$?
missing_runtime=0
for tool in node npm go java javac python3 cc g++ make rg fd dart deno curl unzip tar tree-sitter sqlite3 psql mysql; do
    if command -v "$tool" >/dev/null; then
        printf 'OK %s\n' "$tool"
    else
        printf 'THIẾU %s\n' "$tool"
        missing_runtime=1
    fi
done
if [[ "$audit_status" != 0 ]]; then exit "$audit_status"; fi
[[ "$mode" == --check ]] && exit "$missing_runtime"
[[ "$missing_runtime" == 0 ]] || exit 1
printf '\nĐã cài plugin, Mason, parser theo cấu hình. Mở lại terminal rồi chạy nvim.\n'
printf 'Nếu terminal không có ~/.local/bin trong PATH: export PATH="$HOME/.local/bin:$PATH"\n'
printf 'Copilot vẫn tắt theo cấu hình. CopilotChat cần đăng nhập GitHub.\n'
printf 'Jest/pytest, Flutter, kết nối DB cần thiết lập trong dự án tương ứng.\n'
