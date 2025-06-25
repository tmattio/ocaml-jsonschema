open Error

type flag_output = { valid : bool }
type schema_token = Prop of string | Item of int
type keyword_path = { keyword : string; token : schema_token option }

type absolute_keyword_location = {
  schema_url : string;
  keyword_path : keyword_path option;
}

type output_error = Leaf of error_kind | Branch of output_unit list

and output_unit = {
  valid : bool;
  keyword_location : string;
  absolute_keyword_location : absolute_keyword_location option;
  instance_location : instance_location;
  error : output_error;
}

val flag_output : validation_error -> flag_output
val basic_output : validation_error -> output_unit
val detailed_output : validation_error -> output_unit
val flag_to_json : flag_output -> Yojson.Basic.t
val output_unit_to_json : output_unit -> Yojson.Basic.t
