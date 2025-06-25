type url_loader = string -> (Yojson.Basic.t, exn) result

val file_loader : url_loader

type scheme_url_loader

val create_scheme_loader : unit -> scheme_url_loader
val register_scheme : scheme_url_loader -> string -> url_loader -> unit
val to_url_loader : scheme_url_loader -> url_loader
