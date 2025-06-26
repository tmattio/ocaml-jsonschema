(* Test runner for JSON Schema Test Suite *)
open Jsonschema

(* Load the test URL loader *)
module Test_url_loader = struct
  let test_remotes_dir = "JSON-Schema-Test-Suite/remotes"

  (* Map localhost:1234 URLs to local test files *)
  let test_url_loader url =
    try
      let uri = Uri.of_string url in
      match (Uri.scheme uri, Uri.host uri) with
      | Some "http", Some "localhost" when Uri.port uri = Some 1234 ->
          (* Extract path and map to test remotes directory *)
          let path = Uri.path uri in
          (* Remove leading slash if present *)
          let path =
            if String.starts_with ~prefix:"/" path then
              String.sub path 1 (String.length path - 1)
            else path
          in
          let file_path = Filename.concat test_remotes_dir path in
          let json = Yojson.Basic.from_file file_path in
          Ok json
      | _ -> Error (Failure ("Unsupported test URL: " ^ url))
    with e -> Error e

  (* Create a scheme loader that handles test URLs *)
  let create_test_loader () =
    let loader = Loader.create_scheme_loader () in
    Loader.register_scheme loader "http" test_url_loader;
    Loader.register_scheme loader "https" test_url_loader;
    Loader.register_scheme loader "file" Loader.file_loader;
    Loader.to_url_loader loader
end

type test_case = { description : string; data : Yojson.Basic.t; valid : bool }

type test_group = {
  description : string;
  schema : Yojson.Basic.t;
  tests : test_case list;
}

let parse_test_case json =
  let open Yojson.Basic.Util in
  {
    description = json |> member "description" |> to_string;
    data = json |> member "data";
    valid = json |> member "valid" |> to_bool;
  }

let parse_test_group json =
  let open Yojson.Basic.Util in
  {
    description = json |> member "description" |> to_string;
    schema = json |> member "schema";
    tests = json |> member "tests" |> to_list |> List.map parse_test_case;
  }

let run_test_case ~draft ~needs_url_loader test_group test_case =
  let result =
    if needs_url_loader then
      (* Create validator with URL loader *)
      let url_loader = Test_url_loader.create_test_loader () in
      match
        create_validator_with_loader ?draft ~url_loader
          ~schema:test_group.schema ()
      with
      | Error _ ->
          Error
            {
              schema_url = "inline://schema";
              instance_location = { tokens = [] };
              kind = Schema { url = "Schema compilation failed" };
              causes = [];
            }
      | Ok validator -> validate validator test_case.data
    else
      (* For non-remote tests, use the simple string-based approach *)
      let schema_str = Yojson.Basic.to_string test_group.schema in
      validate_strings ?draft ~schema:schema_str
        ~json:(Yojson.Basic.to_string test_case.data)
        ()
  in
  match (result, test_case.valid) with
  | Ok (), true -> `Pass
  | Error _, false -> `Pass
  | Ok (), false ->
      `Fail (Printf.sprintf "Expected invalid, but validation passed")
  | Error err, true ->
      `Fail
        (Printf.sprintf "Expected valid, but got: %s"
           (Validation_error.to_string err))

let run_test_group ~draft ~needs_url_loader test_group =
  let results =
    List.map
      (run_test_case ~draft ~needs_url_loader test_group)
      test_group.tests
  in
  let passed = List.filter (fun r -> r = `Pass) results |> List.length in
  let total = List.length results in

  if passed = total then
    Printf.printf "  ✓ %s (%d/%d)\n" test_group.description passed total
  else Printf.printf "  ✗ %s (%d/%d)\n" test_group.description passed total;

  (* Print failures *)
  List.iteri
    (fun i result ->
      match result with
      | `Fail msg ->
          Printf.printf "    - Test %d (%s): %s\n" (i + 1)
            (List.nth test_group.tests i).description msg
      | _ -> ())
    results;

  passed = total

let run_test_file ~draft filename =
  try
    let json = Yojson.Basic.from_file filename in
    let test_groups =
      json |> Yojson.Basic.Util.to_list |> List.map parse_test_group
    in

    Printf.printf "\nRunning tests from %s:\n" filename;

    (* Check if this test file needs URL loader (for remote refs) *)
    let needs_url_loader =
      Filename.basename filename = "refRemote.json"
      || String.contains filename '$' (* Some other files might also need it *)
    in

    let results =
      List.map (run_test_group ~draft ~needs_url_loader) test_groups
    in
    let passed_groups = List.filter (fun x -> x) results |> List.length in
    let total_groups = List.length results in

    Printf.printf "Summary: %d/%d test groups passed\n" passed_groups
      total_groups;

    passed_groups = total_groups
  with
  | Yojson.Json_error msg ->
      Printf.eprintf "Error parsing JSON: %s\n" msg;
      false
  | e ->
      Printf.eprintf "Error: %s\n" (Printexc.to_string e);
      false

let () =
  let draft = ref None in
  let files = ref [] in

  let specs =
    [
      ("--draft4", Arg.Unit (fun () -> draft := Some Draft4), " Use Draft 4");
      ("--draft6", Arg.Unit (fun () -> draft := Some Draft6), " Use Draft 6");
      ("--draft7", Arg.Unit (fun () -> draft := Some Draft7), " Use Draft 7");
      ( "--draft2019-09",
        Arg.Unit (fun () -> draft := Some Draft2019_09),
        " Use Draft 2019-09" );
      ( "--draft2020-12",
        Arg.Unit (fun () -> draft := Some Draft2020_12),
        " Use Draft 2020-12" );
    ]
  in

  Arg.parse specs
    (fun f -> files := f :: !files)
    "Usage: test_runner [options] <test_files...>";

  if !files = [] then (
    Printf.eprintf "No test files specified\n";
    exit 1);

  let all_passed =
    List.fold_left
      (fun acc file -> run_test_file ~draft:!draft file && acc)
      true (List.rev !files)
  in

  exit (if all_passed then 0 else 1)
