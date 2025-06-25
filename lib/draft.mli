type t = Draft4 | Draft6 | Draft7 | Draft2019_09 | Draft2020_12

val from_url : string -> t option
val latest : unit -> t
