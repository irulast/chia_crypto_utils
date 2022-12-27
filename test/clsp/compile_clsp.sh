#!/usr/local/bin/bash

cd chia-dev-tools
. ./venv/bin/activate
pip install chia-dev-tools 
cd ..
cdv clsp build $1 -i lib/src/chialisp/include 
deactivate



