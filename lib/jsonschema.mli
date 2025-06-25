(** JSON Schema validator supporting drafts 4, 6, 7, 2019-09, and 2020-12 *)

(** {1 Core Types} *)

(** Supported draft versions *)
type draft = Draft4 | Draft6 | Draft7 | Draft2019_09 | Draft2020_12

type schema
(** A compiled JSON schema *)

(** Instance location token *)
type instance_token = Prop of string | Item of int

type instance_location = { tokens : instance_token list }
(** Instance location in the validated document *)

type type_set
(** Set of JSON types *)

(** Validation error kinds *)
type error_kind =
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

type validation_error = {
  schema_url : string;
  instance_location : instance_location;
  kind : error_kind;
  causes : validation_error list;
}
(** Validation error *)

(** Compilation errors *)
type compile_error =
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

type json_pointer
(** JSON pointer for navigating JSON documents *)

(** {1 High-Level API} *)

type validator
(** A reusable validator *)

val validate_file :
  ?draft:draft ->
  schema:string ->
  Yojson.Basic.t ->
  (unit, validation_error) result
(** Validate JSON against a schema from a file/URL *)

val validate_strings :
  ?draft:draft ->
  schema:string ->
  json:string ->
  unit ->
  (unit, validation_error) result
(** Validate JSON string against schema string *)

val create_validator :
  ?draft:draft ->
  ?enable_format_assertions:bool ->
  ?enable_content_assertions:bool ->
  string ->
  (validator, compile_error) result
(** Create a reusable validator for efficiency *)

val validate : validator -> Yojson.Basic.t -> (unit, validation_error) result
(** Validate using a pre-compiled validator *)

val draft4_validator : validator
(** Pre-compiled validators for meta-schemas *)

val draft6_validator : validator
val draft7_validator : validator
val draft2019_09_validator : validator
val draft2020_12_validator : validator

(** {1 Low-Level API} *)

(** {2 Compilation} *)

module Compiler : sig
  type t

  type config = {
    default_draft : draft;
    enable_format_assertions : bool;
    enable_content_assertions : bool;
    custom_formats : Formats.t list;
    custom_decoders : Content.decoder list;
    custom_media_types : Content.media_type list;
    url_loader : Loader.url_loader option;
  }
  (** Compiler configuration *)

  val default_config : config
  (** Default configuration *)

  val create : config -> t
  (** Create a compiler with the given configuration *)

  val create_default : unit -> t
  (** Create a compiler with default configuration *)

  val compile : t -> string -> (schema, compile_error) result
  (** Compile a schema from a location (file path or URL) *)

  val add_resource :
    t -> string -> Yojson.Basic.t -> (unit, compile_error) result
  (** Add a schema resource for reference resolution *)
end

(** {2 Schema Operations} *)

module Schema : sig
  val validate : schema -> Yojson.Basic.t -> (unit, validation_error) result
  (** Validate a JSON value against a compiled schema *)

  val location : schema -> string
  (** Get the schema location/URL *)

  val draft : schema -> draft
  (** Get the draft version of a schema *)
end

(** {2 Types} *)

module Types : sig
  type json_type = Null | Boolean | Number | Integer | String | Array | Object

  val empty : type_set
  val contains : type_set -> json_type -> bool
  val add : type_set -> json_type -> type_set
  val iter : (json_type -> unit) -> type_set -> unit
  val of_list : json_type list -> type_set
  val type_of : Yojson.Basic.t -> json_type
end

(** {2 Output Formats} *)

module Output : sig
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
end

(** {2 Format Validation} *)

module Format : sig
  type t = { name : string; func : Yojson.Basic.t -> (unit, exn) result }

  val create : string -> (Yojson.Basic.t -> (unit, exn) result) -> t
  val regex : t
  val ipv4 : t
  val ipv6 : t
  val hostname : t
  val idn_hostname : t
  val email : t
  val idn_email : t
  val date : t
  val time : t
  val date_time : t
  val duration : t
  val period : t
  val json_pointer : t
  val relative_json_pointer : t
  val uuid : t
  val uri : t
  val iri : t
  val uri_reference : t
  val iri_reference : t
  val uri_template : t
end

(** {2 Content Validation} *)

module Content : sig
  type decoder = { name : string; func : string -> (bytes, exn) result }

  type media_type = {
    name : string;
    json_compatible : bool;
    func : bytes -> bool -> (Yojson.Basic.t option, exn) result;
  }

  val create_decoder : string -> (string -> (bytes, exn) result) -> decoder

  val create_media_type :
    string ->
    json_compatible:bool ->
    (bytes -> bool -> (Yojson.Basic.t option, exn) result) ->
    media_type

  val base64 : decoder
  val json : media_type
end

(** {2 URL Loading} *)

module Loader : sig
  type url_loader = string -> (Yojson.Basic.t, exn) result

  val file_loader : url_loader

  type scheme_url_loader

  val create_scheme_loader : unit -> scheme_url_loader
  val register_scheme : scheme_url_loader -> string -> url_loader -> unit
  val to_url_loader : scheme_url_loader -> url_loader
end

(** {2 Utilities} *)

module Draft : sig
  val from_url : string -> draft option
  val latest : unit -> draft
end

module Json_pointer : sig
  type t = json_pointer

  val root : t
  val of_string : string -> (t, string) result
  val of_tokens : string list -> t
  val to_string : t -> string
  val append : t -> string -> t
  val tokens : t -> string list
  val lookup : t -> Yojson.Basic.t -> Yojson.Basic.t option
end

module Validation_error : sig
  val to_string : validation_error -> string
  val to_string_verbose : validation_error -> string
  val primary_error : validation_error -> error_kind
  val all_errors : validation_error -> (instance_location * error_kind) list
  val is_type_error : validation_error -> bool
  val is_required_error : validation_error -> bool
  val is_format_error : validation_error -> bool
  val missing_properties : validation_error -> string list

  val type_mismatches :
    validation_error -> (instance_location * Types.json_type * type_set) list
end

(** {2 Pretty Printing} *)

val pp_compile_error : Stdlib.Format.formatter -> compile_error -> unit
val pp_validation_error : Stdlib.Format.formatter -> validation_error -> unit

val pp_validation_error_verbose :
  Stdlib.Format.formatter -> validation_error -> unit
