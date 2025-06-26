(** Instance location token *)
type instance_token = Prop of string | Item of int [@@deriving of_yojson]

type instance_location = { tokens : instance_token list } [@@deriving of_yojson]

(** Validation error kinds *)
type error_kind =
  | Group
  | Schema of { url : string }
  | Content_schema
  | Property_name of { prop : string }
  | Reference of { kw : string; url : string }
  | Ref_cycle of { url : string; kw_loc1 : string; kw_loc2 : string }
  | False_schema
  | Type of { got : Yojson.Basic.t; want : Types.t }
  | Enum of { want : Yojson.Basic.t list }
  | Const of { want : Yojson.Basic.t }
  | Format of { got : Yojson.Basic.t; want : string; err : exn }
  | Min_properties of { got : int; want : int }
  | Max_properties of { got : int; want : int }
  | Additional_properties of { got : string list }
  | Unevaluated_properties of { got : string list }
  | Unevaluated_items of { got : int }
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
