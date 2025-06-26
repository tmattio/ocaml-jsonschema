JSON Schema Test Suite
======================

This cram test file runs the official JSON Schema Test Suite against our OCaml implementation.
The test suite is maintained at: https://github.com/json-schema-org/JSON-Schema-Test-Suite

Define helper functions:
  $ run_draft_tests() {
  >     draft=$1
  >     draft_name=$2
  >     echo "=== $draft_name tests ==="
  >     echo "Total test files: $(ls JSON-Schema-Test-Suite/tests/$draft/*.json 2>/dev/null | grep -v optional | wc -l | tr -d ' ')"
  >     for f in $(ls JSON-Schema-Test-Suite/tests/$draft/*.json 2>/dev/null | grep -v optional | sort); do
  >         name=$(basename "$f" .json)
  >         summary=$(./test_runner.exe --$draft "$f" 2>&1 | grep "Summary:" | tail -1)
  >         printf "%-25s %s\n" "$name:" "$summary"
  >     done
  > }
  $ calculate_coverage() {
  >     draft=$1
  >     ls JSON-Schema-Test-Suite/tests/$draft/*.json 2>/dev/null | grep -v optional | sort | \
  >     xargs -I {} ./test_runner.exe --$draft {} 2>&1 | grep "Summary:" | \
  >     awk -F'[ /]' '{p+=$2; t+=$3} END {if (t>0) print "Total: " p "/" t " test groups passed (" int(p*100/t) "%)"; else print "No tests found"}'
  > }

Draft 4 tests (JSON Schema Draft 4 - released 2013):
  $ run_draft_tests draft4 "Draft 4"
  === Draft 4 tests ===
  Total test files: 30
  additionalItems:          Summary: 10/10 test groups passed
  additionalProperties:     Summary: 7/7 test groups passed
  allOf:                    Summary: 9/9 test groups passed
  anyOf:                    Summary: 5/5 test groups passed
  default:                  Summary: 3/3 test groups passed
  definitions:              Summary: 0/1 test groups passed
  dependencies:             Summary: 5/5 test groups passed
  enum:                     Summary: 14/14 test groups passed
  format:                   Summary: 6/6 test groups passed
  infinite-loop-detection:  Summary: 1/1 test groups passed
  items:                    Summary: 6/6 test groups passed
  maxItems:                 Summary: 1/1 test groups passed
  maxLength:                Summary: 1/1 test groups passed
  maxProperties:            Summary: 2/2 test groups passed
  maximum:                  Summary: 4/4 test groups passed
  minItems:                 Summary: 1/1 test groups passed
  minLength:                Summary: 1/1 test groups passed
  minProperties:            Summary: 1/1 test groups passed
  minimum:                  Summary: 4/4 test groups passed
  multipleOf:               Summary: 5/5 test groups passed
  not:                      Summary: 6/6 test groups passed
  oneOf:                    Summary: 7/7 test groups passed
  pattern:                  Summary: 2/2 test groups passed
  patternProperties:        Summary: 4/4 test groups passed
  properties:               Summary: 5/5 test groups passed
  ref:                      Summary: 17/19 test groups passed
  refRemote:                Summary: 5/8 test groups passed
  required:                 Summary: 4/4 test groups passed
  type:                     Summary: 11/11 test groups passed
  uniqueItems:              Summary: 6/6 test groups passed
  $ calculate_coverage draft4
  Total: 153/159 test groups passed (96%)

Draft 6 tests (JSON Schema Draft 6 - released 2016):
  $ run_draft_tests draft6 "Draft 6"
  === Draft 6 tests ===
  Total test files: 36
  additionalItems:          Summary: 11/11 test groups passed
  additionalProperties:     Summary: 7/7 test groups passed
  allOf:                    Summary: 12/12 test groups passed
  anyOf:                    Summary: 8/8 test groups passed
  boolean_schema:           Summary: 2/2 test groups passed
  const:                    Summary: 15/15 test groups passed
  contains:                 Summary: 6/6 test groups passed
  default:                  Summary: 3/3 test groups passed
  definitions:              Summary: 0/1 test groups passed
  dependencies:             Summary: 7/7 test groups passed
  enum:                     Summary: 14/14 test groups passed
  exclusiveMaximum:         Summary: 1/1 test groups passed
  exclusiveMinimum:         Summary: 1/1 test groups passed
  format:                   Summary: 9/9 test groups passed
  infinite-loop-detection:  Summary: 1/1 test groups passed
  items:                    Summary: 9/9 test groups passed
  maxItems:                 Summary: 2/2 test groups passed
  maxLength:                Summary: 2/2 test groups passed
  maxProperties:            Summary: 3/3 test groups passed
  maximum:                  Summary: 2/2 test groups passed
  minItems:                 Summary: 2/2 test groups passed
  minLength:                Summary: 2/2 test groups passed
  minProperties:            Summary: 2/2 test groups passed
  minimum:                  Summary: 2/2 test groups passed
  multipleOf:               Summary: 5/5 test groups passed
  not:                      Summary: 8/8 test groups passed
  oneOf:                    Summary: 11/11 test groups passed
  pattern:                  Summary: 2/2 test groups passed
  patternProperties:        Summary: 5/5 test groups passed
  properties:               Summary: 6/6 test groups passed
  propertyNames:            Summary: 6/6 test groups passed
  ref:                      Summary: 18/31 test groups passed
  refRemote:                Summary: 3/11 test groups passed
  required:                 Summary: 5/5 test groups passed
  type:                     Summary: 11/11 test groups passed
  uniqueItems:              Summary: 6/6 test groups passed
  $ calculate_coverage draft6
  Total: 209/231 test groups passed (90%)

Draft 7 tests (JSON Schema Draft 7 - released 2017):
  $ run_draft_tests draft7 "Draft 7"
  === Draft 7 tests ===
  Total test files: 37
  additionalItems:          Summary: 11/11 test groups passed
  additionalProperties:     Summary: 7/7 test groups passed
  allOf:                    Summary: 12/12 test groups passed
  anyOf:                    Summary: 8/8 test groups passed
  boolean_schema:           Summary: 2/2 test groups passed
  const:                    Summary: 15/15 test groups passed
  contains:                 Summary: 7/7 test groups passed
  default:                  Summary: 3/3 test groups passed
  definitions:              Summary: 0/1 test groups passed
  dependencies:             Summary: 7/7 test groups passed
  enum:                     Summary: 14/14 test groups passed
  exclusiveMaximum:         Summary: 1/1 test groups passed
  exclusiveMinimum:         Summary: 1/1 test groups passed
  format:                   Summary: 17/17 test groups passed
  if-then-else:             Summary: 10/10 test groups passed
  infinite-loop-detection:  Summary: 1/1 test groups passed
  items:                    Summary: 9/9 test groups passed
  maxItems:                 Summary: 2/2 test groups passed
  maxLength:                Summary: 2/2 test groups passed
  maxProperties:            Summary: 3/3 test groups passed
  maximum:                  Summary: 2/2 test groups passed
  minItems:                 Summary: 2/2 test groups passed
  minLength:                Summary: 2/2 test groups passed
  minProperties:            Summary: 2/2 test groups passed
  minimum:                  Summary: 2/2 test groups passed
  multipleOf:               Summary: 5/5 test groups passed
  not:                      Summary: 8/8 test groups passed
  oneOf:                    Summary: 11/11 test groups passed
  pattern:                  Summary: 2/2 test groups passed
  patternProperties:        Summary: 5/5 test groups passed
  properties:               Summary: 6/6 test groups passed
  propertyNames:            Summary: 6/6 test groups passed
  ref:                      Summary: 18/35 test groups passed
  refRemote:                Summary: 3/11 test groups passed
  required:                 Summary: 5/5 test groups passed
  type:                     Summary: 11/11 test groups passed
  uniqueItems:              Summary: 6/6 test groups passed
  $ calculate_coverage draft7
  Total: 228/254 test groups passed (89%)

Draft 2019-09 tests (JSON Schema Draft 2019-09):
  $ run_draft_tests draft2019-09 "Draft 2019-09"
  === Draft 2019-09 tests ===
  Total test files: 46
  additionalItems:          Summary: 11/11 test groups passed
  additionalProperties:     Summary: 9/9 test groups passed
  allOf:                    Summary: 12/12 test groups passed
  anchor:                   Summary: 1/4 test groups passed
  anyOf:                    Summary: 8/8 test groups passed
  boolean_schema:           Summary: 2/2 test groups passed
  const:                    Summary: 15/15 test groups passed
  contains:                 Summary: 7/7 test groups passed
  content:                  Summary: 4/4 test groups passed
  default:                  Summary: 3/3 test groups passed
  defs:                     Summary: 0/1 test groups passed
  dependentRequired:        Summary: 4/4 test groups passed
  dependentSchemas:         Summary: 4/4 test groups passed
  enum:                     Summary: 14/14 test groups passed
  exclusiveMaximum:         Summary: 1/1 test groups passed
  exclusiveMinimum:         Summary: 1/1 test groups passed
  format:                   Summary: 19/19 test groups passed
  if-then-else:             Summary: 10/10 test groups passed
  infinite-loop-detection:  Summary: 1/1 test groups passed
  items:                    Summary: 9/9 test groups passed
  maxContains:              Summary: 4/4 test groups passed
  maxItems:                 Summary: 2/2 test groups passed
  maxLength:                Summary: 2/2 test groups passed
  maxProperties:            Summary: 3/3 test groups passed
  maximum:                  Summary: 2/2 test groups passed
  minContains:              Summary: 8/8 test groups passed
  minItems:                 Summary: 2/2 test groups passed
  minLength:                Summary: 2/2 test groups passed
  minProperties:            Summary: 2/2 test groups passed
  minimum:                  Summary: 2/2 test groups passed
  multipleOf:               Summary: 5/5 test groups passed
  not:                      Summary: 8/9 test groups passed
  oneOf:                    Summary: 11/11 test groups passed
  pattern:                  Summary: 2/2 test groups passed
  patternProperties:        Summary: 5/5 test groups passed
  properties:               Summary: 6/6 test groups passed
  propertyNames:            Summary: 6/6 test groups passed
  recursiveRef:             Summary: 2/9 test groups passed
  ref:                      Summary: 20/36 test groups passed
  refRemote:                Summary: 6/15 test groups passed
  required:                 Summary: 5/5 test groups passed
  type:                     Summary: 11/11 test groups passed
  unevaluatedItems:         Summary: 19/25 test groups passed
  unevaluatedProperties:    Summary: 32/40 test groups passed
  uniqueItems:              Summary: 6/6 test groups passed
  vocabulary:               Summary: 1/2 test groups passed
  $ calculate_coverage draft2019-09
  Total: 309/361 test groups passed (85%)

Draft 2020-12 tests (JSON Schema Draft 2020-12 - latest stable):
  $ run_draft_tests draft2020-12 "Draft 2020-12"
  === Draft 2020-12 tests ===
  Total test files: 46
  additionalProperties:     Summary: 9/9 test groups passed
  allOf:                    Summary: 12/12 test groups passed
  anchor:                   Summary: 1/4 test groups passed
  anyOf:                    Summary: 8/8 test groups passed
  boolean_schema:           Summary: 2/2 test groups passed
  const:                    Summary: 15/15 test groups passed
  contains:                 Summary: 7/7 test groups passed
  content:                  Summary: 4/4 test groups passed
  default:                  Summary: 3/3 test groups passed
  defs:                     Summary: 0/1 test groups passed
  dependentRequired:        Summary: 4/4 test groups passed
  dependentSchemas:         Summary: 4/4 test groups passed
  dynamicRef:               Summary: 8/20 test groups passed
  enum:                     Summary: 14/14 test groups passed
  exclusiveMaximum:         Summary: 1/1 test groups passed
  exclusiveMinimum:         Summary: 1/1 test groups passed
  format:                   Summary: 19/19 test groups passed
  if-then-else:             Summary: 10/10 test groups passed
  infinite-loop-detection:  Summary: 1/1 test groups passed
  items:                    Summary: 10/10 test groups passed
  maxContains:              Summary: 4/4 test groups passed
  maxItems:                 Summary: 2/2 test groups passed
  maxLength:                Summary: 2/2 test groups passed
  maxProperties:            Summary: 3/3 test groups passed
  maximum:                  Summary: 2/2 test groups passed
  minContains:              Summary: 8/8 test groups passed
  minItems:                 Summary: 2/2 test groups passed
  minLength:                Summary: 2/2 test groups passed
  minProperties:            Summary: 2/2 test groups passed
  minimum:                  Summary: 2/2 test groups passed
  multipleOf:               Summary: 5/5 test groups passed
  not:                      Summary: 8/9 test groups passed
  oneOf:                    Summary: 11/11 test groups passed
  pattern:                  Summary: 2/2 test groups passed
  patternProperties:        Summary: 5/5 test groups passed
  prefixItems:              Summary: 4/4 test groups passed
  properties:               Summary: 6/6 test groups passed
  propertyNames:            Summary: 6/6 test groups passed
  ref:                      Summary: 20/35 test groups passed
  refRemote:                Summary: 6/15 test groups passed
  required:                 Summary: 5/5 test groups passed
  type:                     Summary: 11/11 test groups passed
  unevaluatedItems:         Summary: 18/27 test groups passed
  unevaluatedProperties:    Summary: 33/41 test groups passed
  uniqueItems:              Summary: 6/6 test groups passed
  vocabulary:               Summary: 1/2 test groups passed
  $ calculate_coverage draft2020-12
  Total: 309/368 test groups passed (83%)
