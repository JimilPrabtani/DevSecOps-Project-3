FROM nginx:1.25-alpine

# Install curl for healthcheck
RUN apk add --no-cache curl

# Remove default configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Add health check (proxy-only endpoint, doesn't depend on flask-app)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/healthz || exit 1

# Expose HTTP port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]