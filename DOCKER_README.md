# Odoo Docker Setup

This setup provides a fully containerized Odoo environment with PostgreSQL database using Docker Compose.

## Quick Start

### 1. Build and Start Services

```bash
# Build the Odoo image and start all services
docker compose up --build

# Or run in detached mode
docker compose up --build -d
```

### 2. Access Odoo

- **Odoo Web Interface**: http://localhost:8069
- **Database**: rd-demo (automatically created)
- **Admin Credentials**: 
  - Master Password: `admin123`
  - Default admin user will be created during first setup

### 3. Optional: Start with pgAdmin

```bash
# Start with database administration tool
docker compose --profile admin up --build
```

- **pgAdmin**: http://localhost:8080
- **Login**: admin@odoo.local / admin123

## Configuration

### Environment Variables

You can customize the setup by modifying environment variables in `docker-compose.yml`:

```yaml
environment:
  # Database
  DB_HOST: db
  DB_PORT: 5432
  DB_USER: odoo
  DB_PASSWORD: odoo123
  
  # Odoo
  ADMIN_PASSWORD: admin123
  WORKERS: 2
  MAX_CRON_THREADS: 2
  LOG_LEVEL: info
```

### Custom Addons

To add custom addons:

1. Create a `custom-addons` directory
2. Uncomment the volume mount in `docker-compose.yml`:
   ```yaml
   volumes:
     - ./custom-addons:/opt/odoo/custom-addons:ro
   ```
3. Update the addons path:
   ```yaml
   environment:
     ADDONS_PATH: /opt/odoo/addons,/opt/odoo/odoo/addons,/opt/odoo/custom-addons
   ```

## Docker Commands

### Basic Operations

```bash
# Start services
docker compose up

# Stop services
docker compose down

# View logs
docker compose logs
docker compose logs odoo
docker compose logs db

# Restart specific service
docker compose restart odoo
```

### Development Commands

```bash
# Access Odoo shell
docker compose exec odoo odoo-shell

# Run Odoo upgrade
docker compose run --rm odoo odoo-upgrade --database=rd-demo

# Access PostgreSQL
docker compose exec db psql -U odoo -d rd-demo
```

### Data Management

```bash
# Backup volumes
docker run --rm -v odoo_postgres_data:/source -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz -C /source .
docker run --rm -v odoo_odoo_data:/source -v $(pwd):/backup alpine tar czf /backup/odoo_backup.tar.gz -C /source .

# Clean up (WARNING: This removes all data)
docker compose down -v
docker system prune -a
```

## File Structure

```
.
├── Dockerfile              # Odoo container definition
├── docker-compose.yml      # Service orchestration
├── docker-entrypoint.sh    # Container startup script
├── .dockerignore           # Build context exclusions
├── setup.py                # Python dependencies
├── odoo-bin                # Odoo executable
├── odoo/                   # Odoo core
├── addons/                 # Standard addons
└── custom-addons/          # Custom addons (optional)
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: If ports 8069, 5432, or 8080 are in use, modify the ports in `docker-compose.yml`
2. **Permission issues**: Ensure Docker has proper permissions to access the project directory
3. **Build failures**: Check that all files (especially `docker-entrypoint.sh`) have proper line endings (LF, not CRLF)

### Logs and Debugging

```bash
# View detailed logs
docker compose logs -f odoo

# Access container shell
docker compose exec odoo bash

# Check container status
docker compose ps
```

## Production Considerations

For production deployment:

1. Change default passwords
2. Use environment files for secrets
3. Configure proper SSL/TLS
4. Set up proper backup strategies
5. Consider using external managed databases
6. Configure proper resource limits
7. Set up monitoring and logging 