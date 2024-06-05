#!/usr/bin/env bash
set -e
package_name=""
TERRAFORM_DOWNLOAD_LOC=$HOME/terraform

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

# runs the given command as root (detects if we are root already)
runAsRoot() {
  if [ $EUID -ne 0 -a "$USE_SUDO" = "true" ]; then
    sudo "${@}"
  else
    "${@}"
  fi
}

# either curl or wget should have been installed
client=""
if command_exists curl; then
  client="curl -sSL -o"
elif command_exists wget; then
  client="wget -qO"
else
    echo >&2 'Error: this installer needs the ability to run wget or curl.'
    echo >&2 'We are unable to find either "wget" or "curl" available to make this happen.'
    exit 1
fi

#user=""
#if [ "$user" != 'root' ]; then
#  if command_exists sudo; then
#    user="sudo"
#  elif command_exists su; then
#    user='su -c'
#  else
#    echo >&2 'Error: this installer needs the ability to run commands as root.'
#    echo >&2 'We are unable to find either "sudo" or "su" available to make this happen.'
#    exit 1
#  fi
#fi

current_version=$(curl --silent https://checkpoint-api.hashicorp.com/v1/check/terraform | python3 -m json.tool | grep current_version | cut -f 2 -d :| cut -f 2 -d '"')

platform=""
# perform platform check
case "$(uname)" in
  Linux)
    platform="linux"
    ;;
  Darwin)
    platform="darwin"
    ;;
  WindowsNT)
    platform="windows"
    ;;
  FreeBSD)
    platform="freebsd"
    ;;
  *)
    cat >&2 <<'EOF'

  Either your platform is not easily detectable or is not supported by this
  installer script.
EOF
    exit 1
esac

processor=""
# perform processor architecture check
case "$(uname -m)" in
  arm64|aarch64)
    # valid package name for darwin, and linux
    if [ "$platform" != "darwin" ] && [ "$platform" != "linux" ]; then
      echo echo >&2 'Error: arm64 package is available for Darwin and Linux platforms only.'
      exit 1
    fi
    processor="arm64"
    ;;
  amd64|x86_64)
    # valid package name for darwin, linux, windows, freebsd, solaris and openbsd
    case "$platform" in
    linux|darwin|windows|freebsd)
    processor="amd64"
      ;;
    *)
      echo echo >&2 'Error: amd64 package is available for Darwin, Linux, Windows and FreeBSD platforms only.'
      exit 1
      ;;
    esac
    ;;
  arm)
    # valid package name for linux and freebsd
    if [ "$platform" != "linux" ] && [ "$platform" != "freebsd" ]; then
      echo echo >&2 'Error: arm package is available for Linux and FreeBSD platforms only.'
      exit 1
    fi
    processor="arm"
    ;;
  *386)
    # valid package name for linux, windows freebsd and openbsd
    case "$platform" in
    linux|windows|freebsd|openbsd)
    processor="386"
      ;;
    *)
      echo echo >&2 'Error: amd64 package is available for Darwin, Linux, Windows and FreeBSD platforms only.'
      exit 1
      ;;
    esac
    ;;
  *)
    echo >&2 'Error: you are not using a 64bit platform.'
    echo >&2 'Functions CLI currently only supports 64bit platforms.'
    exit 1
    ;;
esac

package_name="terraform_${current_version}_${platform}_${processor}.zip"
url=https://releases.hashicorp.com/terraform/"${current_version}"/"${package_name}"
mkdir -p "${TERRAFORM_DOWNLOAD_LOC}"
$client "${TERRAFORM_DOWNLOAD_LOC}/${package_name}" "${url}"
runAsRoot unzip -qq "${TERRAFORM_DOWNLOAD_LOC}"/"${package_name}" -d /usr/local/bin
runAsRoot rm -r "${TERRAFORM_DOWNLOAD_LOC}"

echo "Terraform installed successfully"
cat >&2 <<'EOF'
                         _   _
                        | | | | __ _ _ __  _ __  _   _
                        | |_| |/ _` | '_ \| '_ \| | | |
                        |  _  | (_| | |_) | |_) | |_| |
                        |_| |_|\__,_| .__/| .__/ \__, |
                                    |_|   |_|    |___/
                _____                    __
               |_   _|__ _ __ _ __ __ _ / _| ___  _ __ _ __ ___
                 | |/ _ \ '__| '__/ _` | |_ / _ \| '__| '_ ` _ \
                 | |  __/ |  | | | (_| |  _| (_) | |  | | | | | |
                 |_|\___|_|  |_|  \__,_|_|  \___/|_|  |_| |_| |_|

EOF
exit 0
