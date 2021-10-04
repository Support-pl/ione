#!/bin/bash

cd /app
echo "globalThis.VUE_APP_IONE_API_BASE_URL = '"$VUE_APP_IONE_API_BASE_URL"';" > ./dist/config.js
serve -s dist
