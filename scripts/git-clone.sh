#!/usr/bin/env bash
rm -rf "${HOME}/Downloads/meson-build-xpack.git"
git clone \
  --recurse-submodules \
  https://github.com/xpack-dev-tools/meson-build-xpack.git \
  "${HOME}/Downloads/meson-build-xpack.git"
