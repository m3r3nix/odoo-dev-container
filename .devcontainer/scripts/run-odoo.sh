#!/usr/bin/env bash

set -euo pipefail

: "${ODOO_BRANCH:=19.0}"
: "${ODOO_DB_HOST:=db}"
: "${ODOO_DB_PORT:=5432}"
: "${ODOO_DB_USER:=odoo}"
: "${ODOO_DB_PASSWORD:=odoo}"
: "${ODOO_DB_WAIT_DB:=postgres}"
: "${ODOO_DATA_DIR:=/workspaces/odoo_source}"
: "${ODOO_COMMUNITY_DIR:=${ODOO_DATA_DIR}/odoo}"
: "${ODOO_ENTERPRISE_DIR:=${ODOO_DATA_DIR}/enterprise}"
: "${ODOO_CUSTOM_ADDONS_DIR:=${ODOO_DATA_DIR}/custom}"
: "${ODOO_FILESTORE_DIR:=${ODOO_DATA_DIR}/filestore}"
: "${ODOO_PIP_STAMP_DIR:=/home/odoo/.local/share/odoo}"
: "${ODOO_RC:=/etc/odoo/odoo.conf}"
: "${ODOO_EXTRA_ARGS:=}"


# Ensure that the HOME environment variable is set correctly for the current process,
# otherwise "pip install --user" will fail to install requirements.txt for our custom addons.
ensure_user_environment() {
    local current_user
    local home_dir

    current_user="$(id -un)"
    home_dir="$(getent passwd "${current_user}" | cut -d: -f6)"

    if [ -n "${home_dir}" ] && [ "${HOME:-}" != "${home_dir}" ]; then
        export HOME="${home_dir}"
    fi

    export PATH="${HOME}/.local/bin:${PATH}"
}

wait_for_source() {
    if [ ! -f "${ODOO_COMMUNITY_DIR}/odoo-bin" ]; then
        echo "Waiting for Odoo Community source checkout at ${ODOO_COMMUNITY_DIR}..."
        git clone --depth 1 --branch "${ODOO_BRANCH}" --single-branch https://github.com/odoo/odoo.git "${ODOO_COMMUNITY_DIR}"
    fi
}

ensure_python_deps() {
    local requirements_file="${ODOO_CUSTOM_ADDONS_DIR}/requirements.txt"
    local stamp_file="${ODOO_PIP_STAMP_DIR}/requirements.sha256"
    local current_hash
    local previous_hash

    mkdir -p "${ODOO_PIP_STAMP_DIR}"

    if [ -f "${requirements_file}" ]; then
        current_hash="$(sha256sum "${requirements_file}" | awk '{print $1}')"
        previous_hash="$(cat "${stamp_file}" 2>/dev/null || true)"

        if [ "${current_hash}" != "${previous_hash}" ]; then
            echo "Installing your custom Python requirements from ${requirements_file}..."
            python3 -m pip install --user --upgrade --no-cache-dir -r "${requirements_file}"
            printf '%s\n' "${current_hash}" > "${stamp_file}"
        fi
    fi
}

wait_for_postgres() {
    until PGPASSWORD="${ODOO_DB_PASSWORD}" pg_isready \
        --host="${ODOO_DB_HOST}" \
        --port="${ODOO_DB_PORT}" \
        --dbname="${ODOO_DB_WAIT_DB}" \
        --username="${ODOO_DB_USER}" >/dev/null 2>&1; do
        echo "Waiting for PostgreSQL at ${ODOO_DB_HOST}:${ODOO_DB_PORT}..."
        sleep 2
    done
}

main() {
    local cmd=(
        python3
        "${ODOO_COMMUNITY_DIR}/odoo-bin"
        "--config=${ODOO_RC}"
        "--db_host=${ODOO_DB_HOST}"
        "--db_port=${ODOO_DB_PORT}"
        "--db_user=${ODOO_DB_USER}"
        "--db_password=${ODOO_DB_PASSWORD}"
    )

    ensure_user_environment
    wait_for_source
    ensure_python_deps
    wait_for_postgres

    if [ -n "${ODOO_EXTRA_ARGS}" ]; then
        # Split extra CLI arguments exactly once at the env boundary.
        # shellcheck disable=SC2206
        local extra_args=( ${ODOO_EXTRA_ARGS} )
        cmd+=( "${extra_args[@]}" )
    fi

    echo "Starting Odoo from ${ODOO_COMMUNITY_DIR}..."
    exec "${cmd[@]}"
}

main "$@"
