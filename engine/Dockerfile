FROM python:3.12.3-slim AS base
ARG TARGETPLATFORM

ENV APP_USER=appuser
RUN groupadd --system --gid 2000 ${APP_USER} && \
    useradd --system --uid 1000 --gid 2000 ${APP_USER}

# Build & runtime deps (no inline comments; each line ends with '\' except last)
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    netcat-openbsd \
    python3-dev \
    pkg-config \
    libpcre3-dev \
    default-libmysqlclient-dev \
    libffi-dev \
    libssl-dev \
    git \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /etc/app

COPY ./requirements.txt ./

# Get a proper manylinux aarch64 wheel for grpcio on Debian/glibc
RUN python -m pip install --upgrade "pip>=24" && \
    pip install --no-cache-dir --only-binary=:all: "grpcio==1.64.1"

RUN pip install --no-cache-dir uv setuptools

# uWSGI will compile here; we now have gcc and Python headers installed
RUN uv pip install --system -r requirements.txt

# Copy the rest of the app
COPY ./ ./

# Collect static files
RUN DJANGO_SETTINGS_MODULE=settings.prod_without_db \
    DATABASE_TYPE=sqlite3 \
    DATABASE_NAME=/var/lib/oncall/oncall.db \
    SECRET_KEY="ThEmUsTSecretKEYforBUILDstage123" \
    SILK_PROFILER_ENABLED="True" \
    python manage.py collectstatic --no-input

# Fix permissions
RUN chown -R ${APP_USER}:${APP_USER} /etc/app

# Create SQLite DB and set permissions
RUN mkdir -p /var/lib/oncall && \
    DATABASE_TYPE=sqlite3 DATABASE_NAME=/var/lib/oncall/oncall.db python manage.py create_sqlite_db && \
    chown -R ${APP_USER}:${APP_USER} /var/lib/oncall

# Profiler/shared dirs
RUN mkdir -p /tmp/silk_profiles && chown -R ${APP_USER}:${APP_USER} /tmp/silk_profiles
RUN mkdir -p /tmp/prometheus_django_metrics && chown -R ${APP_USER}:${APP_USER} /tmp/prometheus_django_metrics
ENV prometheus_multiproc_dir="/tmp/prometheus_django_metrics"

FROM base AS dev
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sqlite3 \
    default-mysql-client \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*
RUN uv pip install --system -r requirements-dev.txt

FROM dev AS dev-enterprise
RUN uv pip install --system -r requirements-enterprise-docker.txt

FROM base AS prod
USER 1000
CMD [ "uwsgi", "--ini", "uwsgi.ini" ]