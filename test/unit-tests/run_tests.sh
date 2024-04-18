#!/bin/bash

source $(dirname "${BASH_SOURCE[0]}")/basic_tests.sh


get_sad_path_conf(){
    SKU=$( curl -H Metadata:true --max-time 10 -s "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2021-01-01&format=text" | tr '[:upper:]' '[:lower:]' | sed 's/standard_//')
    CONF_DIR="$AZ_NHC_ROOT/conf/"
    CONF_FILE="$CONF_DIR/$SKU.conf"
    if [ -e "$CONF_FILE" ]; then
        echo "Running health checks for Standard_$SKU SKU..."
    else
        echo "The vm SKU 'standard_$SKU' is currently not supported by Azure health checks." | tee -a $OUTPUT_PATH
        return 1
    fi

    relative_path="$(dirname "${BASH_SOURCE[0]}")/../bad_test_confs/$CONF_FILE"
    echo "$(realpath -m $relative_path)"
    return 0
}


#happy path
happy_path(){
    echo "Running  ${FUNCNAME[0]} test"
    EXPECTED_CODE=0
    test=$(runtest $EXPECTED_CODE)
    result=$?

    if [ "$result" -eq $EXPECTED_CODE ]; then
        echo "${FUNCNAME[0]} test: Passed"
        return 0
    else
        echo "${FUNCNAME[0]} test: Failed"
        return 1
    fi
}

#sad path
sad_path(){
    echo "Running  ${FUNCNAME[0]} test"
    bad_conf_file=$(get_sad_path_conf)
    if [[ "$bad_conf_file" == *"not supported"* ]]; then
        echo "${FUNCNAME[0]} test: Failed"
        return 1
    fi
    EXPECTED_CODE=1
    test=$(runtest $EXPECTED_CODE "$bad_conf_file")
    result=$?
  
    if [ "$result" -eq 0 ]; then
        echo "${FUNCNAME[0]} test: Passed"
        return 0
    else
        echo "${FUNCNAME[0]} test: Failed"
        return 1
    fi
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <function_name>"
    echo "choices: happy_path, sad_path"
    exit 1
fi

# Determine which function to run based on the argument
if [ "$1" == "happy_path" ]; then
    happy_path
elif [ "$1" == "sad_path" ]; then
    sad_path
else
    echo "Invalid function name: $1"
    exit 1
fi
