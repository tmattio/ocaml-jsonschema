(** JSON types for JSON Schema *)
type json_type = Null | Boolean | Number | Integer | String | Array | Object

type t = int
(** Set of JSON types - using bit flags for efficiency *)

let null_bit = 1
let boolean_bit = 2
let number_bit = 4
let integer_bit = 8
let string_bit = 16
let array_bit = 32
let object_bit = 64
let empty = 0
let is_empty t = t = 0

let to_bit = function
  | Null -> null_bit
  | Boolean -> boolean_bit
  | Number -> number_bit
  | Integer -> integer_bit
  | String -> string_bit
  | Array -> array_bit
  | Object -> object_bit

let contains set typ = set land to_bit typ <> 0
let add set typ = set lor to_bit typ

let iter f set =
  if contains set Null then f Null;
  if contains set Boolean then f Boolean;
  if contains set Number then f Number;
  if contains set Integer then f Integer;
  if contains set String then f String;
  if contains set Array then f Array;
  if contains set Object then f Object

let of_list types = List.fold_left add empty types

let type_of = function
  | `Null -> Null
  | `Bool _ -> Boolean
  | `Int _ -> Integer
  | `Float f when Float.is_integer f -> Integer
  | `Float _ -> Number
  | `String _ -> String
  | `List _ -> Array
  | `Assoc _ -> Object

let _type_of_extended json =
  match type_of json with
  | Integer -> Number (* Integer is also a Number in JSON Schema *)
  | t -> t
