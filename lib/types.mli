(** JSON types for JSON Schema *)
type json_type = Null | Boolean | Number | Integer | String | Array | Object

type t
(** Set of JSON types - using bit flags for efficiency *)

val empty : t
val contains : t -> json_type -> bool
val add : t -> json_type -> t
val iter : (json_type -> unit) -> t -> unit
val of_list : json_type list -> t
val type_of : Yojson.Basic.t -> json_type
