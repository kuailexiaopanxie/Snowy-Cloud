#!/bin/bash

# Snowy Admin Web - Undeploy from K8s

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENV=${1:-dev}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="$PROJECT_ROOT/k8s"

print_msg() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

print_header() {
    echo ""
    print_msg "${YELLOW}" "=========================================="
    print_msg "${YELLOW}" "$1"
    print_msg "${YELLOW}" "=========================================="
    echo ""
}

# Undeploy from environment
undeploy() {
    print_header "从 ${ENV} 环境卸载"

    cd "$K8S_DIR/overlays/$ENV"

    kubectl delete -k . 2>/dev/null || true

    print_msg "${GREEN}" "${ENV} 环境卸载完成"
}

# Delete namespace (optional)
delete_namespace() {
    print_header "删除命名空间（可选）"

    read -p "是否要删除 frontend 命名空间？[y/N]: " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete namespace frontend 2>/dev/null || echo "命名空间已删除或不存在"
        print_msg "${GREEN}" "命名空间已删除"
    else
        print_msg "${YELLOW}" "命名空间已保留"
    fi
}

# Show remaining resources
show_remaining() {
    print_header "K8s 中剩余相关资源"

    echo "Pods:"
    kubectl get pods -n frontend 2>/dev/null || echo "无"
    echo ""
    echo "Services:"
    kubectl get svc -n frontend 2>/dev/null || echo "无"
    echo ""
    echo "Ingress:"
    kubectl get ingress -n frontend 2>/dev/null || echo "无"
}

# Main
main() {
    print_msg "${GREEN}" "Snowy Admin Web - K8s 卸载"
    echo ""

    undeploy
    delete_namespace
    show_remaining

    print_header "卸载完成"
    print_msg "${GREEN}" "如需重新部署，请运行: ./k8s/deploy.sh ${ENV}"
}

main
