# Payload Deployer

Automates the deployment of [Payload CMS](https://github.com/payloadcms/payload) on a Debian based VPS using Docker.
This repository provides Docker configuration, helper scripts and a GitHub Actions workflow
for quickly provisioning new Payload CMS sites.

## Features

- Multi-stage `Dockerfile` producing a minimal image
- `docker-compose.yml` including PostgreSQL and MinIO
- `init-site.sh` script for initializing a new site on a server
- `deploy-update.sh` for updating an existing site
- CI workflow to build and push images to GHCR
- Placeholder `build` script in `package.json` that can be customized for your project

## Setup

The workflow in `.github/workflows/ci-deploy.yml` builds your project and pushes a Docker image to GHCR using secrets from your repository.
It requires:

- `GHCR_TOKEN` – a personal access token with `write:packages` permission for pushing images to GHCR.

Run `scripts/deploy-update.sh` on your server to pull the latest image and restart the containers.

Create a personal access token by visiting **Settings → Developer settings → Personal access tokens** on GitHub and selecting the `write:packages` scope. Then add the required values as **Repository secrets** under **Settings → Secrets and variables → Actions**.

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

Run the following on your server, setting the Git repository for your Payload
project. You can provide the URL through the `REPO_URL` environment variable or
as the first argument to the script:

```sh
REPO_URL=https://github.com/your-user/your-project.git sudo ./scripts/init-site.sh
```

The script clones the specified repository to `/srv/<site>` and creates a
systemd service that manages the Docker Compose project. The service is enabled
automatically.

### Deploy Updates

Once changes are pushed to the `main` branch, the GitHub Actions workflow builds
a Docker image and pushes it to GHCR. Run `deploy-update.sh` on the server to
pull the new image and restart the containers:

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
