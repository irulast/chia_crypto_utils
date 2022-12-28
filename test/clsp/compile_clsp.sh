#!/usr/local/bin/bash

TEST_DIR="test/clsp/"

cp ./"$1" ./"$TEST_DIR"

BASENAME=$(basename $1)

TEST_FILE="$TEST_DIR$BASENAME"

cd chia-dev-tools
. ./venv/bin/activate
pip install chia-dev-tools 
cd ..
cdv clsp build $TEST_FILE -i lib/src/chialisp/base 
deactivate

EXTENSION='.hex'
HEX_FILE="$TEST_FILE$EXTENSION"
HEX=$(cat $HEX_FILE)

HEX_TO_CHECK=$(cat $2)

rm $TEST_FILE
rm $HEX_FILE

if [ "$HEX" = "$HEX_TO_CHECK" ]
then
  exit 0
else
  exit 1
fi

