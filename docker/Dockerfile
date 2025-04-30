FROM python:3.9-slim-bullseye

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    libcurl4 \
    libcurl4-openssl-dev \
    libssl-dev \
    curl \
    git \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /app

COPY requirements.txt .

RUN echo "Installing python requirements" && \
    pip install -r requirements.txt

COPY . .

RUN groupadd -r notify && useradd -r -g notify notify && chown -R notify:notify /app

USER notify

CMD ["/bin/bash", "-c", "gunicorn --bind 0.0.0.0:${PORT} --worker-class=eventlet --workers=2 wsgi:app"]
