JSON Schema Test Suite
======================

This cram test file runs the official JSON Schema Test Suite against our OCaml implementation.
The test suite is maintained at: https://github.com/json-schema-org/JSON-Schema-Test-Suite

Draft 4 tests (JSON Schema Draft 4 - released 2013):
  $ echo "=== Draft 4 tests ===" && \
  > find JSON-Schema-Test-Suite/tests/draft4 -name "*.json" -type f ! -path "*/optional/*" | wc -l | xargs -I {} echo "Total test files: {}" && \
  > find JSON-Schema-Test-Suite/tests/draft4 -name "*.json" -type f ! -path "*/optional/*" | sort | xargs -I {} ./test_runner.exe --draft4 {} 2>&1 | grep "Summary:" | head -5
  === Draft 4 tests ===
  Total test files: 28
  Summary: 0/5 test groups passed
  Summary: 0/7 test groups passed
  Summary: 0/5 test groups passed
  Summary: 0/7 test groups passed
  Summary: 0/4 test groups passed

Draft 6 tests (JSON Schema Draft 6 - released 2016):
  $ echo "=== Draft 6 tests ===" && \
  > find JSON-Schema-Test-Suite/tests/draft6 -name "*.json" -type f ! -path "*/optional/*" | wc -l | xargs -I {} echo "Total test files: {}" && \
  > find JSON-Schema-Test-Suite/tests/draft6 -name "*.json" -type f ! -path "*/optional/*" | sort | xargs -I {} ./test_runner.exe --draft6 {} 2>&1 | grep "Summary:" | head -5
  === Draft 6 tests ===
  Total test files: 30
  Summary: 0/5 test groups passed
  Summary: 0/7 test groups passed
  Summary: 0/5 test groups passed
  Summary: 0/7 test groups passed
  Summary: 0/2 test groups passed

Draft 7 tests (JSON Schema Draft 7 - released 2017):
  $ echo "=== Draft 7 tests ===" && \
  > find JSON-Schema-Test-Suite/tests/draft7 -name "*.json" -type f ! -path "*/optional/*" | wc -l | xargs -I {} echo "Total test files: {}" && \
  > find JSON-Schema-Test-Suite/tests/draft7 -name "*.json" -type f ! -path "*/optional/*" | sort | xargs -I {} ./test_runner.exe --draft7 {} 2>&1 | grep "Summary:" | head -5
  === Draft 7 tests ===
  Total test files: 32
  Summary: 0/5 test groups passed
  Summary: 0/7 test groups passed
  Summary: 0/5 test groups passed
  Summary: 0/7 test groups passed
  Summary: 0/2 test groups passed

Draft 2019-09 tests (JSON Schema Draft 2019-09):
  $ echo "=== Draft 2019-09 tests ===" && \
  > find JSON-Schema-Test-Suite/tests/draft2019-09 -name "*.json" -type f ! -path "*/optional/*" | wc -l | xargs -I {} echo "Total test files: {}" && \
  > find JSON-Schema-Test-Suite/tests/draft2019-09 -name "*.json" -type f ! -path "*/optional/*" | sort | xargs -I {} ./test_runner.exe --draft2019-09 {} 2>&1 | grep "Summary:" | head -5
  === Draft 2019-09 tests ===
  Total test files: 36
  Summary: 0/5 test groups passed
  Summary: 0/8 test groups passed
  Summary: 0/5 test groups passed
  Summary: 0/12 test groups passed
  Summary: 0/7 test groups passed

Draft 2020-12 tests (JSON Schema Draft 2020-12 - latest stable):
  $ echo "=== Draft 2020-12 tests ===" && \
  > find JSON-Schema-Test-Suite/tests/draft2020-12 -name "*.json" -type f ! -path "*/optional/*" | wc -l | xargs -I {} echo "Total test files: {}" && \
  > find JSON-Schema-Test-Suite/tests/draft2020-12 -name "*.json" -type f ! -path "*/optional/*" | sort | xargs -I {} ./test_runner.exe --draft2020-12 {} 2>&1 | grep "Summary:" | head -5
  === Draft 2020-12 tests ===
  Total test files: 40
  Summary: 0/5 test groups passed
  Summary: 0/5 test groups passed
  Summary: 0/12 test groups passed
  Summary: 0/7 test groups passed
  Summary: 0/2 test groups passed

==================================
Detailed Test Output for Debugging
==================================

Each test group shows:
- ✓ for passing test groups (with count of passing tests)
- ✗ for failing test groups (with count of passing tests and list of failures)
- Detailed error messages for each failing test case

Example: Running type validation tests for Draft 2020-12:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/type.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/type.json:
    ✗ integer type matches integers (2/9)
      - Test 3 (a float is not an integer): Expected invalid, but validation passed
      - Test 4 (a string is not an integer): Expected invalid, but validation passed
      - Test 5 (a string is still not an integer, even if it looks like one): Expected invalid, but validation passed
      - Test 6 (an object is not an integer): Expected invalid, but validation passed
      - Test 7 (an array is not an integer): Expected invalid, but validation passed
      - Test 8 (a boolean is not an integer): Expected invalid, but validation passed
      - Test 9 (null is not an integer): Expected invalid, but validation passed
    ✗ number type matches numbers (3/9)
      - Test 4 (a string is not a number): Expected invalid, but validation passed
      - Test 5 (a string is still not a number, even if it looks like one): Expected invalid, but validation passed
      - Test 6 (an object is not a number): Expected invalid, but validation passed
      - Test 7 (an array is not a number): Expected invalid, but validation passed
      - Test 8 (a boolean is not a number): Expected invalid, but validation passed
      - Test 9 (null is not a number): Expected invalid, but validation passed
    ✗ string type matches strings (3/9)
      - Test 1 (1 is not a string): Expected invalid, but validation passed
      - Test 2 (a float is not a string): Expected invalid, but validation passed
      - Test 6 (an object is not a string): Expected invalid, but validation passed
      - Test 7 (an array is not a string): Expected invalid, but validation passed
      - Test 8 (a boolean is not a string): Expected invalid, but validation passed
      - Test 9 (null is not a string): Expected invalid, but validation passed
    ✗ object type matches objects (1/7)
      - Test 1 (an integer is not an object): Expected invalid, but validation passed
      - Test 2 (a float is not an object): Expected invalid, but validation passed
      - Test 3 (a string is not an object): Expected invalid, but validation passed
      - Test 5 (an array is not an object): Expected invalid, but validation passed
      - Test 6 (a boolean is not an object): Expected invalid, but validation passed
      - Test 7 (null is not an object): Expected invalid, but validation passed
    ✗ array type matches arrays (1/7)
      - Test 1 (an integer is not an array): Expected invalid, but validation passed
      - Test 2 (a float is not an array): Expected invalid, but validation passed
      - Test 3 (a string is not an array): Expected invalid, but validation passed
      - Test 4 (an object is not an array): Expected invalid, but validation passed
      - Test 6 (a boolean is not an array): Expected invalid, but validation passed
      - Test 7 (null is not an array): Expected invalid, but validation passed
    ✗ boolean type matches booleans (2/10)
      - Test 1 (an integer is not a boolean): Expected invalid, but validation passed
      - Test 2 (zero is not a boolean): Expected invalid, but validation passed
      - Test 3 (a float is not a boolean): Expected invalid, but validation passed
      - Test 4 (a string is not a boolean): Expected invalid, but validation passed
      - Test 5 (an empty string is not a boolean): Expected invalid, but validation passed
      - Test 6 (an object is not a boolean): Expected invalid, but validation passed
      - Test 7 (an array is not a boolean): Expected invalid, but validation passed
      - Test 10 (null is not a boolean): Expected invalid, but validation passed
    ✗ null type matches only the null object (1/10)
      - Test 1 (an integer is not null): Expected invalid, but validation passed
      - Test 2 (a float is not null): Expected invalid, but validation passed
      - Test 3 (zero is not null): Expected invalid, but validation passed
      - Test 4 (a string is not null): Expected invalid, but validation passed
      - Test 5 (an empty string is not null): Expected invalid, but validation passed
      - Test 6 (an object is not null): Expected invalid, but validation passed
      - Test 7 (an array is not null): Expected invalid, but validation passed
      - Test 8 (true is not null): Expected invalid, but validation passed
      - Test 9 (false is not null): Expected invalid, but validation passed
    ✗ multiple types can be specified in an array (2/7)
      - Test 3 (a float is invalid): Expected invalid, but validation passed
      - Test 4 (an object is invalid): Expected invalid, but validation passed
      - Test 5 (an array is invalid): Expected invalid, but validation passed
      - Test 6 (a boolean is invalid): Expected invalid, but validation passed
      - Test 7 (null is invalid): Expected invalid, but validation passed
    ✗ type as array with one item (1/2)
      - Test 2 (number is invalid): Expected invalid, but validation passed
    ✗ type: array or object (2/5)
      - Test 3 (number is invalid): Expected invalid, but validation passed
      - Test 4 (string is invalid): Expected invalid, but validation passed
      - Test 5 (null is invalid): Expected invalid, but validation passed
    ✗ type: array, object or null (3/5)
      - Test 4 (number is invalid): Expected invalid, but validation passed
      - Test 5 (string is invalid): Expected invalid, but validation passed
  Summary: 0/11 test groups passed
  [1]