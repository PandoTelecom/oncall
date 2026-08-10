PLUGIN_ID=pando-oncall-app
VERSION=0.1.0          # pick any version label you want
ARCH=linux-amd64       # or linux-arm64

# If your plugin.json has %VERSION% / %TODAY%, stamp them (optional but nice)
DATE=$(date -u +%Y-%m-%d)
# macOS: use `gsed` if needed; otherwise:
tmp=dist/plugin.new.json
sed "s/%VERSION%/${VERSION}/g; s/%TODAY%/${DATE}/g" dist/plugin.json > "$tmp" && mv "$tmp" dist/plugin.json

# Create the plugin folder and zip it
rm -rf "$PLUGIN_ID"
cp -a dist "$PLUGIN_ID"
zip -r "${PLUGIN_ID}-${VERSION}-${ARCH}.zip" "$PLUGIN_ID"
