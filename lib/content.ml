type decoder = { name : string; func : string -> (bytes, exn) result }

type media_type = {
  name : string;
  json_compatible : bool;
  func : bytes -> bool -> (Yojson.Basic.t option, exn) result;
}

let create_decoder name func = { name; func }

let create_media_type name ~json_compatible func =
  { name; json_compatible; func }

let base64 =
  {
    name = "base64";
    func =
      (fun s ->
        try Ok (Bytes.of_string (Base64.decode_exn s)) with e -> Error e);
  }

let json =
  {
    name = "application/json";
    json_compatible = true;
    func =
      (fun bytes deserialize ->
        if deserialize then
          try
            let s = Bytes.to_string bytes in
            Ok (Some (Yojson.Basic.from_string s))
          with e -> Error e
        else
          try
            let s = Bytes.to_string bytes in
            let _ = Yojson.Basic.from_string s in
            Ok None
          with e -> Error e);
  }
