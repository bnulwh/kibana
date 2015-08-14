#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )

tags="$(git ls-remote --tags https://github.com/elastic/kibana.git | cut -d/ -f3 | cut -d^ -f1 | cut -dv -f2 | grep -vE 'milestone|-beta|-m' | sort -rV)"

travisEnv=
for version in "${versions[@]}"; do
	fullVersion="$(echo "$tags" | grep -m1 "^$version.")"
	sha1="$(curl -fsSL "https://download.elastic.co/kibana/kibana/kibana-$fullVersion-linux-x64.tar.gz.sha1.txt" | cut -d' ' -f1)"

	(
		set -x
		sed -ri '
			s/^(ENV KIBANA_VERSION) .*/\1 '"$fullVersion"'/;
			s/^(ENV KIBANA_SHA1) .*/\1 '"$sha1"'/;
		' "$version/Dockerfile"
	)

	travisEnv='\n  - VERSION='"$version$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
