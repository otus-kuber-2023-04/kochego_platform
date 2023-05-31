FROM nginx:1.24.0
ENV UID=1001 \
    GID=1001 \
    USER=nginx \
    GROUP=nginx
WORKDIR /app
RUN usermod -u ${UID} ${USER} && groupmod -g ${GID} ${GROUP} && \
    chown -R ${USER}:${GROUP} /var/cache/nginx /var/log/nginx /app && \
    touch /var/run/nginx.pid && chown -R ${USER}:${GROUP} /var/run/nginx.pid
COPY /app /app
COPY nginx.conf /etc/nginx/conf.d/
USER $UID
EXPOSE 8000