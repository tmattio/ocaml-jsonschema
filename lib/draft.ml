type t = Draft4 | Draft6 | Draft7 | Draft2019_09 | Draft2020_12

let from_url url =
  let url =
    (* Remove fragment if present *)
    match String.index_opt url '#' with
    | Some idx -> String.sub url 0 idx
    | None -> url
  in
  let url =
    (* Remove scheme *)
    if String.starts_with ~prefix:"http://" url then
      String.sub url 7 (String.length url - 7)
    else if String.starts_with ~prefix:"https://" url then
      String.sub url 8 (String.length url - 8)
    else url
  in
  match url with
  | "json-schema.org/schema" -> Some Draft2020_12
  | "json-schema.org/draft/2020-12/schema" -> Some Draft2020_12
  | "json-schema.org/draft/2019-09/schema" -> Some Draft2019_09
  | "json-schema.org/draft-07/schema" -> Some Draft7
  | "json-schema.org/draft-06/schema" -> Some Draft6
  | "json-schema.org/draft-04/schema" -> Some Draft4
  | _ -> None

let latest () = Draft2020_12
