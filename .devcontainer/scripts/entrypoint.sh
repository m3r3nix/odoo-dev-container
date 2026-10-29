#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=odoo-paths.sh
source "${SCRIPT_DIR}/odoo-paths.sh"

: "${ODOO_RC:=/etc/odoo/odoo.conf}"


render_odoo_config() {
    local config_template="$1"
    local config_content
    local rendered_config

    rendered_config="$(mktemp)"
    config_content="$(<"${config_template}")"

    # Expand only the supported path variables. Other dollar-containing values,
    # such as password hashes, must remain unchanged.
    config_content="${config_content//\$ODOO_CUSTOM_ADDONS_DIR/${ODOO_CUSTOM_ADDONS_DIR}}"
    config_content="${config_content//\$ODOO_ENTERPRISE_DIR/${ODOO_ENTERPRISE_DIR}}"
    config_content="${config_content//\$ODOO_COMMUNITY_DIR/${ODOO_COMMUNITY_DIR}}"
    config_content="${config_content//\$ODOO_FILESTORE_DIR/${ODOO_FILESTORE_DIR}}"
    printf '%s\n' "${config_content}" > "${rendered_config}"

    if grep -Eq '\$ODOO_[A-Z0-9_]+' "${rendered_config}"; then
        echo "Refusing to start with unresolved Odoo variables in ${config_template}." >&2
        rm -f "${rendered_config}"
        return 1
    fi

    if ! install -o odoo -g odoo -m 0644 "${rendered_config}" "${ODOO_RC}"; then
        rm -f "${rendered_config}"
        return 1
    fi
    rm -f "${rendered_config}"
}


# Keep the repository config immutable while rendering a safe runtime config.
if [ -f /tmp/odoo.conf.template ]; then
    render_odoo_config /tmp/odoo.conf.template
else
    render_odoo_config "${ODOO_RC}"
fi


# Ensure that development directories exist and have the correct ownership
mkdir -p "${ODOO_SOURCES_DIR}" "${ODOO_COMMUNITY_DIR}" "${ODOO_ENTERPRISE_DIR}" "${ODOO_FILESTORE_DIR}"

# Workaround: Mount this repository into REPO_DIR first, then create the
# custom addons symlink at the exact target path. -T prevents ln from treating
# an existing destination as a directory and creating a nested custom/custom link.
ln -sfnT "${REPO_DIR}/custom" "${ODOO_CUSTOM_ADDONS_DIR}"

chown -R odoo:odoo "${ODOO_SOURCES_DIR}"

exec "$@"
