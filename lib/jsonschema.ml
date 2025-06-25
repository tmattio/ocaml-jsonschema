(** JSON Schema validator supporting drafts 4, 6, 7, 2019-09, and 2020-12 *)

(* Re-export types *)
type draft = Draft.t = Draft4 | Draft6 | Draft7 | Draft2019_09 | Draft2020_12
type schema = Schema.t
type validator = Schema.t
type json_pointer = Json_pointer.t
type type_set = Types.t

(* Re-export error types *)
type instance_token = Error.instance_token = Prop of string | Item of int

type instance_location = Error.instance_location = {
  tokens : instance_token list;
}

type error_kind = Error.error_kind =
  | Group
  | Schema of { url : string }
  | Content_schema
  | Property_name of { prop : string }
  | Reference of { kw : string; url : string }
  | Ref_cycle of { url : string; kw_loc1 : string; kw_loc2 : string }
  | False_schema
  | Type of { got : Yojson.Basic.t; want : type_set }
  | Enum of { want : Yojson.Basic.t list }
  | Const of { want : Yojson.Basic.t }
  | Format of { got : Yojson.Basic.t; want : string; err : exn }
  | Min_properties of { got : int; want : int }
  | Max_properties of { got : int; want : int }
  | Additional_properties of { got : string list }
  | Required of { want : string list }
  | Dependency of { prop : string; missing : string list }
  | Dependent_required of { prop : string; missing : string list }
  | Min_items of { got : int; want : int }
  | Max_items of { got : int; want : int }
  | Contains
  | Min_contains of { got : int list; want : int }
  | Max_contains of { got : int list; want : int }
  | Unique_items of { got : int * int }
  | Additional_items of { got : int }
  | Min_length of { got : int; want : int }
  | Max_length of { got : int; want : int }
  | Pattern of { got : string; want : string }
  | Content_encoding of { want : string; err : exn }
  | Content_media_type of { got : bytes; want : string; err : exn }
  | Minimum of { got : float; want : float }
  | Maximum of { got : float; want : float }
  | Exclusive_minimum of { got : float; want : float }
  | Exclusive_maximum of { got : float; want : float }
  | Multiple_of of { got : float; want : float }
  | Not
  | All_of
  | Any_of
  | One_of of (int * int) option

type validation_error = Error.validation_error = {
  schema_url : string;
  instance_location : instance_location;
  kind : error_kind;
  causes : validation_error list;
}

type compile_error = Error.compile_error =
  | Parse_url_error of { url : string; src : exn }
  | Load_url_error of { url : string; src : exn }
  | Unsupported_url_scheme of { url : string }
  | Invalid_meta_schema_url of { url : string; src : exn }
  | Unsupported_draft of { url : string }
  | MetaSchema_cycle of { url : string }
  | Validation_error of { url : string; src : validation_error }
  | Parse_id_error of { loc : string }
  | Parse_anchor_error of { loc : string }
  | Duplicate_id of { url : string; id : string; ptr1 : string; ptr2 : string }
  | Duplicate_anchor of {
      anchor : string;
      url : string;
      ptr1 : string;
      ptr2 : string;
    }
  | Invalid_json_pointer of string
  | Json_pointer_not_found of string
  | Anchor_not_found of { url : string; reference : string }
  | Unsupported_vocabulary of { url : string; vocabulary : string }
  | Invalid_regex of { url : string; regex : string; src : exn }
  | Bug of exn

(* Re-export modules *)
module Types = Types
module Json_pointer = Json_pointer
module Format = Formats
module Content = Content
module Draft = Draft
module Loader = Loader
module Output = Output
module Compiler = Compiler

module Schema = struct
  include Schema

  let validate schema v =
    let schemas = Validator.create_schemas () in
    Validator.insert_schemas schemas [ schema.location ] [ schema ];
    Validator.validate v schema schemas
end

module Validation_error = Validation_error

(* Pretty printing *)
let pp_compile_error (fmt : Stdlib.Format.formatter) err =
  match err with
  | Parse_url_error { url; src } ->
      Stdlib.Format.fprintf fmt "Failed to parse URL %s: %s" url
        (Printexc.to_string src)
  | Load_url_error { url; src } ->
      Stdlib.Format.fprintf fmt "Failed to load URL %s: %s" url
        (Printexc.to_string src)
  | Unsupported_url_scheme { url } ->
      Stdlib.Format.fprintf fmt "Unsupported URL scheme in %s" url
  | Invalid_meta_schema_url { url; src } ->
      Stdlib.Format.fprintf fmt "Invalid meta schema URL %s: %s" url
        (Printexc.to_string src)
  | Unsupported_draft { url } ->
      Stdlib.Format.fprintf fmt "Unsupported draft in %s" url
  | MetaSchema_cycle { url } ->
      Stdlib.Format.fprintf fmt "Meta schema cycle detected in %s" url
  | Validation_error { url; src } ->
      Stdlib.Format.fprintf fmt "Validation error in %s: %s" url
        (Validation_error.to_string src)
  | Parse_id_error { loc } ->
      Stdlib.Format.fprintf fmt "Failed to parse $id at %s" loc
  | Parse_anchor_error { loc } ->
      Stdlib.Format.fprintf fmt "Failed to parse $anchor at %s" loc
  | Duplicate_id { url; id; ptr1; ptr2 } ->
      Stdlib.Format.fprintf fmt "Duplicate $id '%s' in %s at %s and %s" id url
        ptr1 ptr2
  | Duplicate_anchor { anchor; url; ptr1; ptr2 } ->
      Stdlib.Format.fprintf fmt "Duplicate $anchor '%s' in %s at %s and %s"
        anchor url ptr1 ptr2
  | Invalid_json_pointer ptr ->
      Stdlib.Format.fprintf fmt "Invalid JSON pointer: %s" ptr
  | Json_pointer_not_found ptr ->
      Stdlib.Format.fprintf fmt "JSON pointer not found: %s" ptr
  | Anchor_not_found { url; reference } ->
      Stdlib.Format.fprintf fmt "Anchor %s not found in %s" reference url
  | Unsupported_vocabulary { url; vocabulary } ->
      Stdlib.Format.fprintf fmt "Unsupported vocabulary %s in %s" vocabulary url
  | Invalid_regex { url; regex; src } ->
      Stdlib.Format.fprintf fmt "Invalid regex '%s' in %s: %s" regex url
        (Printexc.to_string src)
  | Bug src ->
      Stdlib.Format.fprintf fmt "Internal error: %s" (Printexc.to_string src)

let pp_validation_error (fmt : Stdlib.Format.formatter) err =
  Stdlib.Format.pp_print_string fmt (Validation_error.to_string err)

let pp_validation_error_verbose (fmt : Stdlib.Format.formatter) err =
  Stdlib.Format.pp_print_string fmt (Validation_error.to_string_verbose err)

(* High-level API *)
let validate_file ?draft ~schema json =
  let config =
    match draft with
    | Some d -> { Compiler.default_config with default_draft = d }
    | None -> Compiler.default_config
  in
  let compiler = Compiler.create config in
  match Compiler.compile compiler schema with
  | Error _e ->
      Error
        {
          schema_url = schema;
          instance_location = { tokens = [] };
          kind = Schema { url = "Compilation failed" };
          causes = [];
        }
  | Ok sch -> Schema.validate sch json

let validate_strings ?draft ~schema ~json () =
  try
    let json_value = Yojson.Basic.from_string json in
    let _schema_value = Yojson.Basic.from_string schema in
    validate_file ?draft ~schema:"inline://schema" json_value
  with e ->
    Error
      {
        schema_url = "inline://schema";
        instance_location = { tokens = [] };
        kind = Schema { url = Printexc.to_string e };
        causes = [];
      }

let create_validator ?draft ?(enable_format_assertions = true)
    ?(enable_content_assertions = true) location =
  let config =
    {
      Compiler.default_config with
      default_draft = Option.value draft ~default:Draft2020_12;
      enable_format_assertions;
      enable_content_assertions;
    }
  in
  let compiler = Compiler.create config in
  Compiler.compile compiler location

let validate validator json = Schema.validate validator json

(* Pre-compiled meta-schema validators *)
let draft4_validator =
  {
    Schema.draft_version = Draft4;
    idx = 0;
    location = "https://json-schema.org/draft-04/schema";
    resource = 0;
    dynamic_anchors = Hashtbl.create 0;
    all_props_evaluated = false;
    all_items_evaluated = false;
    num_items_evaluated = 0;
    boolean = Some true;
    ref_ = None;
    recursive_ref = None;
    recursive_anchor = false;
    dynamic_ref = None;
    dynamic_anchor = None;
    types = Types.empty;
    enum_ = None;
    constant = None;
    not = None;
    all_of = [];
    any_of = [];
    one_of = [];
    if_ = None;
    then_ = None;
    else_ = None;
    format = None;
    min_properties = None;
    max_properties = None;
    required = [];
    properties = Hashtbl.create 0;
    pattern_properties = [];
    property_names = None;
    additional_properties = None;
    dependent_required = [];
    dependent_schemas = [];
    dependencies = [];
    unevaluated_properties = None;
    min_items = None;
    max_items = None;
    unique_items = false;
    min_contains = None;
    max_contains = None;
    contains = None;
    items = None;
    additional_items = None;
    prefix_items = [];
    items2020 = None;
    unevaluated_items = None;
    min_length = None;
    max_length = None;
    pattern = None;
    content_encoding = None;
    content_media_type = None;
    content_schema = None;
    minimum = None;
    maximum = None;
    exclusive_minimum = None;
    exclusive_maximum = None;
    multiple_of = None;
  }

let draft6_validator =
  {
    draft4_validator with
    draft_version = Draft6;
    location = "https://json-schema.org/draft-06/schema";
  }

let draft7_validator =
  {
    draft4_validator with
    draft_version = Draft7;
    location = "https://json-schema.org/draft-07/schema";
  }

let draft2019_09_validator =
  {
    draft4_validator with
    draft_version = Draft2019_09;
    location = "https://json-schema.org/draft/2019-09/schema";
  }

let draft2020_12_validator =
  {
    draft4_validator with
    draft_version = Draft2020_12;
    location = "https://json-schema.org/draft/2020-12/schema";
  }
