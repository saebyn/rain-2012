#!/bin/sh

# ensure that the output directory for assets exists
mkdir -p ../src/assets

# copy in external assets
if [ -d ../../rain-assets/assets ]; then
    cp -ru ../../rain-assets/assets/* .
fi

# copy sprites into output directory
cp -r sprites ../src/assets/

# compile levels
./levels/build_all.py
