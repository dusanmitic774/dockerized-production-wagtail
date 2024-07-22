#!/bin/sh

set -e

ls -la /vol/
ls -la /vol/web

whoami

python manage.py collectstatic --noinput
python manage.py migrate

# project_name is what we used when we ran `wagtail startapp project_name`
uwsgi --socket :9000 --workers 4 --master --enable-threads --module project_name.wsgi
