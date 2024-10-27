[![Build and Push Odoo Dev Container](https://github.com/m3r3nix/odoo-dev-container/actions/workflows/docker-publish.yml/badge.svg?branch=v18)](https://github.com/m3r3nix/odoo-dev-container/actions/workflows/docker-publish.yml)

# Odoo Development Container for GitHub Codespaces and Visual Studio Code on Desktop

Spin up a development-ready environment in just 4 simple steps:
1. Fork this repository or use it as a template and make it private (particularly if you intend to work with the Enterprise Edition).  
   Ensure that during this process, all branches are copied, not just the default one, if you aim to work with older Odoo versions as well.
2. Go to GitHub Actions and wait for all build processes to complete successfully. (Should you encounter any issues, please refer to the `Troubleshooting` section.)
3. Select the branch corresponding to the Odoo version you wish to develop for and initiate a Codespace. (The first boot takes about 2 minutes, be patient)  
    NOTE: If your work involves the Enterprise Edition, please adhere to the instructions in `Create/Update an Enterprise based image`.
4. Within the new VS Code instance, select the `Ports` tab. Then, right-click on port `8069` and choose `Open in Browser`. It will launch your new Odoo instance in your web browser.

## Important informations

- Your custom addons must be located in the `/custom` directory of the repository. However, within the Codespaces VS Code editor, this directory will serve as your root folder. See `estate-demo-addon`.
- The build action is triggered by any change to the `.devcontainer/URL.conf` file. However, if you already have the latest Community URL in place and simply need a new build based on the most recent `latest_all.deb` package, you can go to GitHub Actions and trigger the action manually.
- After forking this repository, update the GitHub Actions Badge URL at the top of the `README.md` file to reflect your own build processes. Otherwise, it will always display `no status`.
- Images are tagged not only with `latest` but also with the version number of the downloaded Debian Odoo installer package. This approach allows you to spin up a Codespace with a previous build version in case the latest Odoo version has a serious bug. Simply select an image, for example, `odoo-v18-community`, and look for available tags like `18.0.20240202` in your Container Registry. Then, adjust the tag in `docker-compose.yml` accordingly.

## How to create/update the development Docker image?

### Create/Update a Community based image

1. Update the current URL in `.devcontainer/URL.conf` to the latest Community version:  
    <https://nightly.odoo.com/18.0/nightly/deb/odoo_18.0.latest_all.deb>  
    Alternatively, select a specific build date from the following link and insert its corresponding URL into the file:  
    <https://nightly.odoo.com/18.0/nightly/deb>
2. If required, update the image name/tag in the `docker-compose.yml` file accordingly, for example `odoo-v18-community:latest`.
3. Commit and push your changes. This will automatically trigger a new build for the Docker image in GitHub Actions.
4. Look for any errors in the build process. If it's green, then we are fine, you can open a Codespace.

### Create/Update an Enterprise based image

1. Obtain the download link for the latest Odoo Enterprise Debian installation package:  
    <https://www.odoo.com/page/download>  
    After filling the form, click on Download (Ubuntu/Debian) and a "Congratulations! The download is starting" page will appear.  
    Right-click on `Click here` and select `Copy link` from your browser's dropdown menu.  
    This will give you a temporary download link, valid for approximately 30 minutes.   
2. Replace the URL in `.devcontainer/URL.conf` with the new one you have copied to the clipboard.
3. If required, update the image name/tag in the `docker-compose.yml` file accordingly, for example `odoo-v18-enterprise:latest`.
4. Commit and push your changes. This will automatically trigger a new build for the Docker image in GitHub Actions.
5. Look for any errors in the build process. If it's green, then we are fine, you can open a Codespace.

## In case of a new Odoo main release

1. The default branch should always contain the latest version. Therefore, create a new branch named after the latest version (e.g., `v19`) before making any changes.
2. Update the `Dockerfile` to reflect the current version from the official repository: <https://github.com/odoo/docker>
3. Attempt to build it and check for any errors.
4. Change the image tag in `docker-compose.yml` if necessary.
5. Update demo addon version number in manifest.py
6. Update README.md

## Possible improvements

You can create a pre-built Codespace template to speed up the initial boot process of a new Codespace. However, I'm still experimenting with this because, in some cases, it can cause more issues than it helps.

1. Go to repository `Settings`
2. Select `Codespaces`
3. Select `Set up pre-build`.
4. Select the branch.
5. Select `devcontainer.json`.
6. Select your region.
7. Save.

## Troubleshooting

- Forking the repository initiates a build process for all available Odoo versions simultaneously. Due to these parallel builds, the GitHub Container Registry might face permission limitations. If this occurs, wait until all builds are complete. Then, identify any failed build and select `Re-run failed job`.
- If you're forking or using this repository as a template more than once, you may encounter a permission issue during the docker image push process. This typically happens because an image with the same name (e.g. `odoo-v18-community`) already exists in your Container Registry, created by a different repository, which means the new repository lacks rights to update the image.  
  `Error: buildx failed with: ERROR: failed to solve: failed to push ghcr.io/YOURNAME/odoo-v18-community:18.0.20240202: unexpected status from POST request to https://ghcr.io/v2/YOURNAME/odoo-v18-community/blobs/uploads/: 403 Forbidden`  
  To resolve this issue:
  - Navigate to `Packages` and remove the search filter to display all available images in your Container Registry.
  - Select `odoo-v18-community`, proceed to `Package settings`, and under `Manage Actions access`, add your current repository with write access.
  - Afterwards, re-run the failed job.

## More info and credits

<https://containers.dev>  
<https://github.com/odoo/docker>
