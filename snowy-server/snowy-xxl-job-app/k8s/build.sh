#!/bin/bash

# Snowy XXL-Job App 镜像构建脚本
# 构建 Docker 镜像并加载到 Minikube（不含部署）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 配置参数
IMAGE_NAME="snowy-xxl-job-app"
IMAGE_TAG="latest"

# 打印彩色消息
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

# 检查 minikube 是否运行
check_minikube() {
    print_header "检查 Minikube 状态"
    if ! minikube status > /dev/null 2>&1; then
        print_msg "${RED}" "Minikube 未运行，请先启动 minikube:"
        echo "  minikube start"
        exit 1
    fi
    print_msg "${GREEN}" "Minikube 运行中"

    # 显示 minikube Docker 信息
    echo ""
    echo "Minikube 节点信息:"
    minikube node list
}

# 构建 Docker 镜像
build_image() {
    print_header "构建 Docker 镜像"

    # 获取项目根目录
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    local PARENT_DIR="$(dirname "$PROJECT_DIR")"
    local ROOT_DIR="$(dirname "$PARENT_DIR")"

    (
        cd "$ROOT_DIR"
        echo "构建上下文: $ROOT_DIR"
        echo "Dockerfile: snowy-server/snowy-xxl-job-app/Dockerfile"
        echo ""
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f snowy-server/snowy-xxl-job-app/Dockerfile .
    )

    print_msg "${GREEN}" "镜像构建成功: ${IMAGE_NAME}:${IMAGE_TAG}"

    # 显示镜像信息
    echo ""
    echo "本地镜像信息:"
    docker images ${IMAGE_NAME}:${IMAGE_TAG}
}

# 加载镜像到 minikube
load_image() {
    print_header "加载镜像到 Minikube"
    minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
    print_msg "${GREEN}" "镜像已加载到 minikube"

    # 验证镜像在 minikube 中
    echo ""
    echo "Minikube 中的镜像:"
    minikube image ls | grep ${IMAGE_NAME} || echo "镜像未找到"
}

# 显示后续步骤
show_next_steps() {
    print_header "后续步骤"
    echo "镜像已就绪，现在可以部署:"
    echo ""
    echo "1. 部署应用:"
    echo "   cd k8s"
    echo "   ./deploy.sh dev"
    echo ""
    echo "2. 或手动部署:"
    echo "   kubectl apply -k overlays/dev"
    echo ""
    echo "3. 查看镜像:"
    echo "   docker images ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "   minikube image ls | grep ${IMAGE_NAME}"
}

# 主执行流程
main() {
    print_msg "${GREEN}" "Snowy XXL-Job App - 镜像构建"
    echo ""

    check_minikube
    build_image
    load_image
    show_next_steps

    print_header "构建完成"
}

# 运行主函数
main
