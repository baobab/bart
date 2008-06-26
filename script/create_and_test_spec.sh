#!/bin/sh
#
# script/create_and_test_spec.sh <model_name>
# e.g.: script/create_and_test_spec.sh patient_address
#
# Creates a BART RSpec model and runs to see if it passes
#

script/generate bart_spec_model $1

echo "script/spec spec/models/$1_spec.rb"

script/spec spec/models/$1_spec.rb

exit
