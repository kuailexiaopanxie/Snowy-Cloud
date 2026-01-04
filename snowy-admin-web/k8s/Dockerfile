# Snowy Admin Web - K8s Deployment Dockerfile
FROM nginx:alpine

# Copy static files
COPY dist/ /usr/share/nginx/html/

# Copy nginx configuration
COPY k8s/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:8080/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
