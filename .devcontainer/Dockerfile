FROM python:3.12-slim

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ODOO_RC=/etc/odoo/odoo.conf \
    ODOO_BRANCH=19.0

ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        git \
        gnupg \
        libcairo2-dev \
        libffi-dev \
        libjpeg-dev \
        liblcms2-dev \
        libldap2-dev \
        libmagic1 \
        libopenjp2-7-dev \
        libpq-dev \
        libsasl2-dev \
        libssl-dev \
        libtiff-dev \
        libwebp-dev \
        libxml2-dev \
        libxslt1-dev \
        nginx \
        node-less \
        npm \
        openssl \
        pkg-config \
        supervisor \
        xz-utils \
        zlib1g-dev \
    && if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi \
    && WKHTMLTOPDF_ARCH="${TARGETARCH}" \
    && case "${TARGETARCH}" in \
        amd64) WKHTMLTOPDF_ARCH=amd64;; \
        arm64) WKHTMLTOPDF_ARCH=arm64;; \
        ppc64le|ppc64el) WKHTMLTOPDF_ARCH=ppc64el;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL -o wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_${WKHTMLTOPDF_ARCH}.deb \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install latest postgresql-client
RUN install -d /usr/share/postgresql-common/pgdg \
    && curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && . /etc/os-release \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g rtlcss

# Install Odoo requirements.txt from the given branch and PyPI replacements
# for Python packages that were previously provided by Debian's python3-* packages.
RUN curl -fsSL -o requirements.txt https://raw.githubusercontent.com/odoo/odoo/${ODOO_BRANCH}/requirements.txt \
    && python3 -m pip install --no-cache-dir --upgrade --root-user-action=ignore pip setuptools wheel \
    && python3 -m pip install --no-cache-dir --root-user-action=ignore \
        google-auth \
        odfpy \
        pdfminer.six \
        phonenumbers \
        python-slugify \
        rlPyCairo \
        watchdog \
    && python3 -m pip install --no-cache-dir --root-user-action=ignore -r requirements.txt \
    && rm requirements.txt

# Generate self-signed SSL certificate for nginx
# Some custom module may require HTTPS for development e.g. eBay API
RUN mkdir -p /etc/nginx/certs \
    && openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
        -keyout /etc/nginx/certs/odoo.localhost.key \
        -out /etc/nginx/certs/odoo.localhost.crt \
        -subj "/CN=odoo.localhost" \
        -addext "subjectAltName=DNS:odoo.localhost,DNS:localhost" \
    && chown root:root /etc/nginx/certs/odoo.localhost.key /etc/nginx/certs/odoo.localhost.crt \
    && chmod 600 /etc/nginx/certs/odoo.localhost.key \
    && chmod 644 /etc/nginx/certs/odoo.localhost.crt

RUN if getent passwd 1000 >/dev/null; then \
        EXISTING_USER="$(getent passwd 1000 | cut -d: -f1)"; \
        EXISTING_GROUP="$(id -gn "${EXISTING_USER}")"; \
        if [ "${EXISTING_GROUP}" != "odoo" ]; then \
            groupmod -n odoo "${EXISTING_GROUP}"; \
        fi; \
        if [ "${EXISTING_USER}" != "odoo" ]; then \
            usermod -l odoo "${EXISTING_USER}"; \
        fi; \
        usermod -d /home/odoo -m odoo; \
    else \
        groupadd --gid 1000 odoo; \
        useradd --create-home --home-dir /home/odoo --shell /bin/bash --uid 1000 --gid 1000 odoo; \
    fi \
    && mkdir -p /etc/odoo /etc/supervisor /var/log/odoo \
    && chown -R odoo:odoo /home/odoo /var/log/odoo

COPY ./configs/nginx.conf /etc/nginx/nginx.conf
COPY ./configs/odoo.conf /etc/odoo/odoo.conf
COPY ./configs/supervisord.conf /etc/supervisor/supervisord.conf
COPY ./scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./scripts/pull-sources.sh /usr/local/bin/pull-sources.sh
COPY ./scripts/run-odoo.sh /usr/local/bin/run-odoo.sh

RUN chown -R odoo:odoo /etc/odoo/odoo.conf
RUN chmod 755 \
        /usr/local/bin/entrypoint.sh \
        /usr/local/bin/pull-sources.sh \
        /usr/local/bin/run-odoo.sh

# Create system-wide aliases
RUN echo "alias ll='ls -la'" >> /etc/bash.bashrc

# Improve history search bindings for Bash
RUN cat >> /etc/inputrc <<'EOF'
"\C-[OA": history-search-backward
"\C-[[A": history-search-backward
"\C-[OB": history-search-forward
"\C-[[B": history-search-forward
EOF

EXPOSE 443 8069 8072

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
