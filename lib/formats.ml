type t = { name : string; func : Yojson.Basic.t -> (unit, exn) result }

let create name func = { name; func }

(* Email regex - simplified version *)
let email_re =
  Re.compile (Re.Perl.re "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")

(* Date regex: YYYY-MM-DD *)
let date_re = Re.compile (Re.Perl.re "^[0-9]{4}-[0-9]{2}-[0-9]{2}$")

(* Time regex: HH:MM:SS with optional fraction and timezone *)
let time_re =
  Re.compile
    (Re.Perl.re
       "^[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})?$")

(* UUID regex *)
let uuid_re =
  Re.compile
    (Re.Perl.re
       "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")

let validate_regex pattern =
  try
    ignore (Re.Perl.re pattern |> Re.compile);
    Ok ()
  with e -> Error e

let validate_ipv4 str =
  try
    let parts = String.split_on_char '.' str in
    if List.length parts <> 4 then Error (Failure "IPv4 must have 4 parts")
    else
      let valid =
        List.for_all
          (fun part ->
            match int_of_string_opt part with
            | Some n -> n >= 0 && n <= 255
            | None -> false)
          parts
      in
      if valid then Ok () else Error (Failure "Invalid IPv4 octet")
  with e -> Error e

let validate_ipv6 str =
  (* Simplified IPv6 validation *)
  let parts = String.split_on_char ':' str in
  if List.length parts > 8 then Error (Failure "Too many IPv6 parts") else Ok ()

let validate_hostname str =
  let valid_char c =
    (c >= 'a' && c <= 'z')
    || (c >= 'A' && c <= 'Z')
    || (c >= '0' && c <= '9')
    || c = '-' || c = '.'
  in
  if String.length str > 253 then Error (Failure "Hostname too long")
  else if String.for_all valid_char str then Ok ()
  else Error (Failure "Invalid hostname character")

let validate_email str =
  if Re.execp email_re str then Ok ()
  else Error (Failure "Invalid email format")

let validate_date str =
  if Re.execp date_re str then
    (* Additional validation for valid dates *)
    try
      let _year = int_of_string (String.sub str 0 4) in
      let month = int_of_string (String.sub str 5 2) in
      let day = int_of_string (String.sub str 8 2) in
      if month < 1 || month > 12 then Error (Failure "Invalid month")
      else if day < 1 || day > 31 then Error (Failure "Invalid day")
      else Ok ()
    with e -> Error e
  else Error (Failure "Invalid date format")

let validate_time str =
  if Re.execp time_re str then Ok () else Error (Failure "Invalid time format")

let validate_uri str =
  try
    let _ = Uri.of_string str in
    if Uri.scheme (Uri.of_string str) = None then
      Error (Failure "URI must have scheme")
    else Ok ()
  with e -> Error e

let validate_uuid str =
  if Re.execp uuid_re str then Ok () else Error (Failure "Invalid UUID format")

(* Format validators *)
let regex =
  create "regex" (function `String s -> validate_regex s | _ -> Ok ())

let ipv4 = create "ipv4" (function `String s -> validate_ipv4 s | _ -> Ok ())
let ipv6 = create "ipv6" (function `String s -> validate_ipv6 s | _ -> Ok ())

let hostname =
  create "hostname" (function `String s -> validate_hostname s | _ -> Ok ())

let idn_hostname = hostname (* Simplified for now *)

let email =
  create "email" (function `String s -> validate_email s | _ -> Ok ())

let idn_email = email (* Simplified for now *)
let date = create "date" (function `String s -> validate_date s | _ -> Ok ())
let time = create "time" (function `String s -> validate_time s | _ -> Ok ())

let date_time =
  create "date-time" (function
    | `String s ->
        if String.length s >= 19 && (s.[10] = 'T' || s.[10] = 't') then
          let date_part = String.sub s 0 10 in
          let time_part = String.sub s 11 (String.length s - 11) in
          match (validate_date date_part, validate_time time_part) with
          | Ok (), Ok () -> Ok ()
          | Error e, _ | _, Error e -> Error e
        else Error (Failure "Invalid date-time format")
    | _ -> Ok ())

let duration = create "duration" (fun _ -> Ok ()) (* TODO: implement *)
let period = create "period" (fun _ -> Ok ()) (* TODO: implement *)

let json_pointer =
  create "json-pointer" (function
    | `String s -> (
        match Json_pointer.of_string s with
        | Ok _ -> Ok ()
        | Error e -> Error (Failure e))
    | _ -> Ok ())

let relative_json_pointer = create "relative-json-pointer" (fun _ -> Ok ())
(* TODO *)

let uri = create "uri" (function `String s -> validate_uri s | _ -> Ok ())
let iri = uri (* Simplified for now *)
let uri_reference = create "uri-reference" (fun _ -> Ok ()) (* TODO *)
let iri_reference = uri_reference (* Simplified for now *)
let uri_template = create "uri-template" (fun _ -> Ok ()) (* TODO *)
let uuid = create "uuid" (function `String s -> validate_uuid s | _ -> Ok ())
