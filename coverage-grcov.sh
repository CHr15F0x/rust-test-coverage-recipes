#! /usr/bin/env bash
#
# Based on: https://github.com/mozilla/grcov
#

# Convenience variables
REPORT=coverage-llvm-grcov

function partial_cleanup() {
  find . -name "*.profraw" | xargs rm -f
  rm -f ./${REPORT}.info
  rm -f ./${REPORT}-lcov.info
}

function init_cov() {
  # Cleanup files from previous run
  # Just in case there are leftovers
  partial_cleanup
  rm -rf ./${REPORT}
  # LLVM cov works only with the following
  export RUSTFLAGS="-Z instrument-coverage"
  # Certain test runs could overwrite each others raw prof data
  # See https://clang.llvm.org/docs/SourceBasedCodeCoverage.html#id4 for explanation of %p and %m 
  export LLVM_PROFILE_FILE="cov-%p-%m.profraw"
  # Nightly is required for grcov
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
  unset RUSTFLAGS
  unset LLVM_PROFILE_FILE
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

# Use grcov's html generation capability
grcov . -s . --binary-path ./target/debug/ --llvm -t html --ignore-not-existing --ignore '*/rustc*' --ignore '*/.cargo/registry*' -o ./${REPORT}

# Use lcov's genhtml
grcov . -s . --binary-path ./target/debug/ --llvm -t lcov --ignore-not-existing --ignore '*/rustc*' --ignore '*/.cargo/registry*' -o ./${REPORT}-lcov.info

# Produce a report in HTML format
genhtml \
  --output-directory ${REPORT}-lcov \
  --sort \
  --title "My test coverage report" \
  --function-coverage \
  --prefix $(readlink -f "${PWD}/..") \
  --show-details \
  --legend \
  --highlight \
  --ignore-errors source \
  ${REPORT}-lcov.info
