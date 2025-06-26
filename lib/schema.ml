type schema_index = int
type enum_values = { types : Types.t; values : Yojson.Basic.t list }
type items = Schema_ref of schema_index | Schema_refs of schema_index list
type additional = Bool of bool | Schema_ref of schema_index
type dependency = Props of string list | Schema_ref of schema_index
type dynamic_ref = { sch : schema_index; anchor : string option }

type t = {
  draft_version : Draft.t;
  idx : schema_index;
  location : string;
  resource : schema_index;
  dynamic_anchors : (string, schema_index) Hashtbl.t;
  all_props_evaluated : bool;
  all_items_evaluated : bool;
  num_items_evaluated : int;
  (* type agnostic *)
  boolean : bool option;
  ref_ : schema_index option;
  recursive_ref : schema_index option;
  recursive_anchor : bool;
  dynamic_ref : dynamic_ref option;
  dynamic_anchor : string option;
  types : Types.t;
  enum_ : enum_values option;
  constant : Yojson.Basic.t option;
  not : schema_index option;
  all_of : schema_index list;
  any_of : schema_index list;
  one_of : schema_index list;
  if_ : schema_index option;
  then_ : schema_index option;
  else_ : schema_index option;
  format : Formats.t option;
  (* object *)
  min_properties : int option;
  max_properties : int option;
  required : string list;
  properties : (string, schema_index) Hashtbl.t;
  pattern_properties : (Re.re * schema_index) list;
  property_names : schema_index option;
  additional_properties : additional option;
  dependent_required : (string * string list) list;
  dependent_schemas : (string * schema_index) list;
  dependencies : (string * dependency) list;
  unevaluated_properties : schema_index option;
  (* array *)
  min_items : int option;
  max_items : int option;
  unique_items : bool;
  min_contains : int option;
  max_contains : int option;
  contains : schema_index option;
  items : items option;
  additional_items : additional option;
  prefix_items : schema_index list;
  items2020 : additional option;
  unevaluated_items : schema_index option;
  (* string *)
  min_length : int option;
  max_length : int option;
  pattern : Re.re option;
  pattern_string : string option;
  content_encoding : Content.decoder option;
  content_media_type : Content.media_type option;
  content_schema : schema_index option;
  (* number *)
  minimum : float option;
  maximum : float option;
  exclusive_minimum : float option; (* draft6+: numeric value *)
  exclusive_maximum : float option; (* draft6+: numeric value *)
  exclusive_minimum_draft4 : bool; (* draft4: boolean flag *)
  exclusive_maximum_draft4 : bool; (* draft4: boolean flag *)
  multiple_of : float option;
}

let location schema = schema.location
let draft schema = schema.draft_version
