open Error

let to_string err =
  Printf.sprintf "jsonschema validation failed with %s\n  at '%s': %s"
    err.schema_url
    (Json_pointer.of_tokens
       (List.map
          (function Prop s -> s | Item i -> string_of_int i)
          err.instance_location.tokens))
    (match err.kind with
    | Type _ -> "type mismatch"
    | Required { want } ->
        Printf.sprintf "missing properties %s" (String.concat ", " want)
    | All_of -> "allOf validation failed"
    | Schema { url } -> Printf.sprintf "schema error: %s" url
    | Unevaluated_items { got } -> Printf.sprintf "%d unevaluated items" got
    | _ -> "validation error")

let to_string_verbose err = to_string err (* TODO: implement verbose version *)
let primary_error err = err.kind

let rec all_errors err =
  (err.instance_location, err.kind) :: List.concat_map all_errors err.causes

let is_type_error err = match err.kind with Type _ -> true | _ -> false

let is_required_error err =
  match err.kind with Required _ -> true | _ -> false

let is_format_error err = match err.kind with Format _ -> true | _ -> false

let missing_properties err =
  match err.kind with Required { want } -> want | _ -> []

let type_mismatches err =
  let rec collect err acc =
    let acc' =
      match err.kind with
      | Type { got; want } ->
          (err.instance_location, Types.type_of got, want) :: acc
      | _ -> acc
    in
    List.fold_left (fun acc e -> collect e acc) acc' err.causes
  in
  collect err []
