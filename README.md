# Payload Deployer

Payload Deployer automates setting up [Payload CMS](https://github.com/payloadcms/payload) on a Debian based VPS.  It provides the Docker configuration and helper scripts needed to run a Payload project behind Traefik with PostgreSQL and MinIO.

The typical workflow is:
1. Push your Payload CMS code to GitHub so a Docker image is built and published to GHCR.
2. Run the provided scripts on your VPS to clone the project and start the containers.
3. Whenever you push updates, pull the latest image and restart the site.

---

## Requirements

* Debian or Ubuntu VPS with **Docker**, **Docker Compose** and **Traefik** installed
* A domain name pointing to the server
* GitHub account with a repository containing your Payload CMS project
* Personal access token for GHCR (`write:packages` scope) to use in the workflow

Below are the detailed steps to get everything running.

## 1. Set up your repository

1. Fork or create a new repository for your Payload CMS project.
2. Copy `.env.example` from this repository into your project and adjust the values as needed.
3. In your GitHub repository settings, add a repository secret named `GHCR_TOKEN` containing a personal access token that has `write:packages` permission.  The CI workflow uses this token to push your Docker image to GitHub Container Registry.
4. Commit your changes and push to the `main` branch.  The workflow defined in `.github/workflows/ci-deploy.yml` will build a Docker image tagged `ghcr.io/<owner>/<repo>:latest`.

## 2. Prepare the VPS

Make sure Docker and Docker Compose are installed.  On a fresh Debian/Ubuntu server you can use:

```sh
sudo apt update
sudo apt install -y docker.io docker-compose git
```

You should also have Traefik running with a `websecure` entrypoint and Let's Encrypt resolver.  The containers created by this project attach to the `web` network used by Traefik.

Clone this repository to the server so you can use the helper scripts:

```sh
git clone https://github.com/your-user/payload-deployer.git
cd payload-deployer
```

## 3. Initialize a site

Run the `init-site.sh` script as root (or with sudo).  Provide the Git URL of the repository containing your Payload project when prompted or via the `REPO_URL` variable.

```sh
REPO_URL=https://github.com/your-user/your-project.git sudo ./scripts/init-site.sh
```

The script will:
1. Ask for a site name and domain.
2. Clone the project to `/srv/<site>`.
3. Copy the `.env` file and populate required values such as `PAYLOAD_SECRET`.
4. Create a systemd service that manages the Docker Compose stack.
5. Enable and start the service immediately.

Once finished, Traefik will serve your site at the domain you specified and Let's Encrypt certificates will be obtained automatically.

## 4. Deploy updates

Whenever you push to `main`, the CI workflow builds a new image.  To deploy the changes on your VPS run:

```sh
cd /srv/<site>
sudo ./scripts/deploy-update.sh
```

This pulls the latest image, runs database migrations and restarts the containers.

## Troubleshooting

* Ensure the values in `/srv/<site>/.env` are correct.
* Check `systemctl status <site>.service` for service state and logs.
* Inspect container output with `docker compose logs` if the site fails to start.

## License

This project is released under the [MIT License](LICENSE).
