FROM nginx:1.25-alpine

# Remove default configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose HTTP port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
