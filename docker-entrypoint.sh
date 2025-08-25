#!/bin/bash
set -e

# Function to wait for PostgreSQL
wait_for_postgres() {
    local host=${DB_HOST:-db}
    local port=${DB_PORT:-5432}
    local user=${DB_USER:-odoo}
    local password=${DB_PASSWORD:-odoo}
    
    echo "Waiting for PostgreSQL at $host:$port..."
    
    until PGPASSWORD=$password psql -h "$host" -p "$port" -U "$user" -c '\q' 2>/dev/null; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 1
    done
    
    echo "PostgreSQL is up - executing command"
}

# Function to initialize database if needed
init_db() {
    local db_name=${DB_NAME:-postgres}
    local host=${DB_HOST:-db}
    local port=${DB_PORT:-5432}
    local user=${DB_USER:-odoo}
    local password=${DB_PASSWORD:-odoo}
    
    echo "Checking if database initialization is needed..."
    
    # Check if we can connect to a specific database
    if [ "$db_name" != "postgres" ]; then
        if ! PGPASSWORD=$password psql -h "$host" -p "$port" -U "$user" -d "$db_name" -c '\q' 2>/dev/null; then
            echo "Database $db_name does not exist, it will be created by Odoo"
        fi
    fi
}

# Update configuration with environment variables
update_config() {
    local config_file="/etc/odoo/odoo.conf"
    local temp_config="/tmp/odoo.conf"
    
    # Copy config to temporary location that odoo user can write to
    cp "$config_file" "$temp_config"
    config_file="$temp_config"
    
    # Database configuration
    if [ -n "$DB_HOST" ]; then
        sed -i "s/^db_host = .*/db_host = $DB_HOST/" "$config_file"
    fi
    
    if [ -n "$DB_PORT" ]; then
        sed -i "s/^db_port = .*/db_port = $DB_PORT/" "$config_file"
    fi
    
    if [ -n "$DB_USER" ]; then
        sed -i "s/^db_user = .*/db_user = $DB_USER/" "$config_file"
    fi
    
    if [ -n "$DB_PASSWORD" ]; then
        sed -i "s/^db_password = .*/db_password = $DB_PASSWORD/" "$config_file"
    fi
    
    # Other Odoo configuration
    if [ -n "$ADMIN_PASSWORD" ]; then
        echo "admin_passwd = $ADMIN_PASSWORD" >> "$config_file"
    fi
    
    if [ -n "$ADDONS_PATH" ]; then
        sed -i "s|^addons_path = .*|addons_path = $ADDONS_PATH|" "$config_file"
    fi
    
    if [ -n "$WORKERS" ]; then
        sed -i "s/^workers = .*/workers = $WORKERS/" "$config_file"
    fi
    
    if [ -n "$MAX_CRON_THREADS" ]; then
        sed -i "s/^max_cron_threads = .*/max_cron_threads = $MAX_CRON_THREADS/" "$config_file"
    fi
    
    if [ -n "$LOG_LEVEL" ]; then
        sed -i "s/^log_level = .*/log_level = $LOG_LEVEL/" "$config_file"
    fi
    
    # Ensure syslog is disabled for Docker
    sed -i "s/^syslog = .*/syslog = False/" "$config_file"
}

# Main execution
case "$1" in
    odoo)
        # Update configuration
        update_config
        
        # Wait for database
        wait_for_postgres
        
        # Initialize database if needed
        init_db
        
        # Start Odoo
        echo "Starting Odoo..."
        exec /opt/odoo/odoo-bin \
            --config=/tmp/odoo.conf \
            --without-demo=all \
            "${@:2}"
        ;;
    odoo-shell)
        # Update configuration
        update_config
        
        # Wait for database
        wait_for_postgres
        
        # Start Odoo shell
        echo "Starting Odoo shell..."
        exec /opt/odoo/odoo-bin shell \
            --config=/tmp/odoo.conf \
            "${@:2}"
        ;;
    odoo-upgrade)
        # Update configuration
        update_config
        
        # Wait for database
        wait_for_postgres
        
        # Run Odoo upgrade
        echo "Running Odoo upgrade..."
        exec /opt/odoo/odoo-bin \
            --config=/tmp/odoo.conf \
            --update=all \
            --stop-after-init \
            "${@:2}"
        ;;
    *)
        # Execute any other command
        exec "$@"
        ;;
esac 