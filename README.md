# rust-test-coverage-recipes
Scripts for test coverage in Rust.

*(Tested only on Ubuntu 18.04 & 20.04)*

`run-all-tests.sh` - call **all** of your tests here

There are 3½ variants of toolsets to pick from:

1. `coverage-grcov.sh`
    ```
    *.profraw ---> [grcov] +--------------> HTML
                           |   
                           +--> [lcov] ---> HTML
    ```    
2. `coverage-llvm.sh`
    ```
    *.profraw ---> [llvm-profdata] ---> [llvm-cov] ---> [lcov] ---> HTML
    ```
3. `coverage-gcov.sh`
    ```
    *.gcda/*.gcno ---> [gcov] ---> [lcov] ---> HTML
    ```

# Dependencies:

All:
`rustup install nightly`

Toolset specific:
1. `coverage-grcov.sh`

	[`llvm` >= v11.0](https://apt.llvm.org/)
    
    If needed: [`update-alternatives-clang.sh`](https://github.com/CHr15F0x/rust-test-coverage-recipes/blob/main/update-alternatives-clang.sh "update-alternatives-clang.sh") to force the default `llvm` version

    `rustup component add llvm-tools-preview --toolchain nightly`
    
    `cargo install grcov`

    Optionally: `apt-get install lcov`

	When in doubt: [more about grcov](https://github.com/mozilla/grcov#how-to-get-grcov)

2. `coverage-llvm.sh`

	[`llvm` >= v11.0](https://apt.llvm.org/)

    If needed: [`update-alternatives-clang.sh`](https://github.com/CHr15F0x/rust-test-coverage-recipes/blob/main/update-alternatives-clang.sh "update-alternatives-clang.sh") to force the default `llvm` version

    `cargo install rustfilt`

    `apt-get install lcov`

	When in doubt: [this chapter of Rust unstable ](https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html).

3. `coverage-gcov.sh`

	`apt-get install gcc-7 lcov`
