#!/bin/bash

DIR=$1

APP="lolcow"
VER="v0.1.0"
IMAGE="oras://docker.io/godlovedc/lolcow:sif"
BINDPATH=""

# Check if Apptainer is installed
if ! command -v apptainer >/dev/null 2>&1; then
  echo "Cannot find Apptainer. Please install apptainer and try again. Exiting."
  exit 1
fi

# Check if a directory exists and is empty
if [ ! -d "$DIR" ]; then
  echo "$DIR does not exist. Please select an existing directory. Exiting."
  exit 2
elif [ "$(ls -A "$DIR")" ]; then
  echo "$DIR is not empty. Exiting."
  exit 3
fi

echo "Proceeding with installation in ${DIR}..."

# Create application directories
APPDIR="$DIR/$APP/$VER"
mkdir -p "$APPDIR/bin" "$APPDIR/libexec" "$APPDIR/src"
if [ $? -ne 0 ]; then
  echo "Failed to create application directories. Exiting."
  exit 4
fi

# Download the image
echo "Downloading the image..."
apptainer pull --name "$APPDIR/libexec/app.sif" "$IMAGE"
if [ $? -ne 0 ] || [ ! -f "$APPDIR/libexec/app.sif" ]; then
  echo "Failed to download the image. Exiting."
  exit 5
fi

# Extract def file and place in src directory
echo "Extracting def file..."
apptainer inspect --deffile "$APPDIR/libexec/app.sif" > "$APPDIR/src/app.def"
if [ $? -ne 0 ]; then
  echo "Failed to extract def file. Exiting."
  exit 6
fi

# Create the wrapper script to translate commands to Apptainer calls
echo "Creating wrapper script..."
cat >"$APPDIR/libexec/wrapper.sh"<<"EOF"
#!/bin/bash
EOF
cat >>"$APPDIR/libexec/wrapper.sh"<<EOF
export APPTAINER_BINDPATH="${BINDPATH}"
EOF
cat >>"$APPDIR/libexec/wrapper.sh"<<"EOF"
cmd=$(basename "$0")
dir="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
img="app.sif"
apptainer exec "${dir}/${img}" $cmd "$@"
EOF
chmod +x "$APPDIR/libexec/wrapper.sh"
if [ $? -ne 0 ] || [ ! -x "$APPDIR/libexec/wrapper.sh" ]; then
  echo "Failed to create wrapper script. Exiting."
  exit 7
fi

# Create symlink in bin directory
echo "Creating symlink in bin directory..."
ln -s "../libexec/wrapper.sh" "$APPDIR/bin/fortune"
ln -s "../libexec/wrapper.sh" "$APPDIR/bin/cowsay"
ln -s "../libexec/wrapper.sh" "$APPDIR/bin/lolcat"
for cmd in fortune cowsay lolcat; do
  if [ ! -x "$APPDIR/bin/$cmd" ]; then
    echo "Failed to create symlink for $cmd. Exiting."
    exit 8
  fi
done