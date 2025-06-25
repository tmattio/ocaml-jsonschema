type t = string

let root = ""

let escape token =
  token |> String.split_on_char '~' |> String.concat "~0"
  |> String.split_on_char '/' |> String.concat "~1"

let unescape token =
  try
    let rec unescape_aux acc remaining =
      match String.index_opt remaining '~' with
      | None -> Ok (acc ^ remaining)
      | Some idx ->
          let prefix = String.sub remaining 0 idx in
          if idx + 1 >= String.length remaining then
            Error "Invalid escape sequence"
          else
            let next_char = remaining.[idx + 1] in
            let replacement, skip =
              match next_char with
              | '0' -> ("~", 2)
              | '1' -> ("/", 2)
              | _ -> ("", 0)
            in
            if skip = 0 then Error "Invalid escape sequence"
            else
              let new_acc = acc ^ prefix ^ replacement in
              let new_remaining =
                String.sub remaining (idx + skip)
                  (String.length remaining - idx - skip)
              in
              unescape_aux new_acc new_remaining
    in
    unescape_aux "" token
  with _ -> Error "Invalid token"

let of_tokens tokens =
  if tokens = [] then root else "/" ^ String.concat "/" (List.map escape tokens)

let of_string str =
  if str = "" then Ok root
  else if str.[0] <> '/' then Error "JSON Pointer must start with '/'"
  else
    (* Validate by attempting to parse *)
    let tokens = String.split_on_char '/' str |> List.tl in
    let validated =
      List.fold_left
        (fun acc token ->
          match acc with
          | Error e -> Error e
          | Ok tokens -> (
              match unescape token with
              | Ok t -> Ok (t :: tokens)
              | Error e -> Error e))
        (Ok []) tokens
    in
    match validated with Ok _ -> Ok str | Error e -> Error e

let to_string t = t

let append t token =
  if t = "" then "/" ^ escape token else t ^ "/" ^ escape token

let tokens t =
  if t = "" then []
  else
    let parts = String.split_on_char '/' t |> List.tl in
    List.filter_map
      (fun part ->
        match unescape part with Ok token -> Some token | Error _ -> None)
      parts

let lookup t json =
  let rec lookup_aux tokens json =
    match (tokens, json) with
    | [], _ -> Some json
    | token :: rest, `Assoc props -> (
        match List.assoc_opt token props with
        | Some value -> lookup_aux rest value
        | None -> None)
    | token :: rest, `List items -> (
        match int_of_string_opt token with
        | Some idx when idx >= 0 && idx < List.length items ->
            lookup_aux rest (List.nth items idx)
        | _ -> None)
    | _ -> None
  in
  lookup_aux (tokens t) json
