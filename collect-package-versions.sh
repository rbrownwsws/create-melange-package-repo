#!/usr/bin/env bash
set -euo pipefail

: "${REPO_DIR:?REPO_DIR must be set}"

# 800MiB
LIMIT_BYTES=838860800

API_BASE="${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/releases"

AUTH_HEADER=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

total_downloaded_bytes=0

per_page=100
page=1
while true; do
  releases_json=$(curl -sSf "${AUTH_HEADER[@]}" \
    "${API_BASE}?per_page=${per_page}&page=${page}")

  mapfile -t releases < <(jq -c '.[]' <<<"${releases_json}")

  if [[ "${#releases[@]}" -eq 0 ]]; then
    break
  fi

  for release in "${releases[@]}"; do
    tag=$(jq -r ".tag_name" <<<"${release}")

    echo "::group::Release '${tag}'"

    assets_json=$(jq '[.assets[] | { name: .name, size: .size, url: .browser_download_url }]' <<<"${release}")

    packages_json=$(jq '[.[] | select(.name | endswith(".apk"))]' <<<"${assets_json}")
    attests_json=$(jq '[.[] | select(.name | endswith(".sigstore.json"))]' <<<"${assets_json}")

    packages_count=$(jq 'length' <<<"${packages_json}")
    attests_count=$(jq 'length' <<<"${attests_json}")

    packages_size_bytes=$(jq '[.[] | .size] | add // 0' <<<"${packages_json}")
    attests_size_bytes=$(jq '[.[] | .size] | add // 0' <<<"${attests_json}")
    release_size_bytes=$((packages_size_bytes + attests_size_bytes))

    echo "This release contains:"
    echo "${packages_count} packages (${packages_size_bytes} bytes)"
    echo "${attests_count} attests (${attests_size_bytes} bytes)"
    echo "Total: ${release_size_bytes} bytes"

    potential_downloaded_bytes=$((total_downloaded_bytes + release_size_bytes))

    if [[ "${potential_downloaded_bytes}" -gt "${LIMIT_BYTES}" ]]; then
      echo ""
      echo "Stopping: release '${tag}' would take us $((potential_downloaded_bytes - LIMIT_BYTES)) bytes over the repo size limit"
      exit 0
    fi

    mapfile -t packages < <(jq -c '.[]' <<<"${packages_json}")

    for package in "${packages[@]}"; do
      package_filename=$(jq -r '.name' <<<"${package}")
      package_url=$(jq -r '.url' <<<"${package}")

      echo ""
      echo "${package_filename}:"

      if [[ ! "${package_filename}" =~ ^(.+)-([^-]+)-r([0-9]+)-([^-]+)-([^-]+).apk$ ]]; then
          echo "::error::Failed to parse package filename: ${package_filename}"
          exit 1
      fi

      package_name="${BASH_REMATCH[1]}"
      package_version="${BASH_REMATCH[2]}"
      package_epoch="${BASH_REMATCH[3]}"
      package_distro="${BASH_REMATCH[4]}"
      package_arch="${BASH_REMATCH[5]}"

      # TODO: What do we do with distro? Error out if not what we expect?

      repo_package_filename="${package_name}-${package_version}-r${package_epoch}.apk"

      target_dir="${REPO_DIR}/${package_arch}"
      mkdir -p "${target_dir}"

      echo "  - Downloading \"${package_filename}\" ..."
      curl -sSfL "${AUTH_HEADER[@]}" -o "${target_dir}/${repo_package_filename}" "${package_url}"

      mapfile -t attests < <(jq -c --arg prefix "${package_filename}" '.[] | select(.name | startswith($prefix))' <<<"${attests_json}")
      for attest in "${attests[@]}"; do
        attest_filename=$(jq -r '.name' <<<"${attest}")
        attest_url=$(jq -r '.url' <<<"${attest}")

        if [[ ! "${attest_filename}" =~ ^${package_filename}(.*)\.sigstore.json$ ]]; then
          echo "::error::Failed to parse attest filename: ${attest_filename}"
          exit 1
        fi

        attest_qualifier="${BASH_REMATCH[1]}"

        echo "  - Downloading \"${attest_filename}\" ..."
        curl -sSfL "${AUTH_HEADER[@]}" -o "${target_dir}/${repo_package_filename}${attest_qualifier}.sigstore.json" "${attest_url}"
      done
    done

    total_downloaded_bytes="${potential_downloaded_bytes}"

    echo "::endgroup::"
  done

  page=$((page + 1))
done

echo ""
echo "No more releases available"
