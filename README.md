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

### Core Features
- ✅ Type validation (null, boolean, number, integer, string, array, object)
- ✅ Basic constraints (enum, const, type)
- ✅ Numeric constraints (minimum, maximum, exclusiveMinimum, exclusiveMaximum, multipleOf)
- ✅ String constraints (minLength, maxLength, pattern)
- ✅ Array constraints (minItems, maxItems, uniqueItems)
- ✅ Object constraints (required, minProperties, maxProperties)
- ✅ Format validation (with extensible format registry)
- ✅ JSON Pointer (RFC 6901)
- ✅ Error reporting with instance locations

### Schema Composition
- ⚠️  allOf, anyOf, oneOf, not (stub implementation)
- ⚠️  if/then/else (stub implementation)

### Advanced Features
- ⚠️  $ref, $recursiveRef, $dynamicRef (stub implementation)
- ⚠️  $id, $anchor, $dynamicAnchor (stub implementation)
- ⚠️  Remote schema loading (basic file:// support only)
- ⚠️  Schema compilation and caching (basic structure in place)
- ⚠️  unevaluatedProperties, unevaluatedItems (stub implementation)
- ⚠️  dependentRequired, dependentSchemas (stub implementation)
- ⚠️  prefixItems, items, additionalItems (stub implementation)
- ⚠️  propertyNames, patternProperties, additionalProperties (stub implementation)
- ⚠️  contains, minContains, maxContains (stub implementation)

### Content Validation
- ✅ contentEncoding (base64)
- ✅ contentMediaType (application/json)
- ⚠️  contentSchema (stub implementation)

### Output Formats
- ✅ Flag output
- ✅ Basic output
- ⚠️  Detailed output (uses basic output currently)

## Testing

The project uses the official [JSON Schema Test Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite) for validation:

```bash
dune build @runtest
```

## License

ocaml-jsonschema is available under the [ISC License](LICENSE).
