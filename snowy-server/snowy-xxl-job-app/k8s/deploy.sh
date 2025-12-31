#!/bin/bash

# Snowy XXL-Job App Minikube 部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 配置参数
IMAGE_NAME="snowy-xxl-job-app"
IMAGE_TAG="latest"
ENV=${1:-dev}  # 默认为开发环境

# 根据环境设置命名空间和 Ingress 主机
case ${ENV} in
  prod)
    NAMESPACE="production"
    INGRESS_HOST="xxl-job.example.com"
    ;;
  test)
    NAMESPACE="infra"
    INGRESS_HOST="xxl-job-test.local"
    ;;
  *)
    NAMESPACE="infra"
    INGRESS_HOST="xxl-job-dev.local"
    ;;
esac

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
}

# 构建 Docker 镜像
build_image() {
    print_header "构建 Docker 镜像"
    (
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
        local PARENT_DIR="$(dirname "$PROJECT_DIR")"
        local ROOT_DIR="$(dirname "$PARENT_DIR")"
        cd "$ROOT_DIR"
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f snowy-server/snowy-xxl-job-app/Dockerfile .
    )
    print_msg "${GREEN}" "镜像构建成功: ${IMAGE_NAME}:${IMAGE_TAG}"
}

# 加载镜像到 minikube
load_image() {
    print_header "加载镜像到 Minikube"
    minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
    print_msg "${GREEN}" "镜像已加载到 minikube"
}

# 创建命名空间
create_namespace() {
    print_header "创建命名空间: ${NAMESPACE}"
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    print_msg "${GREEN}" "命名空间 ${NAMESPACE} 已就绪"
}

# 部署应用
deploy_app() {
    print_header "部署到 ${ENV} 环境"

    (
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$SCRIPT_DIR"

        # 检查 overlay 是否存在
        if [ ! -d "overlays/${ENV}" ]; then
            print_msg "${RED}" "环境 '${ENV}' 不存在。可用环境: dev, test, prod"
            exit 1
        fi

        kubectl apply -k overlays/${ENV}
    )
    print_msg "${GREEN}" "${ENV} 环境部署完成"
}

# 等待 Pod 就绪
wait_for_pod() {
    print_header "等待 Pod 就绪"
    kubectl wait --for=condition=ready pod -l app=snowy-xxl-job-app -n ${NAMESPACE} --timeout=300s
    print_msg "${GREEN}" "Pod 已就绪"
}

# 显示 Pod 状态
show_status() {
    print_header "Pod 状态"
    kubectl get pods -n ${NAMESPACE}
}

# 显示访问信息
show_access_info() {
    print_header "访问信息"
    echo "XXL-Job 管理控制台:"
    echo "  http://${INGRESS_HOST}/xxl-job-admin/"
    echo ""
    echo "默认凭据（实际值请查看 Nacos 配置）:"
    echo "  用户名: admin"
    echo "  密码: (见 Nacos 配置)"
    echo ""
    echo "端口转发（备选方式）:"
    echo "  kubectl port-forward svc/snowy-xxl-job-app 9004:9004 -n ${NAMESPACE}"
    echo "  然后访问: http://localhost:9004/xxl-job-admin/"
    echo ""
    echo "启用 Ingress:"
    echo "  minikube tunnel"
    echo "  然后添加到 /etc/hosts: 127.0.0.1 ${INGRESS_HOST}"
}

# 主执行流程
main() {
    print_msg "${GREEN}" "Snowy XXL-Job App - ${ENV} 环境部署"
    echo ""

    check_minikube
    build_image
    load_image
    create_namespace
    deploy_app
    wait_for_pod
    show_status
    show_access_info

    print_header "部署成功完成"
}

# 运行主函数
main
