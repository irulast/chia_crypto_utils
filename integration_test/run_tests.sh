#!/usr/bin/env bash

function start_simulator() {
  docker compose -f lib/src/api/full_node/simulator/run/docker-compose.enhanced.yml up --wait -d --force-recreate

  # sometimes the first test will fail if run immediately after the simulator healthcheck passes, so wait 3 seconds
  sleep 3
}


function stop_simulator() {
  docker ps --filter ancestor=run-simulator --filter status=running -aq | xargs docker stop
}

current_dir=integration_test/*

# recursively runs flutter test on all subdirectories with no files in integration_test directory
function test_subdirectories() {
  for dir in $(find $current_dir -maxdepth 1 -type d)

    do
      name=$(basename $dir)
 
      # tests must be run in smaller chunks because the simulator starts to cause timeout failures if it is used too intensively, 
      # so simulator must be restarted intermittently 

      # flutter test won't work when run on an individual test file in a Dart project, so if subdirectory has files, restart simulator  
      # and run flutter test on subdirectory, else recursively call function on subdirectory
      if [[ $(find $dir -maxdepth 1 -type f | wc -c) -ne 0 ]]
        then
          start_simulator

          echo "running tests in $name"

          flutter test -d linux ./$dir --coverage --coverage-path=coverage/${name}_lcov.info 

          stop_simulator
        else
          current_dir=$dir/*
          test_subdirectories
      fi
    done
}

test_subdirectories

# merge coverage files
printf -- '-add-tracefile\0%s\0' coverage/*.info | xargs -0 lcov --output-file coverage/integration_test.info 
rm -rf coverage/*lcov.info