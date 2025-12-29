#!/bin/bash

# Snowy Nacos App Deployment Script for Minikube

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="snowy-nacos-app"
IMAGE_TAG="latest"
NAMESPACE="infra"
ENV=${1:-dev}  # Default to dev environment

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
    print_header "Checking Minikube Status"
    if ! minikube status > /dev/null 2>&1; then
        print_msg "${RED}" "Minikube is not running. Please start minikube first:"
        echo "  minikube start"
        exit 1
    fi
    print_msg "${GREEN}" "Minikube is running"
}

# Build Docker image
build_image() {
    print_header "Building Docker Image"
    (
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
        local PARENT_DIR="$(dirname "$PROJECT_DIR")"
        local ROOT_DIR="$(dirname "$PARENT_DIR")"
        cd "$ROOT_DIR"
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f snowy-server/snowy-nacos-app/Dockerfile .
    )
    print_msg "${GREEN}" "Image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
}

# Load image to minikube
load_image() {
    print_header "Loading Image to Minikube"
    minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
    print_msg "${GREEN}" "Image loaded to minikube"
}

# Create namespace
create_namespace() {
    print_header "Creating Namespace: ${NAMESPACE}"
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    print_msg "${GREEN}" "Namespace ${NAMESPACE} ready"
}

# Deploy application
deploy_app() {
    print_header "Deploying to ${ENV} Environment"

    (
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$SCRIPT_DIR"

        # Check if overlay exists
        if [ ! -d "overlays/${ENV}" ]; then
            print_msg "${RED}" "Environment '${ENV}' not found. Available: dev, test"
            exit 1
        fi

        kubectl apply -k overlays/${ENV}
    )
    print_msg "${GREEN}" "Deployment applied for ${ENV} environment"
}

# Wait for pod to be ready
wait_for_pod() {
    print_header "Waiting for Pod to be Ready"
    kubectl wait --for=condition=ready pod -l app=snowy-nacos-app -n ${NAMESPACE} --timeout=120s
    print_msg "${GREEN}" "Pod is ready"
}

# Show pod status
show_status() {
    print_header "Pod Status"
    kubectl get pods -n ${NAMESPACE}
}

# Show access info
show_access_info() {
    print_header "Access Information"
    echo "Port forward:"
    echo "  kubectl port-forward svc/snowy-nacos-app 8848:8848 -n ${NAMESPACE}"
    echo ""
    echo "Then visit: http://localhost:8848/nacos"
    echo ""
    echo "Or enable Ingress:"
    echo "  minikube tunnel"
    echo "  Then add to /etc/hosts: 127.0.0.1 nacos-dev.local"
}

# Main execution
main() {
    print_msg "${GREEN}" "Snowy Nacos App - ${ENV} Environment Deployment"
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
