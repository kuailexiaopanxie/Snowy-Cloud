#!/bin/bash

# Snowy Admin Web - Deploy to K8s

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Config
IMAGE_NAME="snowy-admin-web"
IMAGE_TAG="$(date +%Y%m%d-%H%M)"
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

# Check minikube status
check_minikube() {
    print_header "检查 Minikube 状态"

    if ! minikube status &>/dev/null; then
        print_msg "${RED}" "Minikube 未运行"
        exit 1
    fi

    print_msg "${GREEN}" "Minikube 运行中"
}

# Build Docker image
build_image() {
    print_header "构建 Docker 镜像"

    cd "$PROJECT_ROOT"

    if ! docker images | grep -q "^${IMAGE_NAME}.*${IMAGE_TAG}"; then
        print_msg "${YELLOW}" "镜像不存在，开始构建..."
        bash "$K8S_DIR/build.sh"
    else
        print_msg "${GREEN}" "镜像已存在"
    fi
}

# Load image to minikube
load_to_minikube() {
    print_header "加载镜像到 Minikube"

    minikube image load ${IMAGE_NAME}:${IMAGE_TAG} >/dev/null 2>&1 || true

    print_msg "${GREEN}" "镜像已加载到 minikube"
}

# Create namespace
create_namespace() {
    print_header "创建命名空间: frontend"

    kubectl apply -f "$K8S_DIR/base/namespace.yaml" >/dev/null 2>&1 || true

    print_msg "${GREEN}" "命名空间 frontend 已就绪"
}

# Deploy to environment
deploy() {
    print_header "部署到 ${ENV} 环境"

    cd "$K8S_DIR/overlays/$ENV"

    kubectl apply -k .

    # Update image to latest build (with timestamp tag)
    kubectl set image deployment/snowy-admin-web -n frontend nginx=${IMAGE_NAME}:${IMAGE_TAG}

    print_msg "${GREEN}" "${ENV} 环境部署完成 (镜像: ${IMAGE_NAME}:${IMAGE_TAG})"
}

# Wait for pod ready
wait_for_pod() {
    print_header "等待 Pod 就绪"

    local timeout=120
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        local ready=$(kubectl get pods -n frontend -l app=snowy-admin-web -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")

        if [ "$ready" = "True" ]; then
            print_msg "${GREEN}" "Pod 已就绪"
            return 0
        fi

        sleep 2
        elapsed=$((elapsed + 2))
    done

    print_msg "${RED}" "Pod 启动超时"
    return 1
}

# Show pod status
show_status() {
    print_header "Pod 状态"

    kubectl get pods -n frontend
}

# Get images to cleanup (all except latest)
get_images_to_cleanup() {
    docker images --format "{{.Repository}}:{{.Tag}} {{.CreatedAt}}" \
        | grep "^${IMAGE_NAME}:" \
        | sort -k2 -r \
        | tail -n +2 \
        | awk '{print $1}'
}

# Cleanup old docker images
cleanup_docker_images() {
    local images=$1

    echo "$images" | while read -r image; do
        [ -n "$image" ] && docker rmi "$image" 2>/dev/null && print_msg "${GREEN}" "已删除本地镜像: $image"
    done
}

# Cleanup old minikube images
cleanup_minikube_images() {
    local images=$1

    echo "$images" | while read -r image; do
        [ -n "$image" ] && minikube image rm "$image" 2>/dev/null && print_msg "${GREEN}" "已删除 minikube 镜像: $image"
    done
}

# Cleanup old images
cleanup_old_images() {
    print_header "清理历史镜像"

    local images_to_remove=$(get_images_to_cleanup)

    if [ -z "$images_to_remove" ]; then
        print_msg "${GREEN}" "无需清理的镜像"
        return 0
    fi

    print_msg "${YELLOW}" "将清理以下历史镜像："
    echo "$images_to_remove"
    echo ""

    cleanup_docker_images "$images_to_remove"
    cleanup_minikube_images "$images_to_remove"

    print_msg "${GREEN}" "历史镜像清理完成"
}

# Show access info
show_access_info() {
    print_header "访问信息"

    print_msg "${GREEN}" "前端应用已部署到 K8s！"
    echo ""
    echo "访问地址: http://snowy-dev.local"
    echo ""
    echo "如果无法访问，请检查 /etc/hosts 是否包含："
    echo "  127.0.0.1 snowy-dev.local"
    echo ""
    echo "确保 minikube tunnel 正在运行："
    echo "  minikube tunnel"
    echo ""
    echo "查看日志:"
    echo "  kubectl logs -f -n frontend -l app=snowy-admin-web"
    echo ""
    echo "卸载部署:"
    echo "  ./k8s/undeploy.sh ${ENV}"
}

# Main
main() {
    print_msg "${GREEN}" "Snowy Admin Web - K8s 部署"
    echo ""

    check_minikube
    build_image
    load_to_minikube
    create_namespace
    deploy
    wait_for_pod
    cleanup_old_images
    show_status
    show_access_info

    print_header "部署成功完成"
}

main
