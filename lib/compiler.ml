type config = {
  default_draft : Draft.t;
  enable_format_assertions : bool;
  enable_content_assertions : bool;
  custom_formats : Formats.t list;
  custom_decoders : Content.decoder list;
  custom_media_types : Content.media_type list;
  url_loader : Loader.url_loader option;
}

type t = { config : config; schemas : Validator.schemas }

let default_config =
  {
    default_draft = Draft2020_12;
    enable_format_assertions = true;
    enable_content_assertions = true;
    custom_formats = [];
    custom_decoders = [];
    custom_media_types = [];
    url_loader = None;
  }

let create config = { config; schemas = Validator.create_schemas () }
let create_default () = create default_config

let find_format name =
  let formats =
    [
      ("email", Formats.email);
      ("idn-email", Formats.idn_email);
      ("date", Formats.date);
      ("date-time", Formats.date_time);
      ("time", Formats.time);
      ("duration", Formats.duration);
      ("period", Formats.period);
      ("hostname", Formats.hostname);
      ("idn-hostname", Formats.idn_hostname);
      ("ipv4", Formats.ipv4);
      ("ipv6", Formats.ipv6);
      ("uri", Formats.uri);
      ("uri-reference", Formats.uri_reference);
      ("iri", Formats.iri);
      ("iri-reference", Formats.iri_reference);
      ("uri-template", Formats.uri_template);
      ("uuid", Formats.uuid);
      ("json-pointer", Formats.json_pointer);
      ("relative-json-pointer", Formats.relative_json_pointer);
      ("regex", Formats.regex);
    ]
  in
  List.find_opt (fun (n, _) -> n = name) formats |> Option.map snd

(* Helper functions to avoid exceptions *)
let member_as_int_or_truncated_float name json =
  try
    let value = Yojson.Basic.Util.member name json in
    match value with
    | `Int i -> Some i
    | `Float f -> Some (int_of_float (floor f))
    | _ -> None
  with _ -> None

let member_as_float name json =
  try
    let value = Yojson.Basic.Util.member name json in
    match value with
    | `Int i -> Some (float_of_int i)
    | `Float f -> Some f
    | _ -> None
  with _ -> None

let member_as_string name json =
  try Some (Yojson.Basic.Util.member name json |> Yojson.Basic.Util.to_string)
  with Yojson.Basic.Util.Type_error _ -> None

let member_as_bool name json =
  try Some (Yojson.Basic.Util.member name json |> Yojson.Basic.Util.to_bool)
  with Yojson.Basic.Util.Type_error _ -> None

let member_as_list name json =
  try Some (Yojson.Basic.Util.member name json |> Yojson.Basic.Util.to_list)
  with Yojson.Basic.Util.Type_error _ -> None

let member_as_string_list name json =
  try
    Some
      (Yojson.Basic.Util.member name json
      |> Yojson.Basic.Util.to_list
      |> List.map Yojson.Basic.Util.to_string)
  with Yojson.Basic.Util.Type_error _ -> None

let member_opt name json =
  match json with
  | `Assoc assoc when List.mem_assoc name assoc -> Some (List.assoc name assoc)
  | _ -> None

let parse_type_constraint json =
  try
    match json with
    | `String s -> (
        match s with
        | "null" -> Types.add Types.empty Types.Null
        | "boolean" -> Types.add Types.empty Types.Boolean
        | "object" -> Types.add Types.empty Types.Object
        | "array" -> Types.add Types.empty Types.Array
        | "number" -> Types.add Types.empty Types.Number
        | "string" -> Types.add Types.empty Types.String
        | "integer" -> Types.add Types.empty Types.Integer
        | _ -> Types.empty)
    | `List types ->
        List.fold_left
          (fun acc t ->
            match t with
            | `String "null" -> Types.add acc Types.Null
            | `String "boolean" -> Types.add acc Types.Boolean
            | `String "object" -> Types.add acc Types.Object
            | `String "array" -> Types.add acc Types.Array
            | `String "number" -> Types.add acc Types.Number
            | `String "string" -> Types.add acc Types.String
            | `String "integer" -> Types.add acc Types.Integer
            | _ -> acc)
          Types.empty types
    | _ -> Types.empty
  with _ -> Types.empty

(* Helper to decode URL-encoded characters in refs *)
let url_decode s =
  let rec decode acc i =
    if i >= String.length s then String.concat "" (List.rev acc)
    else if s.[i] = '%' && i + 2 < String.length s then
      try
        let hex = String.sub s (i + 1) 2 in
        let code = int_of_string ("0x" ^ hex) in
        decode (String.make 1 (Char.chr code) :: acc) (i + 3)
      with _ -> decode (String.make 1 s.[i] :: acc) (i + 1)
    else decode (String.make 1 s.[i] :: acc) (i + 1)
  in
  decode [] 0

(* Helper to resolve a URI reference against a base URI *)
let resolve_uri base ref_str =
  if
    String.starts_with ~prefix:"http://" ref_str
    || String.starts_with ~prefix:"https://" ref_str
    || String.starts_with ~prefix:"file://" ref_str
  then
    (* Absolute URI *)
    ref_str
  else if String.starts_with ~prefix:"#" ref_str then
    (* Fragment-only reference *)
    let base_without_fragment =
      match String.index_opt base '#' with
      | Some idx -> String.sub base 0 idx
      | None -> base
    in
    base_without_fragment ^ ref_str
  else
    (* Relative reference *)
    let base_without_fragment =
      match String.index_opt base '#' with
      | Some idx -> String.sub base 0 idx
      | None -> base
    in
    (* Remove filename from base if present *)
    let base_dir =
      match String.rindex_opt base_without_fragment '/' with
      | Some idx -> String.sub base_without_fragment 0 (idx + 1)
      | None -> base_without_fragment
    in
    base_dir ^ ref_str

(* Compile a sub-schema and return its index *)
let rec compile_subschema t root_json base_uri pointer json =
  (* Process any id field to update the base URI for this schema and its children *)
  let schema_id = member_as_string "id" json in
  let current_base_uri =
    match schema_id with
    | Some id_str -> resolve_uri base_uri id_str
    | None -> base_uri
  in

  let sub_location =
    if pointer = "" then current_base_uri else current_base_uri ^ "#" ^ pointer
  in
  (* DEBUG: Printf.printf "compile_subschema at pointer='%s', base_uri='%s', current_base_uri='%s', sub_location='%s'\n" pointer base_uri current_base_uri sub_location; *)
  (* Check if we've already compiled this schema *)
  match Validator.get_schema_by_loc t.schemas sub_location with
  | Some schema -> schema.Schema.idx
  | None -> (
      let compile_new_schema () =
        (* Allocate an index for this schema *)
        let idx = List.length Validator.(t.schemas.list) in
        (* Create a placeholder to prevent infinite recursion *)
        let placeholder =
          {
            Schema.draft_version = t.config.default_draft;
            idx;
            location = sub_location;
            resource = 0;
            dynamic_anchors = Hashtbl.create 0;
            all_props_evaluated = false;
            all_items_evaluated = false;
            num_items_evaluated = 0;
            boolean = None;
            ref_ = None;
            recursive_ref = None;
            recursive_anchor = false;
            dynamic_ref = None;
            dynamic_anchor = None;
            types = Types.empty;
            enum_ = None;
            constant = None;
            not = None;
            all_of = [];
            any_of = [];
            one_of = [];
            if_ = None;
            then_ = None;
            else_ = None;
            format = None;
            min_properties = None;
            max_properties = None;
            required = [];
            properties = Hashtbl.create 0;
            pattern_properties = [];
            property_names = None;
            additional_properties = None;
            dependent_required = [];
            dependent_schemas = [];
            dependencies = [];
            unevaluated_properties = None;
            min_items = None;
            max_items = None;
            unique_items = false;
            min_contains = None;
            max_contains = None;
            contains = None;
            items = None;
            additional_items = None;
            prefix_items = [];
            items2020 = None;
            unevaluated_items = None;
            min_length = None;
            max_length = None;
            pattern = None;
            pattern_string = None;
            content_encoding = None;
            content_media_type = None;
            content_schema = None;
            minimum = None;
            maximum = None;
            exclusive_minimum = None;
            exclusive_maximum = None;
            exclusive_minimum_draft4 = false;
            exclusive_maximum_draft4 = false;
            multiple_of = None;
          }
        in
        let locations =
          [ sub_location ]
          @
          match member_as_string "id" json with
          | Some id_str when String.contains id_str '#' ->
              (* Also register by the full ID *)
              [ resolve_uri base_uri id_str ]
          | Some id_str ->
              (* Register non-fragment IDs too *)
              let full_id = resolve_uri base_uri id_str in
              if full_id <> sub_location then [ full_id ] else []
          | _ -> []
        in
        (* DEBUG: Printf.printf "Registering schema idx=%d at locations: %s\n" idx (String.concat ", " locations); *)
        Validator.insert_schemas t.schemas locations
          (List.map (fun _ -> placeholder) locations);
        (* Now compile the actual schema *)
        let compiled =
          compile_schema_impl t root_json base_uri idx pointer json
        in
        (* Update the placeholder with the compiled schema *)
        Validator.update_schema t.schemas idx compiled;

        (* Register any anchors *)
        (match member_as_string "$anchor" json with
        | Some anchor ->
            let anchor_location = current_base_uri ^ "#" ^ anchor in
            Validator.insert_schemas t.schemas [ anchor_location ] [ compiled ]
        | None -> ());

        (* Register dynamic anchor *)
        (match member_as_string "$dynamicAnchor" json with
        | Some anchor ->
            let anchor_location = current_base_uri ^ "#" ^ anchor in
            Validator.insert_schemas t.schemas [ anchor_location ] [ compiled ]
        | None -> ());

        idx
      in

      (* Also check if this schema has an id that we've compiled *)
      match member_as_string "id" json with
      | Some id_str when String.contains id_str '#' -> (
          (* This is a location-independent identifier *)
          let full_id = resolve_uri base_uri id_str in
          match Validator.get_schema_by_loc t.schemas full_id with
          | Some schema -> schema.Schema.idx
          | None -> compile_new_schema ())
      | _ -> compile_new_schema ())

and compile_schema_impl t root_json base_uri idx pointer json =
  (* Detect draft version from $schema if present *)
  let draft_version =
    match member_as_string "$schema" json with
    | Some schema_url -> (
        match Draft.from_url schema_url with
        | Some draft -> draft
        | None -> t.config.default_draft)
    | None -> t.config.default_draft
  in
  (* Process any id field to update the base URI for this schema *)
  let schema_id = member_as_string "id" json in
  let current_base_uri =
    match schema_id with
    | Some id_str -> resolve_uri base_uri id_str
    | None -> base_uri
  in
  (* For $ref resolution, use parent's base URI if both id and $ref are present *)
  let ref_base_uri =
    match (member_as_string "$ref" json, schema_id) with
    | Some _, Some _ ->
        (* DEBUG: Printf.printf "Both $ref and id present, using parent base_uri='%s' instead of current='%s'\n" base_uri current_base_uri; *)
        base_uri
        (* Use parent's base URI *)
    | _ -> current_base_uri (* Use current base URI *)
  in

  (* Helper to compile a list of sub-schemas *)
  let compile_schema_list schemas pointer_base =
    List.mapi
      (fun i schema_json ->
        (* For subschemas, always use current_base_uri as the base *)
        (* The compile_subschema function will handle the special case of $ref + id *)
        let full_pointer = pointer_base ^ "/" ^ string_of_int i in
        compile_subschema t root_json current_base_uri full_pointer schema_json)
      schemas
  in

  (* Helper to compile object properties *)
  let compile_properties props_json =
    let props_table = Hashtbl.create 8 in
    (match props_json with
    | `Assoc props ->
        List.iter
          (fun (name, schema_json) ->
            let full_pointer = pointer ^ "/properties/" ^ name in
            let idx =
              compile_subschema t root_json current_base_uri full_pointer
                schema_json
            in
            Hashtbl.add props_table name idx)
          props
    | _ -> ());
    props_table
  in

  (* Compile definitions *)
  let compile_definitions () =
    match member_opt "definitions" json with
    | Some (`Assoc defs) ->
        List.iter
          (fun (name, def_json) ->
            let full_pointer = pointer ^ "/definitions/" ^ name in
            let _def_idx =
              compile_subschema t root_json current_base_uri full_pointer
                def_json
            in
            (* DEBUG: Printf.printf "Compiled definition '%s' at idx=%d, pointer=%s\n" name _def_idx full_pointer; *)
            ())
          defs
    | _ -> ()
  in

  (* Also compile $defs (draft 2019-09 and later) *)
  let compile_defs () =
    match member_opt "$defs" json with
    | Some (`Assoc defs) ->
        List.iter
          (fun (name, def_json) ->
            let full_pointer = pointer ^ "/$defs/" ^ name in
            let _def_idx =
              compile_subschema t root_json current_base_uri full_pointer
                def_json
            in
            (* DEBUG: Printf.printf "Compiled definition '%s' at idx=%d, pointer=%s\n" name _def_idx full_pointer; *)
            ())
          defs
    | _ -> ()
  in

  (* Resolve JSON pointer to find the referenced schema *)
  let resolve_json_pointer root_json pointer =
    let pointer_tokens = Json_pointer.tokens pointer in
    let rec resolve json = function
      | [] -> Some json
      | token :: rest -> (
          match json with
          | `Assoc props -> (
              match List.assoc_opt token props with
              | Some v -> resolve v rest
              | None -> None)
          | `List items -> (
              try
                let idx = int_of_string token in
                if idx >= 0 && idx < List.length items then
                  resolve (List.nth items idx) rest
                else None
              with _ -> None)
          | _ -> None)
    in
    resolve root_json pointer_tokens
  in

  (* Process $ref *)
  let process_ref ref_str =
    (* Decode any URL-encoded characters *)
    let ref_str = url_decode ref_str in

    (* Resolve the reference against the ref base URI *)
    let resolved_ref = resolve_uri ref_base_uri ref_str in
    (* DEBUG: Printf.printf "Resolving $ref '%s' against base '%s' = '%s'\n" ref_str ref_base_uri resolved_ref; *)

    (* Check if it's a known remote schema *)
    if
      String.starts_with ~prefix:"http://json-schema.org/" resolved_ref
      || String.starts_with ~prefix:"https://json-schema.org/" resolved_ref
    then
      (* For now, we'll handle the draft schema as a special case *)
      if
        Re.execp
          (Re.compile (Re.Perl.re ".*draft-0[467]/schema.*"))
          resolved_ref
      then
        (* Return a reference to a meta-schema (simplified for now) *)
        None (* This would need proper meta-schema compilation *)
      else None
    else if String.starts_with ~prefix:"#" ref_str then
      (* Fragment reference *)
      if ref_str = "#" then Some 0 (* Reference to root schema *)
      else if String.starts_with ~prefix:"#/" ref_str then
        (* JSON pointer reference *)
        let pointer = String.sub ref_str 1 (String.length ref_str - 1) in
        (* Decode the pointer tokens *)
        let pointer = url_decode pointer in
        (* Resolve the JSON pointer to find the referenced schema *)
        match resolve_json_pointer root_json pointer with
        | Some ref_json ->
            (* Compile the referenced schema *)
            Some
              (compile_subschema t root_json current_base_uri pointer ref_json)
        | None -> None
      else
        (* Fragment identifier (e.g., #foo) - look for schema with matching id *)
        let target_id = resolved_ref in
        match Validator.get_schema_by_loc t.schemas target_id with
        | Some schema -> Some schema.Schema.idx
        | None -> None
    else
      (* Handle external references *)
      let uri = Uri.of_string resolved_ref in
      let base_url, fragment =
        match Uri.fragment uri with
        | Some frag ->
            let uri_without_frag = Uri.with_fragment uri None in
            (Uri.to_string uri_without_frag, Some frag)
        | None -> (resolved_ref, None)
      in

      (* First check if we already have this schema loaded *)
      match Validator.get_schema_by_loc t.schemas base_url with
      | Some schema -> (
          (* Schema already loaded, handle fragment if present *)
          match fragment with
          | None -> Some schema.Schema.idx
          | Some frag -> (
              if String.starts_with ~prefix:"/" frag then
                (* JSON pointer in fragment *)
                match Validator.get_schema_by_loc t.schemas resolved_ref with
                | Some s -> Some s.Schema.idx
                | None -> None
              else
                (* Named anchor *)
                match Validator.get_schema_by_loc t.schemas resolved_ref with
                | Some s -> Some s.Schema.idx
                | None -> None))
      | None -> (
          (* Need to load the schema *)
          match Uri.scheme uri with
          | Some ("http" | "https") -> (
              match t.config.url_loader with
              | None -> None (* No loader configured *)
              | Some loader -> (
                  match loader base_url with
                  | Error _ -> None
                  | Ok loaded_json -> (
                      (* Add the loaded schema as a resource *)
                      try
                        (* Compile the loaded schema with itself as root *)
                        let loaded_idx =
                          compile_subschema t loaded_json base_url ""
                            loaded_json
                        in
                        (* If there's a fragment, resolve it *)
                        match fragment with
                        | None -> Some loaded_idx
                        | Some frag -> (
                            if String.starts_with ~prefix:"/" frag then
                              (* JSON pointer in fragment *)
                              match
                                Validator.get_schema_by_loc t.schemas
                                  resolved_ref
                              with
                              | Some s -> Some s.Schema.idx
                              | None -> None
                            else
                              (* Named anchor *)
                              match
                                Validator.get_schema_by_loc t.schemas
                                  resolved_ref
                              with
                              | Some s -> Some s.Schema.idx
                              | None -> None)
                      with _ -> None)))
          | _ -> (
              (* For relative refs like "node" or "tree", check if there's a schema with that id *)
              let full_uri = resolve_uri current_base_uri ref_str in
              match Validator.get_schema_by_loc t.schemas full_uri with
              | Some schema ->
                  (* DEBUG: Printf.printf "Found schema for '%s' at idx=%d\n" full_uri schema.Schema.idx; *)
                  Some schema.Schema.idx
              | None ->
                  (* DEBUG: Printf.printf "No schema found for '%s'\n" full_uri; *)
                  None))
  in

  (* Compile definitions early so they're available for $ref resolution *)
  compile_definitions ();
  compile_defs ();

  let ref_ =
    match member_as_string "$ref" json with
    | Some ref_str -> process_ref ref_str
    | None -> None
  in

  {
    Schema.draft_version;
    idx;
    location =
      (match List.nth_opt t.schemas.list idx with
      | Some s -> s.Schema.location
      | None -> current_base_uri);
    resource = 0;
    dynamic_anchors = Hashtbl.create 8;
    all_props_evaluated = false;
    all_items_evaluated = false;
    num_items_evaluated = 0;
    boolean = (match json with `Bool b -> Some b | _ -> None);
    ref_;
    recursive_ref =
      (match member_as_string "$recursiveRef" json with
      | Some ref_str -> process_ref ref_str
      | None -> None);
    recursive_anchor =
      (match member_as_bool "$recursiveAnchor" json with
      | Some b -> b
      | None -> false);
    dynamic_ref =
      (match member_as_string "$dynamicRef" json with
      | Some ref_str -> (
          (* For now, treat $dynamicRef like $ref *)
          (* TODO: Implement proper dynamic resolution *)
          match process_ref ref_str with
          | Some idx -> Some { Schema.sch = idx; anchor = None }
          | None -> None)
      | None -> None);
    dynamic_anchor = member_as_string "$dynamicAnchor" json;
    types =
      (match member_opt "type" json with
      | Some type_json -> parse_type_constraint type_json
      | None -> Types.empty);
    enum_ =
      (match member_as_list "enum" json with
      | Some values ->
          let types =
            List.fold_left
              (fun acc v -> Types.add acc (Types.type_of v))
              Types.empty values
          in
          Some { Schema.types; values }
      | None -> None);
    constant = member_opt "const" json;
    not =
      (match member_opt "not" json with
      | Some schema_json ->
          Some
            (compile_subschema t root_json current_base_uri (pointer ^ "/not")
               schema_json)
      | None -> None);
    all_of =
      (match member_as_list "allOf" json with
      | Some schemas ->
          let indices = compile_schema_list schemas (pointer ^ "/allOf") in
          (* Check for self-reference *)
          if List.mem idx indices then
            Printf.eprintf "WARNING: Schema %d references itself in allOf!\n"
              idx;
          indices
      | None -> []);
    any_of =
      (match member_as_list "anyOf" json with
      | Some schemas -> compile_schema_list schemas (pointer ^ "/anyOf")
      | None -> []);
    one_of =
      (match member_as_list "oneOf" json with
      | Some schemas -> compile_schema_list schemas (pointer ^ "/oneOf")
      | None -> []);
    if_ =
      (match member_opt "if" json with
      | Some schema_json ->
          Some
            (compile_subschema t root_json current_base_uri (pointer ^ "/if")
               schema_json)
      | None -> None);
    then_ =
      (match member_opt "then" json with
      | Some schema_json ->
          Some
            (compile_subschema t root_json current_base_uri (pointer ^ "/then")
               schema_json)
      | None -> None);
    else_ =
      (match member_opt "else" json with
      | Some schema_json ->
          Some
            (compile_subschema t root_json current_base_uri (pointer ^ "/else")
               schema_json)
      | None -> None);
    format =
      (match member_as_string "format" json with
      | Some format_name -> find_format format_name
      | None -> None);
    min_properties = member_as_int_or_truncated_float "minProperties" json;
    max_properties = member_as_int_or_truncated_float "maxProperties" json;
    required = member_as_string_list "required" json |> Option.value ~default:[];
    properties =
      (match member_opt "properties" json with
      | Some props -> compile_properties props
      | None -> Hashtbl.create 0);
    pattern_properties =
      (match member_opt "patternProperties" json with
      | Some (`Assoc patterns) ->
          List.map
            (fun (pattern_str, schema_json) ->
              let re =
                try Re.Perl.re pattern_str |> Re.compile
                with _ -> Re.compile (Re.str "")
                (* fallback to empty pattern on error *)
              in
              let full_pointer =
                pointer ^ "/patternProperties/" ^ pattern_str
              in
              let idx =
                compile_subschema t root_json current_base_uri full_pointer
                  schema_json
              in
              (re, idx))
            patterns
      | _ -> []);
    property_names =
      (match member_opt "propertyNames" json with
      | Some schema_json ->
          Some
            (compile_subschema t root_json current_base_uri
               (pointer ^ "/propertyNames")
               schema_json)
      | None -> None);
    additional_properties =
      (match member_opt "additionalProperties" json with
      | Some (`Bool b) -> Some (Schema.Bool b)
      | Some schema_json ->
          Some
            (Schema.Schema_ref
               (compile_subschema t root_json current_base_uri
                  (pointer ^ "/additionalProperties")
                  schema_json))
      | None -> None);
    dependent_required =
      (match member_opt "dependentRequired" json with
      | Some (`Assoc deps) ->
          List.map
            (fun (prop_name, dep_json) ->
              match dep_json with
              | `List prop_names ->
                  let names =
                    List.map
                      (fun n ->
                        match n with
                        | `String s -> s
                        | _ -> failwith "Invalid dependentRequired property")
                      prop_names
                  in
                  (prop_name, names)
              | _ -> failwith "dependentRequired must be an array")
            deps
      | _ -> []);
    dependent_schemas =
      (match member_opt "dependentSchemas" json with
      | Some (`Assoc deps) ->
          List.map
            (fun (prop_name, schema_json) ->
              let full_pointer = pointer ^ "/dependentSchemas/" ^ prop_name in
              let idx =
                compile_subschema t root_json current_base_uri full_pointer
                  schema_json
              in
              (prop_name, idx))
            deps
      | _ -> []);
    dependencies =
      (match member_opt "dependencies" json with
      | Some (`Assoc deps) ->
          List.map
            (fun (prop_name, dep_json) ->
              match dep_json with
              | `List prop_names ->
                  (* Property dependencies - array of property names *)
                  let names =
                    List.map
                      (fun n ->
                        match n with
                        | `String s -> s
                        | _ -> failwith "Invalid property dependency")
                      prop_names
                  in
                  (prop_name, Schema.Props names)
              | _ ->
                  (* Schema dependencies - compile as a subschema *)
                  let full_pointer = pointer ^ "/dependencies/" ^ prop_name in
                  let idx =
                    compile_subschema t root_json current_base_uri full_pointer
                      dep_json
                  in
                  (prop_name, Schema.Schema_ref idx))
            deps
      | _ -> []);
    unevaluated_properties =
      (match member_opt "unevaluatedProperties" json with
      | Some (`Bool b) ->
          (* Create a boolean schema for unevaluatedProperties *)
          let bool_schema_json = `Bool b in
          Some
            (compile_subschema t root_json current_base_uri
               (pointer ^ "/unevaluatedProperties")
               bool_schema_json)
      | Some schema_json ->
          Some
            (compile_subschema t root_json current_base_uri
               (pointer ^ "/unevaluatedProperties")
               schema_json)
      | None -> None);
    min_items = member_as_int_or_truncated_float "minItems" json;
    max_items = member_as_int_or_truncated_float "maxItems" json;
    unique_items =
      member_as_bool "uniqueItems" json |> Option.value ~default:false;
    min_contains = member_as_int_or_truncated_float "minContains" json;
    max_contains = member_as_int_or_truncated_float "maxContains" json;
    contains =
      (match member_opt "contains" json with
      | Some schema_json ->
          Some
            (compile_subschema t root_json current_base_uri
               (pointer ^ "/contains") schema_json)
      | None -> None);
    items =
      (match member_opt "items" json with
      | Some (`List schemas) ->
          let indices = compile_schema_list schemas (pointer ^ "/items") in
          Some (Schema.Schema_refs indices)
      | Some schema_json ->
          Some
            (Schema.Schema_ref
               (compile_subschema t root_json current_base_uri
                  (pointer ^ "/items") schema_json))
      | None -> None);
    additional_items =
      (match member_opt "additionalItems" json with
      | Some (`Bool b) -> Some (Schema.Bool b)
      | Some schema_json ->
          Some
            (Schema.Schema_ref
               (compile_subschema t root_json current_base_uri
                  (pointer ^ "/additionalItems")
                  schema_json))
      | None -> None);
    prefix_items =
      (match member_as_list "prefixItems" json with
      | Some schemas -> compile_schema_list schemas (pointer ^ "/prefixItems")
      | None -> []);
    items2020 =
      (match member_opt "items" json with
      | Some (`Bool b) -> Some (Schema.Bool b)
      | Some schema_json when draft_version >= Draft.Draft2020_12 ->
          Some
            (Schema.Schema_ref
               (compile_subschema t root_json current_base_uri
                  (pointer ^ "/items") schema_json))
      | _ -> None);
    unevaluated_items =
      (match member_opt "unevaluatedItems" json with
      | Some (`Bool b) ->
          (* Create a boolean schema for unevaluatedItems *)
          let bool_schema_json = `Bool b in
          Some
            (compile_subschema t root_json current_base_uri
               (pointer ^ "/unevaluatedItems")
               bool_schema_json)
      | Some schema_json ->
          Some
            (compile_subschema t root_json current_base_uri
               (pointer ^ "/unevaluatedItems")
               schema_json)
      | None -> None);
    min_length = member_as_int_or_truncated_float "minLength" json;
    max_length = member_as_int_or_truncated_float "maxLength" json;
    pattern =
      (match member_as_string "pattern" json with
      | Some pattern_str -> (
          try Some (Re.Perl.re pattern_str |> Re.compile) with _ -> None)
      | None -> None);
    pattern_string = member_as_string "pattern" json;
    content_encoding = None;
    content_media_type = None;
    content_schema = None;
    minimum = member_as_float "minimum" json;
    maximum = member_as_float "maximum" json;
    exclusive_minimum =
      (if draft_version = Draft.Draft4 then None
       else member_as_float "exclusiveMinimum" json);
    exclusive_maximum =
      (if draft_version = Draft.Draft4 then None
       else member_as_float "exclusiveMaximum" json);
    exclusive_minimum_draft4 =
      (if draft_version = Draft.Draft4 then
         member_as_bool "exclusiveMinimum" json |> Option.value ~default:false
       else false);
    exclusive_maximum_draft4 =
      (if draft_version = Draft.Draft4 then
         member_as_bool "exclusiveMaximum" json |> Option.value ~default:false
       else false);
    multiple_of = member_as_float "multipleOf" json;
  }

let compile_from_json t location json =
  (* Use compile_subschema which properly handles schema insertion *)
  let idx = compile_subschema t json location "" json in
  match Validator.get_schema t.schemas idx with
  | schema -> Ok schema
  | exception _ ->
      Error (Error.Bug (Failure "Failed to retrieve compiled schema"))

let compile t location =
  (* For now, assume the location is a JSON string for inline schemas *)
  if String.starts_with ~prefix:"inline://" location then
    (* This is a hack for validate_strings - we'll fix this properly later *)
    compile_from_json t location (`Assoc [])
  else
    (* TODO: Load schema from file/URL *)
    compile_from_json t location (`Assoc [])

let compile_json t location json = compile_from_json t location json

let add_resource t location json =
  try
    let _ = compile_subschema t json location "" json in
    Ok ()
  with e -> Error (Error.Load_url_error { url = location; src = e })

let get_schemas t = t.schemas
