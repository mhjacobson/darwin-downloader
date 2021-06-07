#!/bin/sh

# darwin-downloader.sh
# usage: darwin-downloader.sh <project-name>
# creates a git repository in ./<project-name>
# author: Matt Jacobson

set -e
# set -x

PROJNAME=$1

# Set up a bare repository.
GIT_DIR="${PROJNAME}"/.git
export GIT_DIR

mkdir "${PROJNAME}"
mkdir "${GIT_DIR}"
git init --bare "${GIT_DIR}"

# Fetch the list of versions.
VERSIONS=`curl "https://opensource.apple.com/source/${PROJNAME}/" | sed -nE 's/^.*<a href="?'"${PROJNAME}"'-([0-9\.]+)\/?"?>.*$/\1/p' | sort -n`

for VERSION in ${VERSIONS}; do
	EXTRACT_DIR=`mktemp -d`

	# Download and extract the tarball.  Be resilient to corrupt tarballs, which Apple sadly has some of.
	URL="https://opensource.apple.com/tarballs/${PROJNAME}/${PROJNAME}-${VERSION}.tar.gz"
	if curl "${URL}" | tar xC "${EXTRACT_DIR}"; then
		# Copy our extracted files into the index.
		export GIT_WORK_TREE="${EXTRACT_DIR}/${PROJNAME}-${VERSION}"
		git add .

		export GIT_AUTHOR_NAME="Apple"
		export GIT_AUTHOR_EMAIL="sjobs@next.com"
		export GIT_AUTHOR_DATE=`curl -I "${URL}" | fgrep Last-Modified | cut -c 16-`

		git commit -m "${PROJNAME}-${VERSION}"

		# Clean up.
		export -n GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_AUTHOR_DATE
		export -n GIT_WORK_TREE
	fi

	rm -r "${EXTRACT_DIR}"
done

# De-bare our repository.
git config --local --bool core.bare false
GIT_WORK_TREE="${PROJNAME}" git checkout -- .