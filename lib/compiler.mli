open Error

type t

type config = {
  default_draft : Draft.t;
  enable_format_assertions : bool;
  enable_content_assertions : bool;
  custom_formats : Formats.t list;
  custom_decoders : Content.decoder list;
  custom_media_types : Content.media_type list;
  url_loader : Loader.url_loader option;
}

val default_config : config
val create : config -> t
val create_default : unit -> t
val compile : t -> string -> (Schema.t, compile_error) result

val compile_json :
  t -> string -> Yojson.Basic.t -> (Schema.t, compile_error) result

val add_resource : t -> string -> Yojson.Basic.t -> (unit, compile_error) result
val get_schemas : t -> Validator.schemas
