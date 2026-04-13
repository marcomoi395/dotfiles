# function fish_prompt -d "Write out the prompt"
#     # This shows up as USER@HOST /home/user/ >, with the directory colored
#     # $USER and $hostname are set by fish, so you can just use them
#     # instead of using `whoami` and `hostname`
#     printf '%s@%s %s%s%s > ' $USER $hostname \
#         (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
# end
#
if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # # Use starship
    starship init fish | source
    # if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    #     cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    # end

    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c ii'
    alias oc opencode
    alias n touch
    alias code 'cd /run/media/ym/DATA/Code/'
    alias ws 'cd /run/media/ym/DATA/workspaces/'
    alias conf 'cd ~/.config'
    alias v 'nvim .'
    alias c clear
    alias ns 'npm start'
    alias nd 'npm run start:dev'
    alias yd 'yarn run dev'
    alias ys 'yarn start'
    alias n18 'nvm use 18'
    alias dc 'docker compose'
    alias gst 'git status'
    alias desktop 'cd /run/media/ym/8016C89B16C89416/Users/youngmarco/Desktop/'
    alias pt="QT_QPA_PLATFORM=xcb /usr/lib/packettracer/packettracer.AppImage --no-sandbox"
    # alias gh copilot
    alias lg lazygit
end

set -gx nvm_default_version 18

function pm
    if test -z "$argv[1]"
        echo "Ní ơi, thiếu ID Collection rồi!"
        return 1
    end

    # Cấu hình các biến cố định
    set -l collection_id $argv[1]
    set -l env_id 36342424-d2321386-e744-4232-8b52-804146a12857
    set -l report_dir "./pm-report" # Thư mục lưu trữ
    set -l timestamp (date +%Y%m%d_%H%M%S)
    set -l report_name "report_$timestamp.html"
    set -l report_path "$report_dir/$report_name"

    # Tạo folder nếu chưa có (-p để không báo lỗi nếu đã tồn tại)
    mkdir -p $report_dir

    # Chạy Postman CLI và giấu hết log (loại bỏ cli reporter cho sạch)
    postman collection run $collection_id \
        -e $env_id \
        --env-var "base_url=http://localhost:5001" \
        --reporters html \
        --reporter-html-export $report_path

    sleep 1

    if test -f $report_path
        nohup google-chrome-stable $report_path >/dev/null 2>&1 &
        disown
    else
        echo "❌ Đù, không thấy file $report_path đâu hết ní ơi!"
    end
end
