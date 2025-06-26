# OCaml JSON Schema

A JSON Schema validator for OCaml supporting drafts 4, 6, 7, 2019-09, and 2020-12.

## Installation

```bash
opam install jsonschema
```

## Usage

### High-level API

```ocaml
open Jsonschema

(* Validate JSON string against schema string *)
let schema = {|{"type": "object", "required": ["name"]}|}
let json = {|{"name": "John", "age": 30}|}

match validate_strings ~schema ~json with
| Ok () -> print_endline "Valid!"
| Error err -> print_endline (Validation_error.to_string err)

(* Validate from files *)
let json = Yojson.Basic.from_file "data.json" in
match validate_file ~schema:"schema.json" json with
| Ok () -> print_endline "Valid!"
| Error err -> print_endline (Validation_error.to_string err)

(* Create a reusable validator *)
match create_validator "schema.json" with
| Ok validator ->
    let json = Yojson.Basic.from_file "data.json" in
    (match validate validator json with
     | Ok () -> print_endline "Valid!"
     | Error err -> print_endline (Validation_error.to_string err))
| Error err -> pp_compile_error Format.std_formatter err
```

### JSON Pointer

```ocaml
let json = `Assoc [("foo", `Assoc [("bar", `Int 42)])] in
match Json_pointer.of_string "/foo/bar" with
| Ok ptr ->
    (match Json_pointer.lookup ptr json with
     | Some (`Int n) -> Printf.printf "Found: %d\n" n
     | _ -> print_endline "Not found")
| Error e -> Printf.printf "Invalid pointer: %s\n" e
```

### Format Validators

The library includes validators for common formats:

- `email`, `idn_email`
- `date`, `time`, `date_time`
- `ipv4`, `ipv6`
- `hostname`, `idn_hostname`
- `uri`, `iri`, `uri_reference`, `iri_reference`
- `uuid`
- `json_pointer`, `relative_json_pointer`
- `regex`

## Implementation Status

### Test Coverage by Draft Version
- **Draft 4**: 153/159 test groups (96%)
- **Draft 6**: 209/231 test groups (90%)
- **Draft 7**: 228/254 test groups (89%)
- **Draft 2019-09**: 309/361 test groups (85%)
- **Draft 2020-12**: 309/368 test groups (83%)

### Core Features (Fully Implemented)
- ✅ Type validation (null, boolean, number, integer, string, array, object)
- ✅ Basic constraints (enum, const, type)
- ✅ Numeric constraints (minimum, maximum, exclusiveMinimum, exclusiveMaximum, multipleOf)
- ✅ String constraints (minLength, maxLength, pattern)
- ✅ Array constraints (minItems, maxItems, uniqueItems) 
- ✅ Object constraints (required, minProperties, maxProperties)
- ✅ Format validation (with extensible format registry)
- ✅ JSON Pointer (RFC 6901)
- ✅ Error reporting with instance locations
- ✅ Boolean schemas (true/false)
- ✅ Empty schema validation

### Schema Composition (Partially Implemented)
- ✅ allOf - validates against all schemas
- ✅ anyOf - validates against at least one schema
- ✅ oneOf - validates against exactly one schema
- ✅ not - validates if schema does not match
- ✅ if/then/else - conditional validation

### Object Validation (Fully Implemented)
- ✅ properties - validates specific properties
- ✅ patternProperties - validates properties matching regex patterns
- ✅ additionalProperties - validates/restricts additional properties
- ✅ propertyNames - validates property name format
- ✅ dependencies - property and schema dependencies (draft 4-7)
- ✅ dependentRequired - property dependencies (draft 2019-09+)
- ✅ dependentSchemas - schema dependencies (draft 2019-09+)

### Array Validation (Fully Implemented)
- ✅ items - validates array items (uniform or tuple validation)
- ✅ additionalItems - validates/restricts additional items beyond tuple
- ✅ prefixItems - validates initial items (draft 2020-12)
- ✅ contains - validates at least one item matches
- ✅ minContains/maxContains - number of items matching contains

### References and Schema Identification
- ✅ $ref - basic JSON pointer and fragment resolution
- ✅ $ref with sibling keywords - validates both $ref and siblings
- ✅ $id - schema identification and base URI changes
- ✅ $anchor/$dynamicAnchor - schema anchors for references
- ✅ $recursiveRef/$dynamicRef - basic resolution (full dynamic scope pending)
- ⚠️  Remote schema loading - basic file:// support only

### Advanced Validation
- ✅ unevaluatedProperties - validates properties not covered by other keywords
- ✅ unevaluatedItems - validates items not covered by other keywords
- ⚠️  Vocabulary support - basic structure, not fully implemented

### Content Validation
- ✅ contentEncoding (base64)
- ✅ contentMediaType (application/json)
- ✅ contentSchema - validates decoded content against schema

### Output Formats
- ✅ Flag output - simple boolean result
- ✅ Basic output - error with instance location
- ✅ Detailed output - includes schema location and error details

### Known Limitations
- Remote schema loading only supports file:// URLs
- Dynamic scope resolution for $recursiveRef/$dynamicRef is simplified
- Some complex interactions between unevaluatedProperties/Items and $ref
- Vocabulary support is minimal

## License

ocaml-jsonschema is available under the [ISC License](LICENSE).
