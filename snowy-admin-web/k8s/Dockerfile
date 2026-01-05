# Snowy Admin Web - K8s Deployment Dockerfile
FROM nginx:alpine

# Copy static files
COPY dist/ /usr/share/nginx/html/

# Copy nginx configuration
COPY k8s/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
