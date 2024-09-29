#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# Python 脚本路径
PYTHON_SCRIPT="dns_update.py"

# 服务器备注文件
SERVER_REMARK_FILE="server_remark.txt"

# 函数：显示菜单
show_menu() {
    echo -e "${BLUE}┌─────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│     ${YELLOW}Cloudflare DNS 更新脚本菜单${BLUE}        │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│ ${GREEN}1.${NC} 设置 Cloudflare 配置                 ${BLUE}│${NC}"
    echo -e "${BLUE}│ ${GREEN}2.${NC} 设置钉钉机器人配置                   ${BLUE}│${NC}"
    echo -e "${BLUE}│ ${GREEN}3.${NC} 运行 DNS 更新脚本                    ${BLUE}│${NC}"
    echo -e "${BLUE}│ ${GREEN}4.${NC} 查看运行状态                         ${BLUE}│${NC}"
    echo -e "${BLUE}│ ${GREEN}5.${NC} 停止 DNS 更新脚本                    ${BLUE}│${NC}"
    echo -e "${BLUE}│ ${GREEN}6.${NC} 安装依赖                             ${BLUE}│${NC}"
    echo -e "${BLUE}│ ${GREEN}7.${NC} 切换 CDN 状态                        ${BLUE}│${NC}"
    echo -e "${BLUE}│ ${GREEN}8.${NC} 设置服务器备注                       ${BLUE}│${NC}"
    echo -e "${BLUE}│ ${GREEN}9.${NC} 退出                                 ${BLUE}│${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────┘${NC}"
}

# 函数：设置 Cloudflare 配置
setup_cloudflare() {
    echo -e "${GREEN}正在设置 Cloudflare 配置...${NC}"
    ./dns_update.sh
    echo -e "${GREEN}Cloudflare 配置已完成。${NC}"
}

# 函数：设置钉钉机器人配置
setup_dingtalk() {
    echo -e "${GREEN}正在设置钉钉机器人配置...${NC}"
    read -p "请输入钉钉机器人 Access Token: " access_token
    read -p "请输入钉钉机器人 Secret: " secret

    # 更新 Python 脚本中的钉钉配置
    sed -i "s/ACCESS_TOKEN = .*/ACCESS_TOKEN = \"$access_token\"/" $PYTHON_SCRIPT
    sed -i "s/SECRET = .*/SECRET = \"$secret\"/" $PYTHON_SCRIPT

    echo -e "${GREEN}钉钉机器人配置已更新到 $PYTHON_SCRIPT${NC}"
}

# 函数：运行 DNS 更新脚本
run_dns_update() {
    echo -e "${GREEN}正在启动 DNS 更新脚本...${NC}"
    nohup python3 $PYTHON_SCRIPT >> nohup.out 2>&1 &
    echo -e "${GREEN}DNS 更新脚本已在后台启动。${NC}"
}

# 函数：查看运行状态
check_status() {
    if pgrep -f "python3 $PYTHON_SCRIPT" > /dev/null
    then
        echo -e "${GREEN}DNS 更新脚本正在运行。${NC}"
    else
        echo -e "${RED}DNS 更新脚本未运行。${NC}"
    fi
}

# 函数：停止 DNS 更新脚本
stop_dns_update() {
    echo -e "${YELLOW}正在停止 DNS 更新脚本...${NC}"
    pkill -f $PYTHON_SCRIPT
    echo -e "${GREEN}DNS 更新脚本已停止。${NC}"
}

# 函数：安装依赖
install_dependencies() {
    echo -e "${GREEN}正在安装依赖...${NC}"
    apt update
    apt install python3-pip jq -y
    pip3 install requests
    echo -e "${GREEN}依赖安装完成。${NC}"
}

# 函数：切换 CDN 状态
toggle_cdn_status() {
    echo -e "${GREEN}正在检查当前 CDN 状态...${NC}"
    if grep -q "proxied=True" $PYTHON_SCRIPT; then
        echo -e "${YELLOW}当前 CDN 状态：开启${NC}"
        read -p "是否要关闭 CDN？(y/n): " choice
        if [[ $choice == "y" || $choice == "Y" ]]; then
            sed -i 's/proxied=True/proxied=False/g' $PYTHON_SCRIPT
            echo -e "${GREEN}CDN 已关闭。${NC}"
        else
            echo -e "${YELLOW}操作已取消，CDN 状态保持不变。${NC}"
        fi
    else
        echo -e "${YELLOW}当前 CDN 状态：关闭${NC}"
        read -p "是否要开启 CDN？(y/n): " choice
        if [[ $choice == "y" || $choice == "Y" ]]; then
            sed -i 's/proxied=False/proxied=True/g' $PYTHON_SCRIPT
            echo -e "${GREEN}CDN 已开启。${NC}"
        else
            echo -e "${YELLOW}操作已取消，CDN 状态保持不变。${NC}"
        fi
    fi
    echo -e "${YELLOW}注意：此更改将在下次运行 DNS 更新脚本时生效。${NC}"
}

# 函数：设置服务器备注
set_server_remark() {
    echo -e "${GREEN}设置服务器备注${NC}"
    read -p "请输入服务器备注: " remark
    echo "$remark" > $SERVER_REMARK_FILE
    sed -i "s/SERVER_REMARK = .*/SERVER_REMARK = \"$remark\"/" $PYTHON_SCRIPT
    echo -e "${GREEN}服务器备注已设置为: $remark${NC}"
}

# 主循环
while true; do
    clear
    show_menu
    read -p "请选择操作 (1-9): " choice
    echo
    case $choice in
        1) setup_cloudflare ;;
        2) setup_dingtalk ;;
        3) run_dns_update ;;
        4) check_status ;;
        5) stop_dns_update ;;
        6) install_dependencies ;;
        7) toggle_cdn_status ;;
        8) set_server_remark ;;
        9) echo -e "${YELLOW}感谢使用，再见！${NC}"; exit 0 ;;
        *) echo -e "${RED}无效选择，请重新输入。${NC}" ;;
    esac
    echo
    read -n 1 -s -r -p "按任意键返回主菜单..."
done