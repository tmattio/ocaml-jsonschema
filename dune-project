(lang dune 3.19)

(name jsonschema)

(generate_opam_files true)

(source
 (github tmattio/ocaml-jsonschema))

(authors "Thibaut Mattio <thibaut.mattio@gmail.com>")

(maintainers "Thibaut Mattio <thibaut.mattio@gmail.com>")

(license ISC)

(package
 (name jsonschema)
 (synopsis "JSON Schema validator for OCaml")
 (description
  "A comprehensive JSON Schema validator implementation for OCaml supporting drafts 4, 6, 7, 2019-09, and 2020-12. This library provides full validation of JSON documents against JSON Schema definitions with detailed error reporting, support for all standard validation keywords, format validators, and content encoding/decoding. It includes features like remote schema resolution, custom format validators, and multiple output formats for validation results.")
 (depends
  (ocaml
   (>= 4.08))
  dune
  re
  yojson
  ppx_deriving_yojson
  base64
  uri
  (odoc :with-doc))
 (tags
  (json jsonschema)))
