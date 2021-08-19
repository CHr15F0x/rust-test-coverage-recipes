#! /usr/bin/env bash
#
# Based on: https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html
#

# Convenience variables
REPORT=coverage-llvm-lcov

function partial_cleanup() {
  find . -name "*.profraw" | xargs rm -f
  rm -f ./all.profdata
  rm -f ./${REPORT}.info
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
  # Nightly is required for llvm
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

# Merge raw prof data into one
llvm-profdata merge --sparse `find . -name "*.profraw" -printf "%p "` -o all.profdata

# Figure out paths of all binaries ran while testing - naive way, but works
# Compare with: https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html#tips-for-listing-the-binaries-automatically
# which required building the binaries first, and that forced a different build order than the original order enforced by the tests
BINS_RAW=$(find ./target/debug/ -executable -type "f" -path "*target/debug*" -not -name "*.*" -not -name "build*script*")

BINS=$(for file in ${BINS_RAW}; do printf "%s %s " -object $file; done)

# Export prof data to a more universal format (lcov)
llvm-cov export --format=lcov -Xdemangler=rustfilt ${BINS} \
  --instr-profile=all.profdata \
  --ignore-filename-regex='/rustc' --ignore-filename-regex='/.cargo/registry' \
  > ${REPORT}.info

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
  ${REPORT}.info  
