(* Test runner for JSON Schema Test Suite *)
open Jsonschema

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

let run_test_case ~draft test_group test_case =
  let schema_str = Yojson.Basic.to_string test_group.schema in
  let result =
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

let run_test_group ~draft test_group =
  let results = List.map (run_test_case ~draft test_group) test_group.tests in
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

    let results = List.map (run_test_group ~draft) test_groups in
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
