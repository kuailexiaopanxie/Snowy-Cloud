#!/bin/bash

# Snowy Admin Web - Build Docker Image

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Config
IMAGE_NAME="snowy-admin-web"
IMAGE_TAG="$(date +%Y%m%d-%H%M)"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

# Check if dist exists
check_dist() {
    print_header "检查构建产物"

    if [ ! -d "$PROJECT_ROOT/dist" ]; then
        print_msg "${RED}" "dist 目录不存在！"
        echo ""
        echo "请先运行前端构建："
        echo "  cd $PROJECT_ROOT"
        echo "  npm run build"
        exit 1
    fi

    print_msg "${GREEN}" "dist 目录存在"
}

# Build Docker image
build_image() {
    print_header "构建 Docker 镜像"

    cd "$PROJECT_ROOT"

    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f k8s/Dockerfile .

    print_msg "${GREEN}" "镜像构建成功: ${IMAGE_NAME}:${IMAGE_TAG}"
}

# Load image to minikube
load_to_minikube() {
    print_header "加载镜像到 Minikube"

    if ! minikube status &>/dev/null; then
        print_msg "${RED}" "Minikube 未运行"
        exit 1
    fi

    minikube image load ${IMAGE_NAME}:${IMAGE_TAG} >/dev/null 2>&1 || true

    print_msg "${GREEN}" "镜像已加载到 minikube"
}

# Main
main() {
    print_msg "${GREEN}" "Snowy Admin Web - 镜像构建"
    echo ""

    check_dist
    build_image
    load_to_minikube

    print_header "构建完成"
    print_msg "${GREEN}" "现在可以运行: ./k8s/deploy.sh dev"
}

main
