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

let flag_output _err = { valid = false }

let rec basic_output err =
  let keyword_location =
    match err.kind with Schema { url } -> url | _ -> err.schema_url
  in
  {
    valid = false;
    keyword_location;
    absolute_keyword_location = None;
    instance_location = err.instance_location;
    error =
      (if err.causes = [] then Leaf err.kind
       else Branch (List.map basic_output err.causes));
  }

let detailed_output = basic_output (* TODO: implement full detailed output *)

let flag_to_json (output : flag_output) =
  `Assoc [ ("valid", `Bool output.valid) ]

let rec output_unit_to_json output =
  let error_json =
    match output.error with
    | Leaf _kind -> `String "error" (* TODO: proper error serialization *)
    | Branch units -> `List (List.map output_unit_to_json units)
  in
  let instance_tokens =
    List.map
      (function Error.Prop s -> s | Error.Item i -> string_of_int i)
      output.instance_location.tokens
  in
  `Assoc
    [
      ("valid", `Bool output.valid);
      ("keywordLocation", `String output.keyword_location);
      ("instanceLocation", `String (Json_pointer.of_tokens instance_tokens));
      ("error", error_json);
    ]
