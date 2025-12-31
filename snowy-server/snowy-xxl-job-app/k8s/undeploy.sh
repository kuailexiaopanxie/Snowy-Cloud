#!/bin/bash

# Snowy XXL-Job App Minikube undeployment script

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

# Configuration parameters
ENV=${1:-dev}  # Default to dev environment

# Set namespace based on environment
case ${ENV} in
  prod)
    NAMESPACE="production"
    ;;
  *)
    NAMESPACE="infra"
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

# Undeploy application
undeploy_app() {
    print_header "Undeploy from ${ENV} Environment"

    (
        local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$SCRIPT_DIR"

        # Check if overlay exists
        if [ ! -d "overlays/${ENV}" ]; then
            print_msg "${RED}" "Environment '${ENV}' does not exist. Available: dev, test, prod"
            exit 1
        fi

        kubectl delete -k overlays/${ENV} --ignore-not-found=true
    )
    print_msg "${GREEN}" "${ENV} environment undeployment completed"
}

# Optionally delete PVC
delete_pvc() {
    print_header "Delete PVC (Optional)"
    read -p "Do you want to delete PVC? This will delete all log data. : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete pvc snowy-xxl-job-app-logs -n ${NAMESPACE} --ignore-not-found=true
        print_msg "${GREEN}" "PVC deleted"
    else
        print_msg "${YELLOW}" "PVC retained"
    fi
}

# Show remaining resources
show_remaining() {
    print_header "Remaining Resources in ${NAMESPACE} Namespace"
    kubectl get all,pvc -n ${NAMESPACE} | grep snowy-xxl-job-app || echo "No remaining resources"
}

# Main execution flow
main() {
    print_msg "${GREEN}" "Snowy XXL-Job App - ${ENV} Environment Undeployment"
    echo ""

    undeploy_app
    delete_pvc
    show_remaining

    print_header "Undeployment Complete"
}

# Run main function
main
