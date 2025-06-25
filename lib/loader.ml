type url_loader = string -> (Yojson.Basic.t, exn) result

let file_loader url =
  try
    let uri = Uri.of_string url in
    match Uri.scheme uri with
    | Some "file" ->
        let path = Uri.path uri in
        let json = Yojson.Basic.from_file path in
        Ok json
    | _ -> Error (Failure "Not a file URL")
  with e -> Error e

type scheme_url_loader = { loaders : (string, url_loader) Hashtbl.t }

let create_scheme_loader () = { loaders = Hashtbl.create 8 }

let register_scheme loader scheme url_loader =
  Hashtbl.replace loader.loaders scheme url_loader

let to_url_loader loader url =
  try
    let uri = Uri.of_string url in
    match Uri.scheme uri with
    | None -> Error (Failure "No scheme in URL")
    | Some scheme -> (
        match Hashtbl.find_opt loader.loaders scheme with
        | None -> Error (Failure ("Unsupported scheme: " ^ scheme))
        | Some load -> load url)
  with e -> Error e
