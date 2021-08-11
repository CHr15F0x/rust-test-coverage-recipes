# rust-test-coverage-recipes
Scripts for test coverage in Rust.

*(Tested only on Ubuntu 18.04 & 20.04)*

`install-deps.sh` - install dependencies for **all** toolset configurations

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
