[![Build and Push Devcontainer Image](https://github.com/m3r3nix/odoo-dev-container/actions/workflows/docker-publish.yml/badge.svg?branch=v19)](https://github.com/m3r3nix/odoo-dev-container/actions/workflows/docker-publish.yml)

# Odoo Development Container for GitHub Codespaces and Visual Studio Code on Desktop
This repository gives you a ready-to-use Odoo development environment for Odoo Community and Enterprise. It contains all the dependencies and configurations needed for development and is designed to work both in GitHub Codespaces and in Visual Studio Code on your local machine (tested on Windows with WSL 2, but propably it works on Linux and macOS as well).

**⚠️ Important:** The `v19` branch has a new implementation which solves two painpoints of the older versions (branch `v18` and olders):
1. Odoo no longer runs as the main process of the container, so you can restart the Odoo service without restarting the whole container. This allows you to use Odoo's built-in `--dev=reload` support for Python code changes, which is a much smoother development experience.
2. The container image now contains only the runtime dependencies, Odoo Community and Enterprise source code are mounted from the host machine. This makes it much easier to keep the source code up to date. 

## Quick start in Visual Studio Code on Desktop

### Requirements on Windows
- WSL 2 with a Linux distribution installed and set as default
- Docker Desktop in WSL Mode

### Steps to start the container in VS Code on Desktop

1. Fork this repository to your own GitHub account.
2. Clone the forked repository inside WSL 2 (propably it works on Linux and macOS as well, but it is only tested on Windows with WSL 2).
3. Open the folder in VS Code: `code .`
4. Press `Ctrl+Shift+P` and run `Dev Containers: Reopen in Container`
5. Wait for the first startup to finish. It will create the required host directories and clone the Odoo Community source code automatically.
6. Open `http://localhost:8069`
7. Optional: if you use Odoo Enterprise, follow the steps in the `Working with Odoo source codes` section below.

Should you encounter any issues, please refer to the `Troubleshooting` section.

## Quick start in GitHub Codespaces
1. Fork this repository to your own GitHub account.
2. Select the Odoo version branch you want to work on, then click the `Code` button in the top right and select `Codespaces` > `Create a codespace`. The first startup will take about 2 minutes, be patient.
3. During the startup a popup in the right bottom corner will ask: `A git repository was found in the parent folders of the workspace or the open file(s). Would you like to open the repository?` Answer `Always`
4. Wait until a second popup appears with the message: `Your application running on port 8069 is available.` Click `Open in Browser` in that popup to access the Odoo instance.
5. Optional: if you use Odoo Enterprise, follow the steps in the `Working with Odoo source codes` section below.

Should you encounter any issues, please refer to the `Troubleshooting` section.

## Working with Odoo source codes

To clone or update Odoo Enterprise and Community source codes:

1. Open a terminal inside the container.
2. Make sure the bash prompt indicates the `odoo` user.
3. Use this helper script to clone or update Odoo source trees. This command clones/updates both Community and Enterprise source code when applicable, then restarts the Odoo service. You can run it any time you want to update the mounted Odoo source trees.

```bash
pull-sources.sh
```

The script will:

- clone Odoo Community into `/workspaces/odoo_source/odoo` if it does not exist yet
- update the `origin/19.0` branch for Odoo Community if it already exists
- ask `Do you have an Odoo Enterprise subscription?` before cloning Enterprise for the first time into `/workspaces/odoo_source/enterprise`. If you do not use Enterprise, answer `no` and the script will skip it.
- update Enterprise from `origin/19.0` when an Enterprise checkout already exists

## How this container works

Compared with the v18 and older branches, this version builds an image that contains only the runtime dependencies.

Odoo itself does not run as the main Docker process. Instead, it is managed by `supervisord` inside the container. This makes development easier because Python code changes can be reloaded with Odoo's built-in `--dev=reload` support, without restarting the whole container.

If needed, you can still restart the Odoo service manually:

```bash
supervisorctl restart odoo
supervisorctl status
```

On first startup, Docker creates these sibling directories next to this repository so data stays outside the container:

```text
../odoo_source/
├── enterprise (optional, can stay empty if you do not have an Enterprise subscription)
├── filestore
└── odoo (Community source code is cloned here automatically on first startup)
```

The devcontainer opens in `/workspaces/repo/custom` and runs as the `odoo` user, so any files created from the terminal or VS Code will have the correct permissions for Odoo to read them.
The integrated terminal uses `bash` and VS Code opens it in the `/workspaces/odoo_source` folder, so you can easily navigate between all your resources.

Your custom addons should live in the repository's `custom` directory. In VS Code, that directory is your main working area. An example addon is included in `custom/estate_demo_addon`.

Available local URLs:

- `http://localhost:8069`
- `https://odoo.localhost`

The HTTPS endpoint uses a self-signed certificate. Use it only when you need HTTPS-specific behavior, for example some token exchange flows in your custom addons.

### What the container runs

The compose setup starts two services:

- `workspace`: the main devcontainer service built from `.devcontainer/Dockerfile`
- `db`: PostgreSQL 16 with its data stored in `odoo_db` Docker volume

Inside the `workspace` container, `supervisord` starts:

- Nginx with a self-signed certificate for `odoo.localhost`
- Odoo from `/workspaces/odoo_source/odoo/odoo-bin`

Odoo config uses these addon paths:

- `/workspaces/odoo_source/custom`
- `/workspaces/odoo_source/enterprise`
- `/workspaces/odoo_source/odoo/addons`
- `/workspaces/odoo_source/odoo/odoo/addons`

Your custom addons should live in the repository's `custom` directory. In VS Code, that directory is your main working area. An example addon is included in `custom/estate_demo_addon`.

### Daily workflow

Check the status of services managed by Supervisord:

```bash
supervisorctl status
```

Restart Odoo:

```bash
supervisorctl restart odoo
```

Update the mounted source trees:

```bash
pull-sources.sh
```

View the Odoo log with the included VS Code task `Odoo Server Log`, or run the following command in the terminal:

```bash
tail -f /var/log/odoo/odoo-server.log
```

### Your custom Python dependencies

Add Python packages required by your custom addons to `custom/requirements.txt`.

The startup wrapper installs them automatically. After changing `custom/requirements.txt`, restart Odoo service to trigger a new install/upgrade.

### Ports and defaults

Exposed ports:

- `443`: HTTPS through nginx at `https://odoo.localhost`
- `8069`: direct Odoo HTTP access at `http://localhost:8069`
- `8072`: available for long-polling or websocket-related features if you enable them

Default development settings:

- PostgreSQL host: `db`
- PostgreSQL user/password: `odoo` / `odoo`
- Odoo admin password: `admin`
- Odoo branch: `19.0`
- Odoo extra args: `--dev=xml,reload,werkzeug` (can be changed in `docker-compose.yml`)

## Notes

- `.localhost` resolves locally on modern systems, so you usually do not need to edit your hosts file.
- The HTTPS certificate is self-signed and should be used for local development only.
- The devcontainer excludes the mounted Odoo source trees from the VS Code file watcher to keep the workspace responsive.
- On container startup, the entrypoint recursively sets ownership of `/workspaces/odoo_source` to `odoo:odoo`.

## CI and custom image builds

The CI pipeline is triggered on any change on the following files and directories:
- `.devcontainer/Dockerfile`
- `.devcontainer/configs/**`
- `.devcontainer/scripts/**`
- `.github/workflows/docker-publish.yml`

If you build your own image, make sure to update the `image` field in `.devcontainer/docker-compose.yml` accordingly.

You can also build it locally by replacing the `image` line with a `build` context in `.devcontainer/docker-compose.yml` like this:

```yaml
services:
  workspace:
    # image: ghcr.io/m3r3nix/odoo-v19-devcontainer:latest
    build:
      context: .
      dockerfile: .devcontainer/Dockerfile
      # The rest of the compose file remains unchanged
```

## Troubleshooting
- If the Python interpreter is not detected correctly in VS Code, open the command palette and run `Python: Select Interpreter`, then choose `3.12.x` for Odoo `v19`.
