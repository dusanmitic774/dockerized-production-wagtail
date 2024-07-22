# Wagtail Docker Setup

A Docker setup for Wagtail CMS, designed for both local development and production environments.

## Getting Started

### Local Development

1. **Create and Activate a Virtual Environment**

```bash
mkdir app
virtualenv --python="/usr/bin/python3.10" "app/.venv"
source app/.venv/bin/activate
```

2. **Install Requirements**

```bash
pip install -r requirements.txt
```

3. **Create Wagtail Application**

```bash
wagtail start <name> app
```

*Initialize a new Wagtail project within the `app` directory.*

4. **Configure Database Settings**

In `base.py`, add the following:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'HOST': os.environ.get('DB_HOST'),
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASS'),
    }
}
```

*This configuration connects your Wagtail app to a PostgreSQL database using environment variables.*

5. **Configure Cache Settings**

In `base.py`, add the following cache configuration:

```python
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://redis:6379/1",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        }
    }
}
```

*Configures Django to use Redis for caching.*

6. **Copy `.env.example` file and rename it to `.env`**
```bash
cp .env.example .env
```

*This is where we store environment variables.*

7. **Build and Run Docker Containers**

```bash
docker compose build
docker compose up
```

8. **Run Migrations, Create Superuser, and Cache Table**

```bash
docker compose exec web python manage.py migrate
docker compose exec web python manage.py createsuperuser
docker compose exec web python manage.py createcachetable
```

## Deployment

### Steps for Production Deployment

1. **Create Linux User and SSH Key**

```bash
adduser <usernamek>
sudo usermod -aG sudo <username>
ssh-keygen -t ed25519 -b 4096
```

*Set up a user account and SSH key for secure access.*

2. **Install Docker**

Follow the [Docker installation guide for Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

3. **Create and Configure `.env` File**

Copy `.env.example` to `.env` and update it with your values:

```bash
cp .env.example .env
```

*The `.env` file contains environment-specific settings such as database credentials.*

4. **Configure Production Settings**

Update `production.py`:

```python
from .base import *
import os

DEBUG = False

SECRET_KEY = os.environ.get("SECRET_KEY", "setmeinprod")

ALLOWED_HOSTS = []
ALLOWED_HOSTS.extend(
    filter(
        None,
        os.environ.get("ALLOWED_HOSTS", "").split(","),
    )
)

STATIC_URL = "/static/static/"
MEDIA_URL = "/static/media/"

MEDIA_ROOT = "/vol/web/media"
STATIC_ROOT = "/vol/web/static"

CSRF_TRUSTED_ORIGINS = [
    "http://example.com",
    "https://example.com",
    "http://www.example.com",
    "https://www.example.com",
]

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "[%(asctime)s][%(process)d][%(thread)d][%(levelname)s][%(module)s]: %(message)s"
        },
        "simple": {"format": "[%(asctime)s][%(levelname)s][%(module)s]: %(message)s"},
    },
    "filters": {
        "require_debug_true": {
            "()": "django.utils.log.RequireDebugTrue",
        },
    },
    "handlers": {
        "syslog": {
            "level": "DEBUG",
            "class": "logging.handlers.SysLogHandler",
            "facility": "local7",
            "address": "/dev/log" if os.path.exists("/dev/log") else "/var/run/syslog",
            "formatter": "verbose",
        },
        "console": {
            "level": "INFO",
            "filters": ["require_debug_true"],
            "class": "logging.StreamHandler",
            "formatter": "simple",
        },
        "file": {
            "level": "ERROR",
            "class": "logging.handlers.RotatingFileHandler",
            "filename": "/var/log/example/example.log",
            "maxBytes": 1024 * 1024 * 5,  # 5 MB
            "backupCount": 5,
            "formatter": "verbose",
        },
    },
    "loggers": {
        "": {
            "handlers": ["console", "file", "syslog"],
            "level": "INFO",
            "propagate": True,
        },
    },
}
```

*This configuration sets up logging for your production environment, including console, file, and syslog handlers for capturing logs.*

5. **Configure `wsgi.py`**

```python
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "yourproject.settings.production")
```

*Ensure that `wsgi.py` is set to use the production settings.*

6. **Build and Run Docker Containers for Deployment**

```bash
docker compose -f docker-compose-deploy.yml build
docker compose -f docker-compose-deploy.yml up -d
```

*Deploy your application in production by building and starting the Docker containers.*

To update the application:

```bash
docker compose -f docker-compose-deploy.yml build app
docker compose -f docker-compose-deploy.yml up --no-deps -d
```

*Rebuild the specific service and update containers without affecting other services.*

## Adding Bootstrap

1. **Download Bootstrap Files**

- Add `bootstrap.min.css`, `bootstrap.bundle.min.js`, `bootstrap.min.css.map`, and `bootstrap.bundle.min.js.map` to the `static` directory of your Wagtail app.

2. **Configure Static Files Storage**

For local development:

```python
STATICFILES_STORAGE = "django.contrib.staticfiles.storage.StaticFilesStorage"
```

For production:

```python
STATICFILES_STORAGE = "django.contrib.staticfiles.storage.ManifestStaticFilesStorage"
```

*`ManifestStaticFilesStorage` appends a hash to filenames to prevent browsers from using cached versions of static files. Ensure you include `bootstrap.min.css.map` and `bootstrap.bundle.min.js.map` in your static directory for source maps to be available in production.*

## Setting Up SSL

1. **Build and Run Containers**

```bash
docker compose -f docker-compose-deploy.yml up -d
```

2. **Run Certbot**

```bash
docker compose -f docker-compose-deploy.yml run --rm certbot /opt/certify-init.sh
```

*Certbot obtains and installs SSL certificates for HTTPS.*

To issue new certificates:

```bash
docker compose -f docker-compose-deploy.yml run --rm certbot sh
ls /etc/letsencrypt/live/$DOMAIN/
```

If old certificates exist:

```bash
certbot revoke --cert-path /etc/letsencrypt/live/$DOMAIN/fullchain.pem --reason "superseded"
```

Re-run Certbot initialization:

```bash
docker compose -f docker-compose-deploy.yml run --rm certbot /opt/certify-init.sh
```

*Re-running Certbot ensures new certificates are applied and old ones are revoked as necessary.*

## Clearing Up Docker Cache

To free up disk space:

```bash
docker builder prune -a -f
```
