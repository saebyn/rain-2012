#!/bin/sh
mkdir -p ../src/assets
cp -r sprites ../src/assets/
./levels/build_all.py
