# Changelog

## 0.1.0 (2025-06-26)

### Features

- Initial release with support for JSON Schema drafts 4, 6, 7, 2019-09, and 2020-12
- Complete type validation system (null, boolean, number, integer, string, array, object)
- Schema composition with allOf, anyOf, oneOf, not, and if/then/else
- Full object validation including properties, patternProperties, and additionalProperties
- Array validation with items, contains, and uniqueItems support
- JSON Reference resolution with $ref, $id, and $anchor support
- Format validation for common formats (email, date, time, ipv4, ipv6, uri, uuid, etc.)
- JSON Pointer implementation (RFC 6901)
- Content validation with base64 encoding and JSON media type support
