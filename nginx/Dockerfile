FROM nginx:1.25-alpine

# Install curl for healthcheck
RUN apk add --no-cache curl

# Remove default configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
RUN chown -R nginx:nginx /etc/nginx

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Expose HTTP port 80
EXPOSE 80

# Switch to non-root nginx user
USER nginx

CMD ["nginx", "-g", "daemon off;"]
