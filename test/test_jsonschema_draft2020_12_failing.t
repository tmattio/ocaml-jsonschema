JSON Schema Test Suite - Draft 2020-12 Failing Tests (Detailed)
===============================================================

This cram test provides detailed information about each failing test case
for JSON Schema Draft 2020-12, including the schema and test data.

anchor tests:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/anchor.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/anchor.json:
    ✓ Location-independent identifier (2/2)
    ✗ Location-independent identifier with absolute URI (1/2)
      - Test 2 (mismatch): Expected invalid, but validation passed
    ✗ Location-independent identifier with base URI change in subschema (1/2)
      - Test 2 (mismatch): Expected invalid, but validation passed
    ✗ same $anchor with different base uri (1/2)
      - Test 2 ($ref does not resolve to /$defs/A/allOf/0): Expected invalid, but validation passed
  Summary: 1/4 test groups passed
  [1]

defs tests:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/defs.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/defs.json:
    ✗ validate definition against metaschema (1/2)
      - Test 2 (invalid definition schema): Expected invalid, but validation passed
  Summary: 0/1 test groups passed
  [1]

dynamicRef tests:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/dynamicRef.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/dynamicRef.json:
    ✓ A $dynamicRef to a $dynamicAnchor in the same schema resource behaves like a normal $ref to an $anchor (2/2)
    ✓ A $dynamicRef to an $anchor in the same schema resource behaves like a normal $ref to an $anchor (2/2)
    ✓ A $ref to a $dynamicAnchor in the same schema resource behaves like a normal $ref to an $anchor (2/2)
    ✗ A $dynamicRef resolves to the first $dynamicAnchor still in scope that is encountered when the schema is evaluated (1/2)
      - Test 2 (An array containing non-strings is invalid): Expected invalid, but validation passed
    ✗ A $dynamicRef without anchor in fragment behaves identical to $ref (1/2)
      - Test 1 (An array of strings is invalid): Expected invalid, but validation passed
    ✗ A $dynamicRef with intermediate scopes that don't include a matching $dynamicAnchor does not affect dynamic scope resolution (1/2)
      - Test 2 (An array containing non-strings is invalid): Expected invalid, but validation passed
    ✓ An $anchor with the same name as a $dynamicAnchor is not used for dynamic scope resolution (1/1)
    ✓ A $dynamicRef without a matching $dynamicAnchor in the same schema resource behaves like a normal $ref to $anchor (1/1)
    ✓ A $dynamicRef with a non-matching $dynamicAnchor in the same schema resource behaves like a normal $ref to $anchor (1/1)
    ✗ A $dynamicRef that initially resolves to a schema with a matching $dynamicAnchor resolves to the first $dynamicAnchor in the dynamic scope (1/2)
      - Test 2 (The recursive part is not valid against the root): Expected invalid, but validation passed
    ✓ A $dynamicRef that initially resolves to a schema without a matching $dynamicAnchor behaves like a normal $ref to $anchor (1/1)
    ✗ multiple dynamic paths to the $dynamicRef keyword (2/4)
      - Test 2 (number list with string values): Expected invalid, but validation passed
      - Test 3 (string list with number values): Expected invalid, but validation passed
    ✗ after leaving a dynamic scope, it is not used by a $dynamicRef (1/3)
      - Test 1 (string matches /$defs/thingy, but the $dynamicRef does not stop here): Expected invalid, but validation passed
      - Test 2 (first_scope is not in dynamic scope for the $dynamicRef): Expected invalid, but validation passed
    ✗ strict-tree schema, guards against misspelled properties (1/2)
      - Test 2 (instance with correct field): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': validation error
    ✗ tests for implementation dynamic anchor and reference link (1/3)
      - Test 1 (incorrect parent schema): Expected invalid, but validation passed
      - Test 2 (incorrect extended schema): Expected invalid, but validation passed
    ✗ $ref and $dynamicAnchor are independent of order - $defs first (1/3)
      - Test 1 (incorrect parent schema): Expected invalid, but validation passed
      - Test 2 (incorrect extended schema): Expected invalid, but validation passed
    ✗ $ref and $dynamicAnchor are independent of order - $ref first (1/3)
      - Test 1 (incorrect parent schema): Expected invalid, but validation passed
      - Test 2 (incorrect extended schema): Expected invalid, but validation passed
    ✗ $ref to $dynamicRef finds detached $dynamicAnchor (1/2)
      - Test 2 (non-number is invalid): Expected invalid, but validation passed
    ✓ $dynamicRef points to a boolean schema (2/2)
    ✗ $dynamicRef skips over intermediate resources - direct reference (1/2)
      - Test 2 (string property fails): Expected invalid, but validation passed
  Summary: 8/20 test groups passed
  [1]

not tests:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/not.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/not.json:
    ✓ not (2/2)
    ✓ not multiple types (3/3)
    ✓ not more complex schema (3/3)
    ✓ forbidden property (2/2)
    ✓ forbid everything with empty schema (9/9)
    ✓ forbid everything with boolean schema true (9/9)
    ✓ allow everything with boolean schema false (9/9)
    ✓ double negation (1/1)
    ✗ collect annotations inside a 'not', even if collection is disabled (1/2)
      - Test 1 (unevaluated property): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': validation error
  Summary: 8/9 test groups passed
  [1]

ref tests:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/ref.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/ref.json:
    ✓ root pointer ref (4/4)
    ✓ relative pointer ref to object (2/2)
    ✓ relative pointer ref to array (2/2)
    ✓ escaped pointer ref (6/6)
    ✓ nested refs (2/2)
    ✓ ref applies alongside sibling keywords (3/3)
    ✗ remote ref, containing refs itself (1/2)
      - Test 2 (remote ref invalid): Expected invalid, but validation passed
    ✓ property named $ref that is not a reference (2/2)
    ✓ property named $ref, containing an actual $ref (2/2)
    ✓ $ref to boolean schema true (1/1)
    ✓ $ref to boolean schema false (1/1)
    ✗ Recursive references between schemas (1/2)
      - Test 2 (invalid tree): Expected invalid, but validation passed
    ✓ refs with quote (2/2)
    ✓ ref creates new scope when adjacent to keywords (1/1)
    ✓ naive replacement of $ref with its destination is not correct (3/3)
    ✗ refs with relative uris and defs (1/3)
      - Test 1 (invalid on inner field): Expected invalid, but validation passed
      - Test 2 (invalid on outer field): Expected invalid, but validation passed
    ✗ relative refs with absolute uris and defs (1/3)
      - Test 1 (invalid on inner field): Expected invalid, but validation passed
      - Test 2 (invalid on outer field): Expected invalid, but validation passed
    ✗ $id must be resolved against nearest parent, not just immediate parent (1/2)
      - Test 2 (non-number is invalid): Expected invalid, but validation passed
    ✗ order of evaluation: $id and $ref (1/2)
      - Test 2 (data is invalid against first definition): Expected invalid, but validation passed
    ✗ order of evaluation: $id and $anchor and $ref (1/2)
      - Test 1 (data is valid against first definition): Expected valid, but got: jsonschema validation failed with inline://schema#/$defs/smallint
    at '': validation error
    ✗ simple URN base URI with $ref via the URN (1/2)
      - Test 2 (invalid under the URN IDed schema): Expected invalid, but validation passed
    ✓ simple URN base URI with JSON pointer (2/2)
    ✓ URN base URI with NSS (2/2)
    ✓ URN base URI with r-component (2/2)
    ✓ URN base URI with q-component (2/2)
    ✗ URN base URI with URN and JSON pointer ref (1/2)
      - Test 2 (a non-string is invalid): Expected invalid, but validation passed
    ✗ URN base URI with URN and anchor ref (1/2)
      - Test 2 (a non-string is invalid): Expected invalid, but validation passed
    ✗ URN ref with nested pointer ref (1/2)
      - Test 2 (a non-string is invalid): Expected invalid, but validation passed
    ✗ ref to if (1/2)
      - Test 1 (a non-integer is invalid due to the $ref): Expected invalid, but validation passed
    ✗ ref to then (1/2)
      - Test 1 (a non-integer is invalid due to the $ref): Expected invalid, but validation passed
    ✗ ref to else (1/2)
      - Test 1 (a non-integer is invalid due to the $ref): Expected invalid, but validation passed
    ✗ ref with absolute-path-reference (1/2)
      - Test 2 (an integer is invalid): Expected invalid, but validation passed
    ✓ $id with file URI still resolves pointers - *nix (2/2)
    ✓ $id with file URI still resolves pointers - windows (2/2)
    ✓ empty tokens in $ref json-pointer (2/2)
  Summary: 20/35 test groups passed
  [1]

refRemote tests:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/refRemote.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/refRemote.json:
    ✓ remote ref (2/2)
    ✓ fragment within remote ref (2/2)
    ✓ anchor within remote ref (2/2)
    ✓ ref within remote ref (2/2)
    ✗ base URI change (1/2)
      - Test 2 (base URI change ref invalid): Expected invalid, but validation passed
    ✗ base URI change - change folder (1/2)
      - Test 2 (string is invalid): Expected invalid, but validation passed
    ✗ base URI change - change folder in subschema (1/2)
      - Test 2 (string is invalid): Expected invalid, but validation passed
    ✗ root ref in remote ref (2/3)
      - Test 3 (object is invalid): Expected invalid, but validation passed
    ✗ remote ref with ref to defs (1/2)
      - Test 1 (invalid): Expected invalid, but validation passed
    ✗ Location-independent identifier in remote ref (1/2)
      - Test 2 (string is invalid): Expected invalid, but validation passed
    ✗ retrieved nested refs resolve relative to their URI not $id (1/2)
      - Test 1 (number is invalid): Expected invalid, but validation passed
    ✓ remote HTTP ref with different $id (2/2)
    ✓ remote HTTP ref with different URN $id (2/2)
    ✗ remote HTTP ref with nested absolute ref (1/2)
      - Test 1 (number is invalid): Expected invalid, but validation passed
    ✗ $ref to $ref finds detached $anchor (1/2)
      - Test 2 (non-number is invalid): Expected invalid, but validation passed
  Summary: 6/15 test groups passed
  [1]

unevaluatedItems tests:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/unevaluatedItems.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/unevaluatedItems.json:
    ✓ unevaluatedItems true (2/2)
    ✓ unevaluatedItems false (2/2)
    ✓ unevaluatedItems as schema (3/3)
    ✓ unevaluatedItems with uniform items (1/1)
    ✓ unevaluatedItems with tuple (2/2)
    ✓ unevaluatedItems with items and prefixItems (1/1)
    ✓ unevaluatedItems with items (2/2)
    ✓ unevaluatedItems with nested tuple (2/2)
    ✗ unevaluatedItems with nested items (2/3)
      - Test 3 (with invalid additional item): Expected invalid, but validation passed
    ✓ unevaluatedItems with nested prefixItems and items (2/2)
    ✗ unevaluatedItems with nested unevaluatedItems (1/2)
      - Test 2 (with additional items): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': 2 unevaluated items
    ✓ unevaluatedItems with anyOf (4/4)
    ✓ unevaluatedItems with oneOf (2/2)
    ✓ unevaluatedItems with not (1/1)
    ✓ unevaluatedItems with if/then/else (4/4)
    ✗ unevaluatedItems with boolean schemas (1/2)
      - Test 2 (with unevaluated items): Expected invalid, but validation passed
    ✗ unevaluatedItems with $ref (1/2)
      - Test 2 (with unevaluated items): Expected invalid, but validation passed
    ✗ unevaluatedItems before $ref (1/2)
      - Test 2 (with unevaluated items): Expected invalid, but validation passed
    ✗ unevaluatedItems with $dynamicRef (1/2)
      - Test 2 (with unevaluated items): Expected invalid, but validation passed
    ✓ unevaluatedItems can't see inside cousins (1/1)
    ✓ item is evaluated in an uncle schema to unevaluatedItems (2/2)
    ✗ unevaluatedItems depends on adjacent contains (2/3)
      - Test 1 (second item is evaluated by contains): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': 1 unevaluated items
    ✗ unevaluatedItems depends on multiple nested contains (1/2)
      - Test 1 (5 not evaluated, passes unevaluatedItems): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': validation error
    ✗ unevaluatedItems and contains interact to control item dependency relationship (5/8)
      - Test 2 (only a's are valid): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': 2 unevaluated items
      - Test 3 (a's and b's are valid): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': 5 unevaluated items
      - Test 4 (a's, b's and c's are valid): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': 6 unevaluated items
    ✓ non-array instances are valid (6/6)
    ✓ unevaluatedItems with null instance elements (1/1)
    ✓ unevaluatedItems can see annotations from if without then and else (2/2)
  Summary: 18/27 test groups passed
  [1]

unevaluatedProperties tests:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/unevaluatedProperties.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/unevaluatedProperties.json:
    ✓ unevaluatedProperties true (2/2)
    ✓ unevaluatedProperties schema (3/3)
    ✓ unevaluatedProperties false (2/2)
    ✓ unevaluatedProperties with adjacent properties (2/2)
    ✓ unevaluatedProperties with adjacent patternProperties (2/2)
    ✓ unevaluatedProperties with adjacent bool additionalProperties (2/2)
    ✓ unevaluatedProperties with adjacent non-bool additionalProperties (2/2)
    ✓ unevaluatedProperties with nested properties (2/2)
    ✓ unevaluatedProperties with nested patternProperties (2/2)
    ✓ unevaluatedProperties with nested additionalProperties (2/2)
    ✗ unevaluatedProperties with nested unevaluatedProperties (1/2)
      - Test 2 (with nested unevaluated properties): Expected valid, but got: jsonschema validation failed with inline://schema#/unevaluatedProperties
    at '/bar': validation error
    ✓ unevaluatedProperties with anyOf (4/4)
    ✓ unevaluatedProperties with oneOf (2/2)
    ✓ unevaluatedProperties with not (1/1)
    ✓ unevaluatedProperties with if/then/else (4/4)
    ✓ unevaluatedProperties with if/then/else, then not defined (4/4)
    ✓ unevaluatedProperties with if/then/else, else not defined (4/4)
    ✓ unevaluatedProperties with dependentSchemas (2/2)
    ✗ unevaluatedProperties with boolean schemas (1/2)
      - Test 2 (with unevaluated properties): Expected invalid, but validation passed
    ✗ unevaluatedProperties with $ref (1/2)
      - Test 1 (with no unevaluated properties): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': validation error
    ✗ unevaluatedProperties before $ref (1/2)
      - Test 1 (with no unevaluated properties): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': validation error
    ✗ unevaluatedProperties with $dynamicRef (1/2)
      - Test 2 (with unevaluated properties): Expected invalid, but validation passed
    ✓ unevaluatedProperties can't see inside cousins (1/1)
    ✓ unevaluatedProperties can't see inside cousins (reverse order) (1/1)
    ✗ nested unevaluatedProperties, outer false, inner true, properties outside (1/2)
      - Test 2 (with nested unevaluated properties): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': validation error
    ✗ nested unevaluatedProperties, outer false, inner true, properties inside (1/2)
      - Test 2 (with nested unevaluated properties): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': validation error
    ✓ nested unevaluatedProperties, outer true, inner false, properties outside (2/2)
    ✓ nested unevaluatedProperties, outer true, inner false, properties inside (2/2)
    ✓ cousin unevaluatedProperties, true and false, true with properties (2/2)
    ✓ cousin unevaluatedProperties, true and false, false with properties (2/2)
    ✓ property is evaluated in an uncle schema to unevaluatedProperties (2/2)
    ✓ in-place applicator siblings, allOf has unevaluated (3/3)
    ✓ in-place applicator siblings, anyOf has unevaluated (3/3)
    ✓ unevaluatedProperties + single cyclic ref (7/7)
    ✓ unevaluatedProperties + ref inside allOf / oneOf (8/8)
    ✗ dynamic evalation inside nested refs (19/21)
      - Test 19 (all is valid): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': validation error
      - Test 20 (all + foo is valid): Expected valid, but got: jsonschema validation failed with inline://schema
    at '': validation error
    ✓ non-object instances are valid (6/6)
    ✓ unevaluatedProperties with null valued instance properties (1/1)
    ✓ unevaluatedProperties not affected by propertyNames (2/2)
    ✓ unevaluatedProperties can see annotations from if without then and else (2/2)
    ✓ dependentSchemas with unevaluatedProperties (3/3)
  Summary: 33/41 test groups passed
  [1]

vocabulary tests:
  $ ./test_runner.exe --draft2020-12 JSON-Schema-Test-Suite/tests/draft2020-12/vocabulary.json
  
  Running tests from JSON-Schema-Test-Suite/tests/draft2020-12/vocabulary.json:
    ✗ schema that uses custom metaschema with with no validation vocabulary (2/3)
      - Test 3 (no validation: invalid number, but it still validates): Expected valid, but got: jsonschema validation failed with inline://schema#/properties/numberProperty
    at '/numberProperty': validation error
    ✓ ignore unrecognized optional vocabulary (2/2)
  Summary: 1/2 test groups passed
  [1]
