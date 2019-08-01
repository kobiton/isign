#!/bin/bash

# Figures out what the current version is, echoes that back,
# and also writes a `version.json` file into the package.

set -e
MAJMIN_VERSION="1.5"

# path of package isign have a white space, when run INSTALL.sh script include 'python setup.py'
# 'python setup.py' script has error if setup.py include script import 'version.sh'
# Error log: /../White Space/isign/version.sh: line 9: pushd: no other directory
working_dir=$PWD
name=$(basename "$PWD")
package=$(echo $name | sed 's/-/_/g')
version_json="${working_dir}/${package}/version.json"

version_suffix=""
# official version
if [[ "$JOB_NAME" = "${name}" ]] && [[ -n "$BUILD_TAG" ]]; then
    patch_version=0
    if [[ -n "$(git tag --list v$MAJMIN_VERSION.0)" ]]; then
        # number of commits since vMAJOR.MINOR.0
        patch_version=$(git rev-list --count $(git describe --tags --match "v${MAJMIN_VERSION}.0" | cut -f 1 -d -)...HEAD)
    fi
    # add post version if built before (i.e., already tagged)
    post_version=$(git tag --contain | wc -l | awk '{print $1}')
    test "$post_version" -gt 0 && version_suffix=".post${post_version}"
# development version
else
    if [[ -n "$(git tag --list 'v[0-9]*')" ]]; then
        recent_tag=$(git describe --tags --match 'v[0-9]*' | cut -f 1 -d -)
        majmin_version=$(echo $recent_tag | tr "v.-" " " | awk '{print $1"."$2}')
        patch_version=$(echo $recent_tag | tr "v.-" " " | awk '{print $3}')
        dev_version=$(git rev-list --count ${recent_tag}...HEAD)
    else  # start of dev, nothing tagged
        majmin_version="0.0"
        patch_version="0"
        dev_version=$(git rev-list --count HEAD)
    fi
    version_suffix=".$(date '+%s').dev${dev_version}+${USER}"
fi

version="${majmin_version:-$MAJMIN_VERSION}.${patch_version}${version_suffix}"
json='"version": "'$version'", "commit": "'$(git rev-parse HEAD)'", "build": "'${BUILD_TAG:-"dev"}'"'
# write-out version.json
# add " in front and behind variable is a path to fix path have a white space
echo "{${json}}" > "$version_json"

style="$1"
if [[ "$style" = "json" ]]; then
    cat "$version_json"
else
    echo $version
fi
