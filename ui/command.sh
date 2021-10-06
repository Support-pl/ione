#!/bin/sh

echo "globalThis.VUE_APP_IONE_API_BASE_URL = '"$VUE_APP_IONE_API_BASE_URL"';" > config.js
thttpd -D -h 0.0.0.0 -p 5000 -d . -u static -l - -M 60
