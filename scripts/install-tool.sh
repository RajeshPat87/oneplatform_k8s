#!/usr/bin/env bash
# One-time installer for pinned versions of CI/IaC tooling.
# Usage: ./scripts/install-tool.sh <tool> <version>
# Tools: terraform | helm | kubectl | gitleaks | hadolint | trivy | codeql
set -euo pipefail

tool="${1:-}"
version="${2:-}"

if [[ -z "${tool}" || -z "${version}" ]]; then
  echo "usage: $0 <tool> <version>" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

verify_checksum_from_file() {
  local archive_path="$1"
  local archive_name="$2"
  local checksum_file="$3"
  local expected
  expected="$(grep " ${archive_name}\$" "${checksum_file}" | awk '{print $1}')"
  if [[ -z "${expected}" ]]; then
    echo "checksum for ${archive_name} not found in ${checksum_file}" >&2
    exit 1
  fi
  echo "${expected}  ${archive_path}" | sha256sum -c -
}

verify_checksum_from_value() {
  local archive_path="$1"
  local checksum_file="$2"
  local expected
  expected="$(awk '{print $1}' "${checksum_file}")"
  if [[ -z "${expected}" ]]; then
    echo "checksum file ${checksum_file} is empty" >&2
    exit 1
  fi
  echo "${expected}  ${archive_path}" | sha256sum -c -
}

install_binary() {
  local source_path="$1"
  local target_name="$2"
  sudo install "${source_path}" "/usr/local/bin/${target_name}"
}

case "${tool}" in
  terraform)
    archive_name="terraform_${version}_linux_amd64.zip"
    curl -fsSL "https://releases.hashicorp.com/terraform/${version}/${archive_name}" -o "${tmpdir}/terraform.zip"
    curl -fsSL "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_SHA256SUMS" -o "${tmpdir}/terraform_SHA256SUMS"
    verify_checksum_from_file "${tmpdir}/terraform.zip" "${archive_name}" "${tmpdir}/terraform_SHA256SUMS"
    unzip -q "${tmpdir}/terraform.zip" -d "${tmpdir}"
    install_binary "${tmpdir}/terraform" terraform
    ;;
  helm)
    archive_name="helm-v${version}-linux-amd64.tar.gz"
    curl -fsSL "https://get.helm.sh/${archive_name}" -o "${tmpdir}/helm.tar.gz"
    curl -fsSL "https://get.helm.sh/${archive_name}.sha256sum" -o "${tmpdir}/helm.sha256"
    verify_checksum_from_value "${tmpdir}/helm.tar.gz" "${tmpdir}/helm.sha256"
    tar -xzf "${tmpdir}/helm.tar.gz" -C "${tmpdir}"
    install_binary "${tmpdir}/linux-amd64/helm" helm
    ;;
  kubectl)
    curl -fsSL "https://dl.k8s.io/release/v${version}/bin/linux/amd64/kubectl" -o "${tmpdir}/kubectl"
    curl -fsSL "https://dl.k8s.io/release/v${version}/bin/linux/amd64/kubectl.sha256" -o "${tmpdir}/kubectl.sha256"
    verify_checksum_from_value "${tmpdir}/kubectl" "${tmpdir}/kubectl.sha256"
    chmod +x "${tmpdir}/kubectl"
    install_binary "${tmpdir}/kubectl" kubectl
    ;;
  gitleaks)
    archive_name="gitleaks_${version}_linux_x64.tar.gz"
    curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v${version}/${archive_name}" -o "${tmpdir}/gitleaks.tar.gz"
    curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_checksums.txt" -o "${tmpdir}/gitleaks_checksums.txt"
    verify_checksum_from_file "${tmpdir}/gitleaks.tar.gz" "${archive_name}" "${tmpdir}/gitleaks_checksums.txt"
    tar -xzf "${tmpdir}/gitleaks.tar.gz" -C "${tmpdir}"
    install_binary "${tmpdir}/gitleaks" gitleaks
    ;;
  hadolint)
    curl -fsSL "https://github.com/hadolint/hadolint/releases/download/v${version}/hadolint-Linux-x86_64" -o "${tmpdir}/hadolint"
    curl -fsSL "https://github.com/hadolint/hadolint/releases/download/v${version}/hadolint-Linux-x86_64.sha256" -o "${tmpdir}/hadolint.sha256"
    verify_checksum_from_value "${tmpdir}/hadolint" "${tmpdir}/hadolint.sha256"
    chmod +x "${tmpdir}/hadolint"
    install_binary "${tmpdir}/hadolint" hadolint
    ;;
  trivy)
    archive_name="trivy_${version}_Linux-64bit.tar.gz"
    curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/v${version}/${archive_name}" -o "${tmpdir}/trivy.tar.gz"
    curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/v${version}/trivy_${version}_checksums.txt" -o "${tmpdir}/trivy_checksums.txt"
    verify_checksum_from_file "${tmpdir}/trivy.tar.gz" "${archive_name}" "${tmpdir}/trivy_checksums.txt"
    tar -xzf "${tmpdir}/trivy.tar.gz" -C "${tmpdir}" trivy
    install_binary "${tmpdir}/trivy" trivy
    ;;
  codeql)
    codeql_root="/opt/codeql/${version}"
    if [[ ! -x "${codeql_root}/codeql" ]]; then
      curl -fsSL "https://github.com/github/codeql-action/releases/download/codeql-bundle-v${version}/codeql-bundle-linux64.tar.gz" -o "${tmpdir}/codeql.tar.gz"
      curl -fsSL "https://github.com/github/codeql-action/releases/download/codeql-bundle-v${version}/codeql-bundle-linux64.tar.gz.checksum.txt" -o "${tmpdir}/codeql.checksum"
      verify_checksum_from_value "${tmpdir}/codeql.tar.gz" "${tmpdir}/codeql.checksum"
      sudo mkdir -p "${codeql_root}"
      sudo tar -xzf "${tmpdir}/codeql.tar.gz" -C "${codeql_root}" --strip-components=1
    fi
    sudo chmod -R a+rX "${codeql_root}"
    sudo ln -sf "${codeql_root}/codeql" /usr/local/bin/codeql
    ;;
  *)
    echo "unsupported tool: ${tool}" >&2
    exit 1
    ;;
esac
