FROM python:3.13.11-alpine3.22 AS base
ARG TARGETPLATFORM

ENV APP_USER=appuser
RUN addgroup --system --gid 2000 ${APP_USER} && \
    adduser --system --uid 1000 --ingroup ${APP_USER} ${APP_USER}

RUN apk add bash \
    python3-dev \
    build-base \
    linux-headers \
    pcre-dev \
    mariadb-connector-c-dev \
    libffi-dev \
    libxslt-dev \
    libxml2-dev \
    git \
    postgresql-dev

WORKDIR /etc/app

COPY ./requirements.txt ./

RUN pip install -U uv setuptools pip

# make sure we are using the correct Python version
RUN uv python pin 3.13.11

RUN uv pip install --system -r requirements.txt

COPY ./ ./

RUN DJANGO_SETTINGS_MODULE=settings.prod_without_db DATABASE_TYPE=sqlite3 DATABASE_NAME=/var/lib/oncall/oncall.db SECRET_KEY="ThEmUsTSecretKEYforBUILDstage123" SILK_PROFILER_ENABLED="True" python manage.py collectstatic --no-input

RUN chown -R ${APP_USER}:${APP_USER} /etc/app

RUN mkdir -p /var/lib/oncall
RUN DATABASE_TYPE=sqlite3 DATABASE_NAME=/var/lib/oncall/oncall.db python manage.py create_sqlite_db
RUN chown -R ${APP_USER}:${APP_USER} /var/lib/oncall

RUN mkdir -p /tmp/silk_profiles;
RUN chown -R ${APP_USER}:${APP_USER} /tmp/silk_profiles

RUN mkdir -p /tmp/prometheus_django_metrics;
RUN chown -R ${APP_USER}:${APP_USER} /tmp/prometheus_django_metrics
ENV prometheus_multiproc_dir "/tmp/prometheus_django_metrics"

FROM base AS dev
RUN apk add sqlite mysql-client postgresql-client
RUN uv pip install --system -r requirements-dev.txt

FROM dev AS dev-enterprise
RUN uv pip install --system -r requirements-enterprise-docker.txt

FROM base AS prod

USER 1000
CMD [ "uwsgi", "--ini", "uwsgi.ini" ]
