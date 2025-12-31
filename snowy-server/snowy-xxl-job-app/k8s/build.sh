#!/bin/bash

# Snowy XXL-Job App image build script
# Build Docker image and load to Minikube (without deployment)

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

# Configuration parameters
IMAGE_NAME="snowy-xxl-job-app"
IMAGE_TAG="latest"

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

    # Show minikube Docker info
    echo ""
    echo "Minikube node info:"
    minikube node list
}

# Build Docker image
build_image() {
    print_header "Build Docker Image"

    # Get project root directory
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    local PARENT_DIR="$(dirname "$PROJECT_DIR")"
    local ROOT_DIR="$(dirname "$PARENT_DIR")"

    (
        cd "$ROOT_DIR"
        echo "Build context: $ROOT_DIR"
        echo "Dockerfile: snowy-server/snowy-xxl-job-app/Dockerfile"
        echo ""
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f snowy-server/snowy-xxl-job-app/Dockerfile .
    )

    print_msg "${GREEN}" "Image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"

    # Show image info
    echo ""
    echo "Local image info:"
    docker images ${IMAGE_NAME}:${IMAGE_TAG}
}

# Load image to minikube
load_image() {
    print_header "Load Image to Minikube"
    minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
    print_msg "${GREEN}" "Image loaded to minikube"

    # Verify image is in minikube
    echo ""
    echo "Images in minikube:"
    minikube image ls | grep ${IMAGE_NAME} || echo "Image not found"
}

# Show next steps
show_next_steps() {
    print_header "Next Steps"
    echo "Image is ready, now you can deploy:"
    echo ""
    echo "1. Deploy application:"
    echo "   cd k8s"
    echo "   ./deploy.sh dev"
    echo ""
    echo "2. Or deploy manually:"
    echo "   kubectl apply -k overlays/dev"
    echo ""
    echo "3. View images:"
    echo "   docker images ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "   minikube image ls | grep ${IMAGE_NAME}"
}

# Main execution flow
main() {
    print_msg "${GREEN}" "Snowy XXL-Job App - Image Build"
    echo ""

    check_minikube
    build_image
    load_image
    show_next_steps

    print_header "Build Complete"
}

# Run main function
main
