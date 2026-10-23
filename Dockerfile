FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN python -m pip install --no-cache-dir -r requirements.txt

RUN groupadd --gid 10001 forge \
    && useradd --uid 10001 --gid forge --no-create-home \
       --shell /usr/sbin/nologin forge

COPY server.py .

USER 10001:10001

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import json, sys, urllib.request; opener = urllib.request.build_opener(urllib.request.ProxyHandler({})); response = opener.open('http://127.0.0.1:5000/health', timeout=2); data = json.load(response); sys.exit(0 if response.status == 200 and isinstance(data, dict) and data.get('status') == 'healthy' else 1)"]

CMD ["gunicorn", "--no-control-socket", "--bind=0.0.0.0:5000", "--workers=1", "--access-logfile=-", "--error-logfile=-", "server:app"]
