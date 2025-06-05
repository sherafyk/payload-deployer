# Payload Deployer

Automates the deployment of [Payload CMS](https://github.com/payloadcms/payload) on a Debian based VPS using Docker.
This repository provides Docker configuration, helper scripts and a GitHub Actions workflow
for quickly provisioning new Payload CMS sites.

## Features

- Multi-stage `Dockerfile` producing a minimal image
- `docker-compose.yml` including PostgreSQL and MinIO
- `init-site.sh` script for initializing a new site on a server
- `deploy-update.sh` for updating an existing site
- CI workflow to build and deploy images to your server

## Getting Started

### Prerequisites

- Debian based server with Docker, Docker Compose and Traefik
- SSH access to the server
- A domain pointing to the server

### Environment Variables

Copy `.env.example` to `.env` and adjust the variables:

- `PAYLOAD_SECRET` – secret used to encrypt Payload data
- `DATABASE_URI` – PostgreSQL connection string
- `S3_ENDPOINT` – URL of the MinIO instance
- `PORT` – port the application should listen on
- `SITE_NAME` – identifier for the site
- `SITE_DOMAIN` – domain served by Traefik
- `TRUST_PROXY` – set to `1` when running behind a proxy

### Initialize a Site

Run the following on your server:

```sh
sudo ./scripts/init-site.sh
```

The script clones this repository to `/srv/<site>` and creates a systemd service
that manages the Docker Compose project. The service is enabled automatically.

### Deploy Updates

Once changes are pushed to the `main` branch, the GitHub Actions workflow builds
a Docker image and deploys it to the server by running `deploy-update.sh` over
SSH. You can also run the script manually:

```sh
cd /srv/<site>
sudo ./scripts/deploy-update.sh
```

### Troubleshooting

- Ensure environment variables are correctly set in `.env`.
- Check `systemctl status <site>.service` for service logs.
- Use `docker compose logs` to inspect container output.

## License

This project is released under the [MIT License](LICENSE).
