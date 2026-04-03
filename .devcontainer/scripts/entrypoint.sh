#!/usr/bin/env bash

set -euo pipefail

: "${REPO_DIR:=/workspaces/repo}"
: "${ODOO_DATA_DIR:=/workspaces/odoo_source}"
: "${ODOO_COMMUNITY_DIR:=${ODOO_DATA_DIR}/odoo}"
: "${ODOO_ENTERPRISE_DIR:=${ODOO_DATA_DIR}/enterprise}"
: "${ODOO_CUSTOM_ADDONS_DIR:=${ODOO_DATA_DIR}/custom}"
: "${ODOO_FILESTORE_DIR:=${ODOO_DATA_DIR}/filestore}"


# Ensure that development directories exist and have the correct ownership
mkdir -p "${ODOO_DATA_DIR}" "${ODOO_COMMUNITY_DIR}" "${ODOO_ENTERPRISE_DIR}" "${ODOO_FILESTORE_DIR}"

# Workaround: Mount this repository into REPO_DIR first, then create the
# custom addons symlink at the exact target path. -T prevents ln from treating
# an existing destination as a directory and creating a nested custom/custom link.
ln -sfnT "${REPO_DIR}/custom" "${ODOO_CUSTOM_ADDONS_DIR}"

chown -R odoo:odoo "${ODOO_DATA_DIR}"

exec "$@"
