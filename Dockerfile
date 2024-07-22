FROM python:3.10-slim

LABEL maintainer="your-email@example.com"

ENV PYTHONUNBUFFERED=1

COPY ./requirements.txt /requirements.txt
COPY ./app /app
COPY ./scripts /scripts

WORKDIR /app

EXPOSE 8000

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  libjpeg62-turbo-dev \
  zlib1g-dev \
  libwebp-dev && \
  python -m venv /py && \
  /py/bin/pip install --upgrade pip && \
  /py/bin/pip install -r /requirements.txt && \
  # Cleans up unnecessary packages and clears apt cache to reduce image size.
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  build-essential libpq-dev && \
  rm -rf /var/lib/apt/lists/* && \
  adduser --disabled-password --no-create-home app && \
  mkdir -p /vol/web/static && \
  mkdir -p /vol/web/media && \
  #change project_name placeholder
  mkdir -p /var/log/project_name && \
  chown -R app:app /vol && \
  chmod -R 755 /vol && \
  chown -R app:app /var/log/project_name && \
  chmod -R 755 /var/log/project_name && \
  chmod -R +x /scripts

ENV PATH="/scripts:/py/bin:$PATH"

USER app

CMD ["run.sh"]
