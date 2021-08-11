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

# Cleanup files from previous run
# Just in case there are leftovers
partial_cleanup
rm -rf ./${REPORT}

# What happens next is a delicate matter, so:
cargo clean

# LLVM cov works only with the following
export RUSTFLAGS="-Z instrument-coverage"
# Certain test runs could overwrite each others raw prof data
# See https://clang.llvm.org/docs/SourceBasedCodeCoverage.html#id4 for explanation of %p and %m 
export LLVM_PROFILE_FILE="cov-%p-%m.profraw"

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

# Partial cleanup files from this run, at least the most prolific ones
partial_cleanup

# Cleanup state
unset RUSTFLAGS
unset LLVM_PROFILE_FILE
