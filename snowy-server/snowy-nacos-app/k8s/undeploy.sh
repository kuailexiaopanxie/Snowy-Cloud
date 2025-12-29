#!/bin/bash

# Snowy Nacos App Undeployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
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

# Undeploy application
undeploy_app() {
    print_header "Undeploying from ${ENV} Environment"

    (
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$SCRIPT_DIR"

        # Check if overlay exists
        if [ ! -d "overlays/${ENV}" ]; then
            print_msg "${RED}" "Environment '${ENV}' not found. Available: dev, test"
            exit 1
        fi

        kubectl delete -k overlays/${ENV} --ignore-not-found=true
    )
    print_msg "${GREEN}" "Undeployed ${ENV} environment"
}

# Show remaining resources
show_remaining() {
    print_header "Remaining Resources in ${NAMESPACE}"
    kubectl get all,pvc,secret,configmap -n ${NAMESPACE} 2>/dev/null || true
}

# Main execution
main() {
    print_msg "${GREEN}" "Snowy Nacos App - ${ENV} Environment Undeployment"
    echo ""

    undeploy_app
    show_remaining

    print_header "Undeployment Completed"
}

# Run main function
main
