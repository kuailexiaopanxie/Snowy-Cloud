#!/bin/bash

# Snowy Nacos App 卸载脚本

set -e

# 输出颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 配置参数
NAMESPACE="infra"
ENV=${1:-dev}  # 默认开发环境

# 打印带颜色的消息
print_msg() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

# 打印章节标题
print_header() {
    echo ""
    print_msg "${YELLOW}" "=========================================="
    print_msg "${YELLOW}" "$1"
    print_msg "${YELLOW}" "=========================================="
    echo ""
}

# 卸载应用
undeploy_app() {
    print_header "从 ${ENV} 环境卸载"

    (
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$SCRIPT_DIR"

        # 检查 overlay 是否存在
        if [ ! -d "overlays/${ENV}" ]; then
            print_msg "${RED}" "环境 '${ENV}' 不存在。可用环境: dev, test"
            exit 1
        fi

        kubectl delete -k overlays/${ENV} --ignore-not-found=true
    )
    print_msg "${GREEN}" "${ENV} 环境已卸载"
}

# 显示剩余资源
show_remaining() {
    print_header "${NAMESPACE} 命名空间中的剩余资源"
    kubectl get all,pvc,secret,configmap -n ${NAMESPACE} 2>/dev/null || true
}

# 主执行流程
main() {
    print_msg "${GREEN}" "Snowy Nacos App - ${ENV} 环境卸载"
    echo ""

    undeploy_app
    show_remaining

    print_header "卸载完成"
}

# 运行主函数
main
