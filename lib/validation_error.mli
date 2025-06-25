open Error

val to_string : validation_error -> string
val to_string_verbose : validation_error -> string
val primary_error : validation_error -> error_kind
val all_errors : validation_error -> (instance_location * error_kind) list
val is_type_error : validation_error -> bool
val is_required_error : validation_error -> bool
val is_format_error : validation_error -> bool
val missing_properties : validation_error -> string list

val type_mismatches :
  validation_error -> (instance_location * Types.json_type * Types.t) list
