# Serve the static site with Nginx.
FROM nginx:1.27-alpine

# The commit SHA is passed in at build time so the live site can say which release it is.
ARG GIT_SHA=unknown

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY assets /usr/share/nginx/html/assets
RUN echo "${GIT_SHA}" > /usr/share/nginx/html/version.txt

EXPOSE 80

# Docker marks the container "healthy" only while /healthz answers.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
