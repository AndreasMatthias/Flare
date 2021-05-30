#!/bin/bash

# Installing TeX Live for Travis-CI

export PATH=/tmp/texlive/bin/x86_64-linux:$PATH

# Get TeX Live if not cached already
if ! command -v luatex >/dev/null 2>&1; then
    wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
    tar -xzf install-tl-unx.tar.gz
    cd install-tl-20*
    ./install-tl --profile=../scripts/texlive.profile
    cd ..
fi

# update self
tlmgr update --self

# install packages
tlmgr install \
      luatex \
      luatexbase \
      kvsetkeys \
      etoolbox

# no backups
tlmgr option -- autobackup 0

# update
tlmgr update --all --no-auto-install
