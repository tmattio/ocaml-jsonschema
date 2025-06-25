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
