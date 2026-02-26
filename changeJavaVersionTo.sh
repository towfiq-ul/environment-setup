#!/bin/bash

# Load SDKMAN if not already loaded
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "Error: SDKMAN not found!"
  exit 1
fi

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <java_version>"
  echo "Supported versions: 11, 17, 21"
  exit 1
fi

JAVA_VERSION=$1

# Validate the version
if [[ "$JAVA_VERSION" != "11" && "$JAVA_VERSION" != "17" && "$JAVA_VERSION" != "21" ]]; then
  echo "Error: Unsupported Java version '$JAVA_VERSION'. Only 11, 17, or 21 are allowed."
  exit 1
fi

echo "Looking up latest Java $JAVA_VERSION (amzn) from SDKMAN..."

# Find the latest amzn build for the requested major version from sdk list java
# sdk list java outputs lines like: | Amazon  |     | 21.0.5          | amzn    | installed  | 21.0.5-amzn
LATEST_VERSION=$(sdk list java 2>/dev/null \
  | grep -E "^\s*\|.*\|\s*${JAVA_VERSION}\.[0-9.]+" \
  | grep "amzn" \
  | awk -F'|' '{print $6}' \
  | tr -d ' ' \
  | grep "^${JAVA_VERSION}\." \
  | sort -t. -k1,1n -k2,2n -k3,3n \
  | tail -1)

if [ -z "$LATEST_VERSION" ]; then
  echo "Error: Could not find a Java $JAVA_VERSION amzn version in SDKMAN list."
  echo "Try running 'sdk list java' manually to check available versions."
  exit 1
fi

echo "Latest Java $JAVA_VERSION found: $LATEST_VERSION"

# Define the path to the .sdkmanrc file
SDKMANRC_FILE="$HOME/.sdkmanrc"

if [ ! -f "$SDKMANRC_FILE" ]; then
  echo "Error: $SDKMANRC_FILE file not found!"
  exit 1
fi

# Install the version if not already installed
if sdk list java 2>/dev/null | grep "$LATEST_VERSION" | grep -q "installed"; then
  echo "Java $LATEST_VERSION is already installed."
else
  echo "Installing Java $LATEST_VERSION..."
  sdk install java "$LATEST_VERSION"
fi

# Update .sdkmanrc: comment out any active java= line, then set the new one
sed -i.bak -E "s/^(java=)/#\1/" "$SDKMANRC_FILE"

# Remove any previously commented+re-added duplicate for this version, then append
grep -qE "^java=${LATEST_VERSION}" "$SDKMANRC_FILE" || echo "java=${LATEST_VERSION}" >> "$SDKMANRC_FILE"

echo "Java version set to $LATEST_VERSION in $SDKMANRC_FILE"

# Apply via sdk env install
sdk env install

# Set as default
sdk default java "$LATEST_VERSION"

echo ""
echo "Current Java Compiler Version:"
javac --version

echo ""
echo "Done! Java $LATEST_VERSION is now active and set as default."