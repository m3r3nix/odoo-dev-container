#!/usr/bin/env bash

set -euo pipefail

: "${ODOO_BRANCH:=19.0}"
: "${ODOO_DATA_DIR:=/workspaces/odoo_source}"
: "${ODOO_COMMUNITY_DIR:=${ODOO_DATA_DIR}/odoo}"
: "${ODOO_ENTERPRISE_DIR:=${ODOO_DATA_DIR}/enterprise}"


enterprise_subscription() {
    local reply

    if [ ! -t 0 ]; then
        echo "Odoo Enterprise repository is not cloned and no interactive terminal is available." >&2
        echo "Skipping Odoo Enterprise clone." >&2
        return 1
    fi

    while true; do
        echo
        read -r -p "Do you have an Odoo Enterprise subscription? [y/N] " reply

        case "${reply}" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            ""|[Nn]|[Nn][Oo])
                echo -e "\nSkipping Odoo Enterprise clone."
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

github_cli_auth() {
    local reply

    if [ ! -t 0 ]; then
        echo "GitHub CLI authentication is required to access the private Odoo Enterprise repository, but no interactive terminal is available." >&2
        return 1
    fi

    while true; do
        read -r -p "Do you want to authenticate with GitHub CLI now? [Y/n] " reply

        case "${reply}" in
            ""|[Yy]|[Yy][Ee][Ss])
                if [ -n "${GITHUB_TOKEN:-}" ]; then
                    echo -e "\nWARNING: GITHUB_TOKEN environment variable is set. To continue, please unset GITHUB_TOKEN and GH_TOKEN by running the following command, then run this script again. This is a requirement for GitHub CLI authentication:\n"
                    echo -e "unset GITHUB_TOKEN GH_TOKEN\n"
                    exit 1
                fi
                gh auth login --hostname github.com --git-protocol https
                gh auth setup-git
                return 0
                ;;
            [Nn]|[Nn][Oo])
                echo -e "\nSkipping GitHub CLI authentication."
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

enterprise_repo_access() {
    if [ -z "${CODESPACES:-}" ]; then
        return 0
    fi

    if ! command -v gh >/dev/null 2>&1; then
        echo "GitHub CLI is not installed in this container." >&2
        echo "Rebuild the dev container and try again." >&2
        return 1
    fi

    if gh repo view odoo/enterprise >/dev/null 2>&1; then
        return 0
    fi

    echo
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!!  GitHub Codespaces environment detected.  !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo
    echo "The default Codespace access token is not sufficient to access the private Odoo Enterprise repository."
    echo -e "We have to authenticate with GitHub CLI to get a token with the necessary scopes.\n"

    github_cli_auth
}

if [ ! -d "${ODOO_COMMUNITY_DIR}/.git" ]; then
    echo -e "\nWaiting for Odoo Community source checkout at ${ODOO_COMMUNITY_DIR}...\n"
    git clone --depth 1 --branch "${ODOO_BRANCH}" --single-branch https://github.com/odoo/odoo.git "${ODOO_COMMUNITY_DIR}"
else
    cd "${ODOO_COMMUNITY_DIR}"
    echo -e "\nUpdating Odoo Community source at ${ODOO_COMMUNITY_DIR}...\n"
    git pull origin "${ODOO_BRANCH}"
fi

if [ ! -d "${ODOO_ENTERPRISE_DIR}/.git" ]; then
    if enterprise_subscription; then
        if ! enterprise_repo_access; then
            echo -e "\nSkipping Odoo Enterprise clone."
        else
            echo -e "\nWaiting for Odoo Enterprise source checkout at ${ODOO_ENTERPRISE_DIR}...\n"
            git clone --depth 1 --branch "${ODOO_BRANCH}" --single-branch https://github.com/odoo/enterprise.git "${ODOO_ENTERPRISE_DIR}"
        fi
    fi
else
    cd "${ODOO_ENTERPRISE_DIR}"
    if ! enterprise_repo_access; then
        echo -e "\nSkipping Odoo Enterprise update."
    else
        echo -e "\nUpdating Odoo Enterprise source at ${ODOO_ENTERPRISE_DIR}...\n"
        git pull origin "${ODOO_BRANCH}"
    fi
fi

echo -e "\nSource update complete.\n"

echo "Restarting Odoo service to apply changes..."
supervisorctl restart odoo
