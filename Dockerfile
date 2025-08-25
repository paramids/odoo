FROM python:3.11-slim-bullseye

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    ODOO_RC=/etc/odoo/odoo.conf \
    ODOO_DATA_DIR=/var/lib/odoo

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build dependencies
    build-essential \
    gcc \
    # PostgreSQL client
    libpq-dev \
    postgresql-client \
    # XML processing
    libxml2-dev \
    libxslt1-dev \
    # Image processing
    libjpeg-dev \
    libfreetype6-dev \
    libffi-dev \
    # LDAP support
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    # Fonts and locales
    fonts-liberation \
    locales \
    # Node.js for JS processing
    nodejs \
    npm \
    # Utilities
    curl \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/^#.* en_US.UTF-8 /s/^#//' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Create odoo user
RUN groupadd -r odoo && useradd -r -g odoo -d /var/lib/odoo -s /bin/bash odoo

# Create directories
RUN mkdir -p /etc/odoo \
    && mkdir -p /var/lib/odoo \
    && mkdir -p /var/log/odoo \
    && chown -R odoo:odoo /var/lib/odoo /var/log/odoo

# Set working directory
WORKDIR /opt/odoo

# Copy Odoo source code first (setup.py needs odoo/release.py)
COPY --chown=odoo:odoo . ./

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -e . && \
    pip install --no-cache-dir lxml_html_clean

# Create Odoo configuration file
RUN echo "[options]" > /etc/odoo/odoo.conf && \
    echo "addons_path = /opt/odoo/addons,/opt/odoo/odoo/addons" >> /etc/odoo/odoo.conf && \
    echo "data_dir = /var/lib/odoo" >> /etc/odoo/odoo.conf && \
    echo "logfile = /var/log/odoo/odoo.log" >> /etc/odoo/odoo.conf && \
    echo "log_level = info" >> /etc/odoo/odoo.conf && \
    echo "db_host = db" >> /etc/odoo/odoo.conf && \
    echo "db_port = 5432" >> /etc/odoo/odoo.conf && \
    echo "db_user = odoo" >> /etc/odoo/odoo.conf && \
    echo "db_password = odoo" >> /etc/odoo/odoo.conf && \
    chown -R odoo:odoo /etc/odoo

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to odoo user
USER odoo

# Expose Odoo port
EXPOSE 8069

# Set volumes
VOLUME ["/var/lib/odoo", "/var/log/odoo"]

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["odoo"] 