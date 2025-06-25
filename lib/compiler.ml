type config = {
  default_draft : Draft.t;
  enable_format_assertions : bool;
  enable_content_assertions : bool;
  custom_formats : Formats.t list;
  custom_decoders : Content.decoder list;
  custom_media_types : Content.media_type list;
  url_loader : Loader.url_loader option;
}

type t = { config : config; schemas : Validator.schemas }

let default_config =
  {
    default_draft = Draft2020_12;
    enable_format_assertions = true;
    enable_content_assertions = true;
    custom_formats = [];
    custom_decoders = [];
    custom_media_types = [];
    url_loader = None;
  }

let create config = { config; schemas = Validator.create_schemas () }
let create_default () = create default_config

let compile t location =
  (* TODO: implement actual compilation logic *)
  let schema =
    {
      Schema.draft_version = t.config.default_draft;
      idx = 0;
      location;
      resource = 0;
      dynamic_anchors = Hashtbl.create 8;
      all_props_evaluated = false;
      all_items_evaluated = false;
      num_items_evaluated = 0;
      boolean = None;
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
      properties = Hashtbl.create 8;
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
  in
  Validator.insert_schemas t.schemas [ location ] [ schema ];
  Ok schema

let add_resource _t _location _json =
  (* TODO: implement resource addition *)
  Ok ()
