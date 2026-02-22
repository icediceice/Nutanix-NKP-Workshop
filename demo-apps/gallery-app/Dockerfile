# Stage 1: Build
# In a real app this stage would compile assets, run a bundler, etc.
# For this demo we just copy static files.
FROM alpine:3.19 AS build
WORKDIR /build
COPY app/ .
RUN echo "<html><body><h1>Gallery App</h1><p>Running on NKP!</p></body></html>" > index.html

# Stage 2: Runtime
FROM nginx:1.25-alpine

# Copy the nginx configuration
COPY <<'NGINX_CONF' /etc/nginx/conf.d/default.conf
server {
    listen       8080;
    server_name  _;

    location / {
        root   /usr/share/nginx/html;
        index  index.html;
    }

    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
NGINX_CONF

# Copy static assets from build stage
COPY --from=build /build /usr/share/nginx/html

# Run as non-root
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
