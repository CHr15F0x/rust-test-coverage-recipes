#! /usr/bin/env bash
#
# Based on: https://github.com/mozilla/grcov
#

# Convenience variables
REPORT=coverage-gcov-lcov

function partial_cleanup() {
  find . -name "*.gcno" | xargs rm -f
  find . -name "*.gcda" | xargs rm -f
  rm -f ./${REPORT}*.info
}

function init_cov() {
  # Cleanup files from previous run
  # Just in case there are leftovers
  partial_cleanup
  rm -rf ./${REPORT}
  # Required to use the gcov format (*.gcno, *.gcda)
  export CARGO_INCREMENTAL=0
  export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Copt-level=0 -Clink-dead-code -Coverflow-checks=off -Zpanic_abort_tests -Cpanic=abort"
  export RUSTDOCFLAGS="-Cpanic=abort"
  # Nightly is required for gcov compatible cov instrumentation
  # See https://rust-lang.github.io/rustup/overrides.html#the-toolchain-file
  if [ -f rust-toolchain ]; then
    mv rust-toolchain rust-toolchain.bak
  fi
  echo "nightly" > rust-toolchain
}

function cleanup_cov() {
  # Kill all jobs if any still running, helpful if using SIGINT or like
  [[ -z "$(jobs -p)" ]] || kill $(jobs -p)
  # Cleanup intermediate files
  partial_cleanup
  # Cleanup env variables
  unset CARGO_INCREMENTAL
  unset RUSTFLAGS
  unset RUSTDOCFLAGS
  # Revert to whatever the default toolchain is
  # See https://rust-lang.github.io/rustup/overrides.html#the-toolchain-file
  if [ -f rust-toolchain.bak ]; then
    mv rust-toolchain.bak rust-toolchain
  else
    rm -f rust-toolchain
  fi
  echo "Current toolchain settings:"
  rustup show
}

# Always call cleanup on exit, regardless if errors occur
trap cleanup_cov EXIT

# Set everything up
init_cov

# Run the tests
source run-all-tests.sh

lcov --directory ./target/debug --capture --output-file ${REPORT}-0.info

lcov --extract ${REPORT}-0.info "*$(basename ${PWD})*" -o ${REPORT}-1.info

# Produce a report in HTML format
genhtml \
  --output-directory ${REPORT} \
  --sort \
  --title "My test coverage report" \
  --function-coverage \
  --prefix $(readlink -f "${PWD}/..") \
  --show-details \
  --legend \
  --highlight \
  --ignore-errors source \
  ${REPORT}-1.info
