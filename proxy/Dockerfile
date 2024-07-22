FROM nginxinc/nginx-unprivileged:1-alpine
LABEL maintainer="your_email@example.com"

COPY ./nginx/* /etc/nginx/
COPY ./run.sh /run.sh

ENV LISTEN_PORT=80
ENV APP_HOST=app
ENV APP_PORT=9000

USER root

RUN apk add --no-cache openssl bash

RUN mkdir -p /vol/static && \
  chmod 755 /vol/static && \
  touch /etc/nginx/conf.d/default.conf && \
  chown nginx:nginx /etc/nginx/conf.d/default.conf && \
  chmod +x /run.sh

VOLUME /vol/static
VOLUME /vol/www

CMD ["/run.sh"]
