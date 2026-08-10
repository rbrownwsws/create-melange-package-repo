#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${SIGNING_KEY:-}" && -z "${SIGNING_KEY_NAME:-}" ]]; then
  echo "::error::You provided 'signing-key' but did not provide 'signing-key-name'" >&2
  exit 1
fi

if [[ -n "${SIGNING_KEY_NAME:-}" && -z "${SIGNING_KEY:-}" ]]; then
  echo "::error::You provided 'signing-key-name' but did not provide 'signing-key'" >&2
  exit 1
fi

REPO_DIR=$(realpath "$REPO_DIR")

echo "Creating indexes for repo at ${REPO_DIR}"

SIGNING_ARGS=()
if [[ -n "${SIGNING_KEY:-}" ]]; then
  echo "::notice::The package index will be signed with \"${SIGNING_KEY_NAME}\""

  # Get a temporary dir to store the private signing key
  SIGNING_KEY_DIR=$(mktemp -d --tmpdir="${RUNNER_TEMP}")
  SIGNING_KEY_FILE="${SIGNING_KEY_DIR}/${SIGNING_KEY_NAME}.rsa"

  # Make sure we delete the private signing key file at the end of this step
  trap 'rm -rf "${SIGNING_KEY_DIR}"' EXIT

  # Put the private signing key into a file
  touch "${SIGNING_KEY_FILE}"
  chmod 600 "${SIGNING_KEY_FILE}"
  printf '%s' "${SIGNING_KEY}" > "${SIGNING_KEY_FILE}"

  # Store the public signing key in the repo root
  openssl rsa -in "${SIGNING_KEY_FILE}" -pubout -out "${REPO_DIR}/${SIGNING_KEY_NAME}.rsa.pub"

  SIGNING_ARGS=("--signing-key=${SIGNING_KEY_FILE}")
else
  echo "::notice::The package index will not be signed"
fi

for ARCH_DIR in "${REPO_DIR}"/*; do
  if [[ ! -d "${ARCH_DIR}" ]]; then
    continue
  fi

  ARCH=$(basename "${ARCH_DIR}")

  echo ""
  echo "::group::Indexing arch '${ARCH}'"

  melange \
    index \
    "${SIGNING_ARGS[@]}" \
    -o "${ARCH_DIR}/APKINDEX.tar.gz" \
    "${ARCH_DIR}"/*.apk

  echo "::endgroup::"
done
