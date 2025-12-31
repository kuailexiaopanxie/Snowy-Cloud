#!/bin/bash

# Snowy XXL-Job App Minikube deployment script

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

# Configuration parameters
IMAGE_NAME="snowy-xxl-job-app"
IMAGE_TAG="latest"
ENV=${1:-dev}  # Default to dev environment

# Set namespace and ingress host based on environment
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

# Print colored message
print_msg() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

# Print section header
print_header() {
    echo ""
    print_msg "${YELLOW}" "=========================================="
    print_msg "${YELLOW}" "$1"
    print_msg "${YELLOW}" "=========================================="
    echo ""
}

# Check if minikube is running
check_minikube() {
    print_header "Check Minikube Status"
    if ! minikube status > /dev/null 2>&1; then
        print_msg "${RED}" "Minikube is not running, please start minikube first:"
        echo "  minikube start"
        exit 1
    fi
    print_msg "${GREEN}" "Minikube is running"
}

# Build Docker image
build_image() {
    print_header "Build Docker Image"
    (
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
        local PARENT_DIR="$(dirname "$PROJECT_DIR")"
        local ROOT_DIR="$(dirname "$PARENT_DIR")"
        cd "$ROOT_DIR"
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f snowy-server/snowy-xxl-job-app/Dockerfile .
    )
    print_msg "${GREEN}" "Image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
}

# Load image to minikube
load_image() {
    print_header "Load Image to Minikube"
    minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
    print_msg "${GREEN}" "Image loaded to minikube"
}

# Create namespace
create_namespace() {
    print_header "Create Namespace: ${NAMESPACE}"
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    print_msg "${GREEN}" "Namespace ${NAMESPACE} is ready"
}

# Deploy application
deploy_app() {
    print_header "Deploy to ${ENV} Environment"

    (
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$SCRIPT_DIR"

        # Check if overlay exists
        if [ ! -d "overlays/${ENV}" ]; then
            print_msg "${RED}" "Environment '${ENV}' does not exist. Available: dev, test, prod"
            exit 1
        fi

        kubectl apply -k overlays/${ENV}
    )
    print_msg "${GREEN}" "${ENV} environment deployment completed"
}

# Wait for Pod ready
wait_for_pod() {
    print_header "Wait for Pod Ready"
    kubectl wait --for=condition=ready pod -l app=snowy-xxl-job-app -n ${NAMESPACE} --timeout=300s
    print_msg "${GREEN}" "Pod is ready"
}

# Show Pod status
show_status() {
    print_header "Pod Status"
    kubectl get pods -n ${NAMESPACE}
}

# Show access info
show_access_info() {
    print_header "Access Information"
    echo "XXL-Job Admin Console:"
    echo "  http://${INGRESS_HOST}/xxl-job-admin/"
    echo ""
    echo "Default credentials (check Nacos for actual values):"
    echo "  Username: admin"
    echo "  Password: (see Nacos config)"
    echo ""
    echo "Port forward (alternative):"
    echo "  kubectl port-forward svc/snowy-xxl-job-app 9004:9004 -n ${NAMESPACE}"
    echo "  Then visit: http://localhost:9004/xxl-job-admin/"
    echo ""
    echo "To enable Ingress:"
    echo "  minikube tunnel"
    echo "  Then add to /etc/hosts: 127.0.0.1 ${INGRESS_HOST}"
}

# Main execution flow
main() {
    print_msg "${GREEN}" "Snowy XXL-Job App - ${ENV} Environment Deployment"
    echo ""

    check_minikube
    build_image
    load_image
    create_namespace
    deploy_app
    wait_for_pod
    show_status
    show_access_info

    print_header "Deployment Completed Successfully"
}

# Run main function
main
