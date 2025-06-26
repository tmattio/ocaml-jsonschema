open Error

(* Helper function to count Unicode code points (not bytes) *)
let utf8_length s =
  let len = String.length s in
  let rec count i n =
    if i >= len then n
    else
      let b = Char.code s.[i] in
      if b < 0x80 then count (i + 1) (n + 1)
      else if b < 0xC0 then count (i + 1) n (* continuation byte *)
      else if b < 0xE0 then count (i + 2) (n + 1)
      else if b < 0xF0 then count (i + 3) (n + 1)
      else count (i + 4) (n + 1)
  in
  count 0 0

(* Deep equality for Yojson.Basic.t, handles object key order. *)
let rec yojson_equal v1 v2 =
  match (v1, v2) with
  | `Assoc o1, `Assoc o2 ->
      if List.length o1 <> List.length o2 then false
      else
        let o1_sorted =
          List.sort (fun (k1, _) (k2, _) -> String.compare k1 k2) o1
        in
        let o2_sorted =
          List.sort (fun (k1, _) (k2, _) -> String.compare k1 k2) o2
        in
        List.for_all2
          (fun (k1, v1_i) (k2, v2_i) -> k1 = k2 && yojson_equal v1_i v2_i)
          o1_sorted o2_sorted
  | `List l1, `List l2 ->
      if List.length l1 <> List.length l2 then false
      else List.for_all2 yojson_equal l1 l2
  | `Int i1, `Int i2 -> i1 = i2
  | `Float f1, `Float f2 -> abs_float (f1 -. f2) < 1e-9
  | `Int i, `Float f | `Float f, `Int i ->
      abs_float (float_of_int i -. f) < 1e-9
  | v1, v2 -> v1 = v2

(* Floating point aware check for multipleOf, using a small epsilon *)
let is_multiple_of v m =
  if m = 0.0 then false
  else
    let quotient = v /. m in
    (* For very small divisors, use a relative epsilon *)
    let epsilon = if abs_float m < 1e-6 then 1e-12 else 1e-9 in
    (* Check if quotient is close to an integer *)
    let remainder = abs_float (quotient -. Float.round quotient) in
    remainder < epsilon

type schemas = {
  mutable list : Schema.t list;
  mutable map : (string, int) Hashtbl.t; (* location -> schema index *)
}

let update_schema t idx schema =
  t.list <- List.mapi (fun i s -> if i = idx then schema else s) t.list

let create_schemas () = { list = []; map = Hashtbl.create 32 }

let insert_schemas t locs schemas =
  List.iter2
    (fun loc sch ->
      (* The schema's idx field should match its position in the list *)
      t.list <- t.list @ [ sch ];
      Hashtbl.add t.map loc sch.Schema.idx)
    locs schemas

let get_schema t idx =
  try
    let s = List.nth t.list idx in
    (* Sanity check: the schema's idx should match its position *)
    if s.Schema.idx <> idx && s.Schema.idx <> -1 then
      (* -1 is for dummy schemas *)
      failwith
        (Printf.sprintf "get_schema: schema at position %d has idx=%d" idx
           s.Schema.idx);
    s
  with Failure _ ->
    failwith
      (Printf.sprintf "get_schema: index %d out of bounds (list length: %d)" idx
         (List.length t.list))

let get_schema_by_loc t loc =
  match Hashtbl.find_opt t.map loc with
  | Some idx -> Some (List.nth t.list idx)
  | None -> None

let contains_schema t idx = idx >= 0 && idx < List.length t.list

(* Type to track evaluation state *)
type eval_state = {
  evaluated_props : string list;
  evaluated_items : bool; (* true if all items are evaluated *)
  evaluated_item_count : int;
}

let empty_eval_state =
  { evaluated_props = []; evaluated_items = false; evaluated_item_count = 0 }

let merge_eval_state s1 s2 =
  {
    evaluated_props =
      s1.evaluated_props @ s2.evaluated_props |> List.sort_uniq String.compare;
    evaluated_items = s1.evaluated_items || s2.evaluated_items;
    evaluated_item_count = max s1.evaluated_item_count s2.evaluated_item_count;
  }

let rec validate_with_path v schema schemas visited_refs path =
  let visited_key = (schema.Schema.idx, path) in
  if List.mem visited_key visited_refs then
    ( Error
        {
          schema_url = schema.Schema.location;
          instance_location = path;
          kind = All_of;
          (* Report as allOf error since that's likely where the issue is *)
          causes = [];
        },
      empty_eval_state )
  else
    let visited_refs = visited_key :: visited_refs in
    (* Handle $recursiveRef first *)
    match schema.recursive_ref with
    | Some ref_idx when schema.recursive_anchor ->
        (* This schema has $recursiveAnchor: true, so $recursiveRef should resolve dynamically *)
        if contains_schema schemas ref_idx then
          let ref_schema = get_schema schemas ref_idx in
          validate_with_path v ref_schema schemas visited_refs path
        else
          ( Error
              {
                schema_url = schema.Schema.location;
                instance_location = path;
                kind =
                  Schema
                    {
                      url =
                        Printf.sprintf
                          "Recursive ref schema not found: index %d" ref_idx;
                    };
                causes = [];
              },
            empty_eval_state )
    | Some ref_idx ->
        (* No $recursiveAnchor, so $recursiveRef acts like $ref *)
        if contains_schema schemas ref_idx then
          let ref_schema = get_schema schemas ref_idx in
          validate_with_path v ref_schema schemas visited_refs path
        else
          ( Error
              {
                schema_url = schema.Schema.location;
                instance_location = path;
                kind =
                  Schema
                    {
                      url =
                        Printf.sprintf
                          "Recursive ref schema not found: index %d" ref_idx;
                    };
                causes = [];
              },
            empty_eval_state )
    | None -> (
        (* Check $dynamicRef *)
        match schema.dynamic_ref with
        | Some { Schema.sch = ref_idx; anchor = _ } ->
            (* For now, treat $dynamicRef like $ref, ignoring anchor *)
            if contains_schema schemas ref_idx then
              let ref_schema = get_schema schemas ref_idx in
              validate_with_path v ref_schema schemas visited_refs path
            else
              ( Error
                  {
                    schema_url = schema.Schema.location;
                    instance_location = path;
                    kind =
                      Schema
                        {
                          url =
                            Printf.sprintf
                              "Dynamic ref schema not found: index %d" ref_idx;
                        };
                    causes = [];
                  },
                empty_eval_state )
        | None -> (
            (* Check regular $ref *)
            match schema.ref_ with
            | Some ref_idx ->
                if contains_schema schemas ref_idx then
                  let ref_schema = get_schema schemas ref_idx in
                  let ref_result, ref_eval_state =
                    validate_with_path v ref_schema schemas visited_refs path
                  in
                  (* Also validate sibling keywords if any exist *)
                  let has_siblings =
                    schema.types <> Types.empty
                    || schema.constant <> None || schema.enum_ <> None
                    || schema.min_length <> None || schema.max_length <> None
                    || schema.pattern <> None || schema.min_items <> None
                    || schema.max_items <> None || schema.unique_items
                    || schema.min_properties <> None
                    || schema.max_properties <> None
                    || schema.required <> []
                    || Hashtbl.length schema.properties > 0
                    || schema.pattern_properties <> []
                    || schema.additional_properties <> None
                    || schema.property_names <> None
                    || schema.contains <> None
                    || schema.min_contains <> None
                    || schema.max_contains <> None
                    || schema.minimum <> None || schema.maximum <> None
                    || schema.exclusive_minimum <> None
                    || schema.exclusive_maximum <> None
                    || schema.multiple_of <> None || schema.all_of <> []
                    || schema.any_of <> [] || schema.one_of <> []
                    || schema.not <> None || schema.if_ <> None
                    || schema.format <> None
                    || schema.content_encoding <> None
                    || schema.content_media_type <> None
                    || schema.content_schema <> None
                    || schema.dependent_schemas <> []
                    || schema.dependent_required <> []
                    (* Don't include unevaluated keywords in sibling check - they need special handling *)
                  in
                  if has_siblings then
                    (* Validate sibling keywords *)
                    let sibling_result, sibling_eval_state =
                      validate_impl v schema schemas visited_refs path
                    in
                    (* Combine results *)
                    match (ref_result, sibling_result) with
                    | Ok (), Ok () ->
                        (* Merge eval states *)
                        let merged_eval_state =
                          merge_eval_state ref_eval_state sibling_eval_state
                        in
                        (Ok (), merged_eval_state)
                    | Error e1, Ok () -> (Error e1, ref_eval_state)
                    | Ok (), Error e2 -> (Error e2, sibling_eval_state)
                    | Error e1, Error e2 ->
                        (* Combine errors *)
                        let combined_error =
                          {
                            schema_url = schema.Schema.location;
                            instance_location = path;
                            kind = Group;
                            causes = [ e1; e2 ];
                          }
                        in
                        (Error combined_error, empty_eval_state)
                  else (ref_result, ref_eval_state)
                else
                  ( Error
                      {
                        schema_url = schema.Schema.location;
                        instance_location = path;
                        kind =
                          Schema
                            {
                              url =
                                Printf.sprintf
                                  "Referenced schema not found: index %d \
                                   (total schemas: %d)"
                                  ref_idx (List.length schemas.list);
                            };
                        causes = [];
                      },
                    empty_eval_state )
            | None -> validate_impl v schema schemas visited_refs path))

and validate_impl v schema schemas visited_refs path =
  match schema.boolean with
  | Some true ->
      ( Ok (),
        (* Boolean true schema evaluates all properties/items *)
        match v with
        | `Assoc props ->
            {
              evaluated_props = List.map fst props;
              evaluated_items = false;
              evaluated_item_count = 0;
            }
        | `List items ->
            {
              evaluated_props = [];
              evaluated_items = true;
              evaluated_item_count = List.length items;
            }
        | _ -> empty_eval_state )
  | Some false ->
      ( Error
          {
            schema_url = schema.location;
            instance_location = path;
            kind = False_schema;
            causes = [];
          },
        empty_eval_state )
  | None -> (
      let errors = ref [] in
      let eval_state = ref empty_eval_state in
      let add_error kind =
        errors :=
          {
            schema_url = schema.location;
            instance_location = path;
            kind;
            causes = [];
          }
          :: !errors
      in

      (* Keyword validations *)
      (if not (Types.is_empty schema.types) then
         let actual_type = Types.type_of v in
         let type_matches =
           Types.contains schema.types actual_type
           || actual_type = Types.Integer
              && Types.contains schema.types Types.Number
         in
         if not type_matches then
           add_error (Type { got = v; want = schema.types }));

      (match schema.constant with
      | Some const_val ->
          if not (yojson_equal v const_val) then
            add_error (Const { want = const_val })
      | _ -> ());

      (match schema.enum_ with
      | Some { values = enum_vals; _ } ->
          if not (List.exists (yojson_equal v) enum_vals) then
            add_error (Enum { want = enum_vals })
      | _ -> ());

      (* String validations *)
      (match v with
      | `String s -> (
          let str_len = utf8_length s in
          (match schema.min_length with
          | Some min when str_len < min ->
              add_error (Min_length { got = str_len; want = min })
          | _ -> ());
          (match schema.max_length with
          | Some max when str_len > max ->
              add_error (Max_length { got = str_len; want = max })
          | _ -> ());
          match (schema.pattern, schema.pattern_string) with
          | Some re, Some pattern_str -> (
              try
                (* JSON Schema patterns match if found anywhere in the string *)
                let found = Re.execp re s in
                if not found then
                  add_error (Pattern { got = s; want = pattern_str })
              with _ -> add_error (Pattern { got = s; want = pattern_str }))
          | _ -> ())
      | _ -> ());

      (* Number validations *)
      (match v with
      | `Int i -> (
          let f = float_of_int i in
          (* Handle minimum/maximum based on draft version *)
          if schema.draft_version = Draft.Draft4 then (
            (* Draft4: exclusiveMinimum/Maximum are boolean flags *)
            (match schema.minimum with
            | Some min when schema.exclusive_minimum_draft4 && f <= min ->
                add_error (Exclusive_minimum { got = f; want = min })
            | Some min when (not schema.exclusive_minimum_draft4) && f < min ->
                add_error (Minimum { got = f; want = min })
            | _ -> ());
            match schema.maximum with
            | Some max when schema.exclusive_maximum_draft4 && f >= max ->
                add_error (Exclusive_maximum { got = f; want = max })
            | Some max when (not schema.exclusive_maximum_draft4) && f > max ->
                add_error (Maximum { got = f; want = max })
            | _ -> ())
          else (
            (* Draft6+: exclusiveMinimum/Maximum are numeric values *)
            (match schema.minimum with
            | Some min when f < min ->
                add_error (Minimum { got = f; want = min })
            | _ -> ());
            (match schema.maximum with
            | Some max when f > max ->
                add_error (Maximum { got = f; want = max })
            | _ -> ());
            (match schema.exclusive_minimum with
            | Some min when f <= min ->
                add_error (Exclusive_minimum { got = f; want = min })
            | _ -> ());
            match schema.exclusive_maximum with
            | Some max when f >= max ->
                add_error (Exclusive_maximum { got = f; want = max })
            | _ -> ());
          match schema.multiple_of with
          | Some mult ->
              if not (is_multiple_of f mult) then
                add_error (Multiple_of { got = f; want = mult })
          | _ -> ())
      | `Float f -> (
          (* Handle minimum/maximum based on draft version *)
          if schema.draft_version = Draft.Draft4 then (
            (* Draft4: exclusiveMinimum/Maximum are boolean flags *)
            (match schema.minimum with
            | Some min when schema.exclusive_minimum_draft4 && f <= min ->
                add_error (Exclusive_minimum { got = f; want = min })
            | Some min when (not schema.exclusive_minimum_draft4) && f < min ->
                add_error (Minimum { got = f; want = min })
            | _ -> ());
            match schema.maximum with
            | Some max when schema.exclusive_maximum_draft4 && f >= max ->
                add_error (Exclusive_maximum { got = f; want = max })
            | Some max when (not schema.exclusive_maximum_draft4) && f > max ->
                add_error (Maximum { got = f; want = max })
            | _ -> ())
          else (
            (* Draft6+: exclusiveMinimum/Maximum are numeric values *)
            (match schema.minimum with
            | Some min when f < min ->
                add_error (Minimum { got = f; want = min })
            | _ -> ());
            (match schema.maximum with
            | Some max when f > max ->
                add_error (Maximum { got = f; want = max })
            | _ -> ());
            (match schema.exclusive_minimum with
            | Some min when f <= min ->
                add_error (Exclusive_minimum { got = f; want = min })
            | _ -> ());
            match schema.exclusive_maximum with
            | Some max when f >= max ->
                add_error (Exclusive_maximum { got = f; want = max })
            | _ -> ());
          match schema.multiple_of with
          | Some mult when not (is_multiple_of f mult) ->
              add_error (Multiple_of { got = f; want = mult })
          | _ -> ())
      | _ -> ());

      (* Array validations *)
      (match v with
      | `List items -> (
          let len = List.length items in
          (match schema.min_items with
          | Some min when len < min ->
              add_error (Min_items { got = len; want = min })
          | _ -> ());
          (match schema.max_items with
          | Some max when len > max ->
              add_error (Max_items { got = len; want = max })
          | _ -> ());
          (if schema.unique_items then
             let rec find_dup i = function
               | [] -> None
               | h :: t -> (
                   let rec find_index j = function
                     | [] -> None
                     | x :: xs ->
                         if yojson_equal h x then Some j
                         else find_index (j + 1) xs
                   in
                   match find_index 0 t with
                   | Some j -> Some (i, i + j + 1)
                   | None -> find_dup (i + 1) t)
             in
             match find_dup 0 items with
             | Some (i, j) -> add_error (Unique_items { got = (i, j) })
             | None -> ());

          (* Handle array validation based on draft version *)
          (if
             schema.draft_version >= Draft.Draft2020_12
             && schema.prefix_items <> []
           then (
             (* Draft 2020-12: use prefixItems and items2020 *)
             let num_prefix_items = List.length schema.prefix_items in
             List.iteri
               (fun i item ->
                 let item_path = { tokens = path.tokens @ [ Error.Item i ] } in
                 if i < num_prefix_items then
                   (* Validate against prefixItems schema *)
                   let idx = List.nth schema.prefix_items i in
                   let item_schema = get_schema schemas idx in
                   match
                     validate_with_path item item_schema schemas visited_refs
                       item_path
                   with
                   | Ok (), _ -> ()
                   | Error e, _ -> errors := e :: !errors
                 else
                   (* Items beyond prefixItems - check items2020 *)
                   match schema.items2020 with
                   | Some (Bool false) ->
                       add_error
                         (Additional_items { got = len - num_prefix_items })
                   | Some (Bool true) | None -> ()
                   | Some (Schema_ref add_idx) -> (
                       let add_schema = get_schema schemas add_idx in
                       match
                         validate_with_path item add_schema schemas visited_refs
                           item_path
                       with
                       | Ok (), _ -> ()
                       | Error e, _ -> errors := e :: !errors))
               items;
             (* Track evaluated items *)
             if
               schema.items2020 = Some (Bool true)
               ||
               match schema.items2020 with
               | Some (Schema_ref _) -> true
               | _ -> false
             then
               eval_state :=
                 {
                   !eval_state with
                   evaluated_items = true;
                   evaluated_item_count = len;
                 }
             else
               eval_state :=
                 { !eval_state with evaluated_item_count = num_prefix_items })
           else
             (* Pre-2020-12: use items and additionalItems *)
             match schema.items with
             | Some (Schema_ref idx) ->
                 let item_schema = get_schema schemas idx in
                 List.iteri
                   (fun i item ->
                     let item_path =
                       { tokens = path.tokens @ [ Error.Item i ] }
                     in
                     match
                       validate_with_path item item_schema schemas visited_refs
                         item_path
                     with
                     | Ok (), _ -> ()
                     | Error e, _ -> errors := e :: !errors)
                   items;
                 eval_state :=
                   {
                     !eval_state with
                     evaluated_items = true;
                     evaluated_item_count = len;
                   }
             | Some (Schema_refs idxs) ->
                 let num_tuple_items = List.length idxs in
                 List.iteri
                   (fun i item ->
                     let item_path =
                       { tokens = path.tokens @ [ Error.Item i ] }
                     in
                     if i < num_tuple_items then
                       let idx = List.nth idxs i in
                       let item_schema = get_schema schemas idx in
                       match
                         validate_with_path item item_schema schemas
                           visited_refs item_path
                       with
                       | Ok (), _ -> ()
                       | Error e, _ -> errors := e :: !errors
                     else
                       match schema.additional_items with
                       | Some (Bool false) ->
                           add_error
                             (Additional_items { got = len - num_tuple_items })
                       | Some (Bool true) | None -> ()
                       | Some (Schema_ref add_idx) -> (
                           let add_schema = get_schema schemas add_idx in
                           match
                             validate_with_path item add_schema schemas
                               visited_refs item_path
                           with
                           | Ok (), _ -> ()
                           | Error e, _ -> errors := e :: !errors))
                   items;
                 (* Track evaluated items *)
                 if
                   schema.additional_items = Some (Bool true)
                   ||
                   match schema.additional_items with
                   | Some (Schema_ref _) -> true
                   | _ -> false
                 then
                   eval_state :=
                     {
                       !eval_state with
                       evaluated_items = true;
                       evaluated_item_count = len;
                     }
                 else
                   eval_state :=
                     { !eval_state with evaluated_item_count = num_tuple_items }
             | None -> ());

          (* Contains validation *)
          match schema.contains with
          | Some contains_idx -> (
              let contains_schema = get_schema schemas contains_idx in
              let valid_indices =
                List.mapi
                  (fun i item ->
                    let item_path =
                      { tokens = path.tokens @ [ Error.Item i ] }
                    in
                    match
                      validate_with_path item contains_schema schemas
                        visited_refs item_path
                    with
                    | Ok (), _ -> Some i
                    | Error _, _ -> None)
                  items
                |> List.filter_map (fun x -> x)
              in
              let valid_count = List.length valid_indices in
              (* Only add Contains error if minContains is not 0 *)
              (match schema.min_contains with
              | Some 0 -> () (* minContains = 0 makes contains always pass *)
              | _ -> if valid_count = 0 then add_error Contains);
              (* minContains validation *)
              (match schema.min_contains with
              | Some min when valid_count < min ->
                  add_error (Min_contains { got = valid_indices; want = min })
              | _ -> ());
              (* maxContains validation *)
              match schema.max_contains with
              | Some max when valid_count > max ->
                  add_error (Max_contains { got = valid_indices; want = max })
              | _ -> ())
          | None -> (
              (* When contains is not present, minContains = 0 is always valid *)
              match schema.min_contains with
              | Some 0 ->
                  ()
                  (* Valid - minContains = 0 without contains always passes *)
              | Some _ ->
                  (* Without contains, any minContains > 0 would fail, but this is actually
                     ignored per spec - minContains without contains has no effect *)
                  ()
              | _ -> ()))
      | _ -> ());

      (* Object validations *)
      (match v with
      | `Assoc props ->
          let prop_count = List.length props in
          (match schema.min_properties with
          | Some min when prop_count < min ->
              add_error (Min_properties { got = prop_count; want = min })
          | _ -> ());
          (match schema.max_properties with
          | Some max when prop_count > max ->
              add_error (Max_properties { got = prop_count; want = max })
          | _ -> ());

          let missing_required =
            List.filter
              (fun req -> not (List.mem_assoc req props))
              schema.required
          in
          if missing_required <> [] then
            add_error (Required { want = missing_required });

          let defined_props = ref [] in
          let pattern_matched_props = ref [] in
          let additional_props_evaluated = ref [] in

          List.iter
            (fun (p_name, p_value) ->
              let prop_path =
                { tokens = path.tokens @ [ Error.Prop p_name ] }
              in
              (match Hashtbl.find_opt schema.properties p_name with
              | Some p_idx ->
                  let p_schema = get_schema schemas p_idx in
                  (match
                     validate_with_path p_value p_schema schemas visited_refs
                       prop_path
                   with
                  | Ok (), sub_state ->
                      eval_state := merge_eval_state !eval_state sub_state
                  | Error e, sub_state ->
                      errors := e :: !errors;
                      eval_state := merge_eval_state !eval_state sub_state);
                  defined_props := p_name :: !defined_props
              | None -> ());
              List.iter
                (fun (re, pat_idx) ->
                  (* For patternProperties, we just need the pattern to match, not necessarily the whole string *)
                  if Re.execp re p_name then (
                    let pat_schema = get_schema schemas pat_idx in
                    (match
                       validate_with_path p_value pat_schema schemas
                         visited_refs prop_path
                     with
                    | Ok (), sub_state ->
                        eval_state := merge_eval_state !eval_state sub_state
                    | Error e, sub_state ->
                        errors := e :: !errors;
                        eval_state := merge_eval_state !eval_state sub_state);
                    pattern_matched_props := p_name :: !pattern_matched_props))
                schema.pattern_properties)
            props;

          (* Additional properties are those that don't match properties or patternProperties *)
          let additional_props =
            List.filter
              (fun (p, _) ->
                (not (List.mem p !defined_props))
                && not (List.mem p !pattern_matched_props))
              props
          in
          (if additional_props <> [] then
             match schema.additional_properties with
             | Some (Bool false) ->
                 add_error
                   (Additional_properties
                      { got = List.map fst additional_props })
             | Some (Bool true) ->
                 (* additionalProperties: true evaluates all additional properties *)
                 additional_props_evaluated := List.map fst additional_props
             | Some (Schema_ref idx) ->
                 let add_schema = get_schema schemas idx in
                 List.iter
                   (fun (p_name, p_value) ->
                     let prop_path =
                       { tokens = path.tokens @ [ Error.Prop p_name ] }
                     in
                     match
                       validate_with_path p_value add_schema schemas
                         visited_refs prop_path
                     with
                     | Ok (), sub_state ->
                         eval_state := merge_eval_state !eval_state sub_state;
                         additional_props_evaluated :=
                           p_name :: !additional_props_evaluated
                     | Error e, sub_state ->
                         errors := e :: !errors;
                         eval_state := merge_eval_state !eval_state sub_state;
                         additional_props_evaluated :=
                           p_name :: !additional_props_evaluated)
                   additional_props
             | None ->
                 (* No additionalProperties keyword - properties remain unevaluated *)
                 ());

          (* Update evaluated properties *)
          let all_evaluated_here =
            !defined_props @ !pattern_matched_props
            @ !additional_props_evaluated
          in
          eval_state :=
            {
              !eval_state with
              evaluated_props =
                !eval_state.evaluated_props @ all_evaluated_here
                |> List.sort_uniq String.compare;
            };

          (* propertyNames validation *)
          (match schema.property_names with
          | Some prop_names_idx ->
              let prop_names_schema = get_schema schemas prop_names_idx in
              List.iter
                (fun (p_name, _) ->
                  (* Validate each property name as a string against the propertyNames schema *)
                  let name_as_json = `String p_name in
                  match
                    validate_with_path name_as_json prop_names_schema schemas
                      visited_refs path
                  with
                  | Ok (), _ -> ()
                  | Error _, _ -> add_error (Property_name { prop = p_name }))
                props
          | None -> ());

          (* Dependencies validation *)
          List.iter
            (fun (dep_prop, dep_spec) ->
              if List.mem_assoc dep_prop props then
                match dep_spec with
                | Schema.Props required_props ->
                    (* Property dependencies - check that all required properties are present *)
                    let missing =
                      List.filter
                        (fun p -> not (List.mem_assoc p props))
                        required_props
                    in
                    if missing <> [] then
                      add_error (Dependency { prop = dep_prop; missing })
                | Schema.Schema_ref dep_idx -> (
                    (* Schema dependencies - validate the entire object against the dependency schema *)
                    let dep_schema = get_schema schemas dep_idx in
                    match
                      validate_with_path v dep_schema schemas visited_refs path
                    with
                    | Ok (), sub_state ->
                        eval_state := merge_eval_state !eval_state sub_state
                    | Error e, sub_state ->
                        errors := e :: !errors;
                        eval_state := merge_eval_state !eval_state sub_state))
            schema.dependencies;

          (* Dependent required validation (draft 2019-09+) *)
          List.iter
            (fun (dep_prop, required_props) ->
              if List.mem_assoc dep_prop props then
                let missing =
                  List.filter
                    (fun p -> not (List.mem_assoc p props))
                    required_props
                in
                if missing <> [] then
                  add_error (Dependent_required { prop = dep_prop; missing }))
            schema.dependent_required;

          (* Dependent schemas validation (draft 2019-09+) *)
          List.iter
            (fun (dep_prop, dep_idx) ->
              if List.mem_assoc dep_prop props then
                let dep_schema = get_schema schemas dep_idx in
                match
                  validate_with_path v dep_schema schemas visited_refs path
                with
                | Ok (), sub_state ->
                    eval_state := merge_eval_state !eval_state sub_state
                | Error e, sub_state ->
                    errors := e :: !errors;
                    eval_state := merge_eval_state !eval_state sub_state)
            schema.dependent_schemas
      | _ -> ());

      (* Applicators *)
      let collect_sub_errors_and_state schemas_list =
        List.fold_left
          (fun (errs, state) idx ->
            match
              validate_with_path v (get_schema schemas idx) schemas visited_refs
                path
            with
            | Ok (), sub_state -> (errs, merge_eval_state state sub_state)
            | Error e, sub_state -> (e :: errs, merge_eval_state state sub_state))
          ([], !eval_state) schemas_list
      in

      if schema.all_of <> [] then (
        let sub_errors, new_state =
          collect_sub_errors_and_state schema.all_of
        in
        eval_state := new_state;
        if sub_errors <> [] then
          errors :=
            {
              schema_url = schema.location;
              instance_location = path;
              kind = All_of;
              causes = sub_errors;
            }
            :: !errors);

      (if schema.any_of <> [] then
         let valid_results =
           List.filter_map
             (fun idx ->
               match
                 validate_with_path v (get_schema schemas idx) schemas
                   visited_refs path
               with
               | Ok (), sub_state -> Some sub_state
               | Error _, _ -> None)
             schema.any_of
         in
         if valid_results = [] then add_error Any_of
         else
           (* Merge state from all valid branches *)
           List.iter
             (fun sub_state ->
               eval_state := merge_eval_state !eval_state sub_state)
             valid_results);

      (if schema.one_of <> [] then
         let valid_results =
           List.filter_map
             (fun idx ->
               match
                 validate_with_path v (get_schema schemas idx) schemas
                   visited_refs path
               with
               | Ok (), sub_state -> Some sub_state
               | Error _, _ -> None)
             schema.one_of
         in
         let valid_count = List.length valid_results in
         if valid_count <> 1 then
           add_error (One_of (Some (valid_count, List.length schema.one_of)))
         else
           (* Merge state from the one valid branch *)
           eval_state := merge_eval_state !eval_state (List.hd valid_results));

      (match schema.not with
      | Some idx -> (
          (* "not" should fail if the subschema validates *)
          let not_schema = get_schema schemas idx in
          match validate_with_path v not_schema schemas visited_refs path with
          | Ok (), _ -> add_error Not (* subschema validated, so "not" fails *)
          | Error _, _ -> () (* subschema failed, so "not" succeeds *))
      | None -> ());

      (match schema.if_ with
      | Some if_idx -> (
          match
            validate_with_path v
              (get_schema schemas if_idx)
              schemas visited_refs path
          with
          | Ok (), if_state -> (
              eval_state := merge_eval_state !eval_state if_state;
              match schema.then_ with
              | Some then_idx -> (
                  match
                    validate_with_path v
                      (get_schema schemas then_idx)
                      schemas visited_refs path
                  with
                  | Ok (), then_state ->
                      eval_state := merge_eval_state !eval_state then_state
                  | Error e, then_state ->
                      errors := e :: !errors;
                      eval_state := merge_eval_state !eval_state then_state)
              | None -> ())
          | Error _, _ -> (
              match schema.else_ with
              | Some else_idx -> (
                  match
                    validate_with_path v
                      (get_schema schemas else_idx)
                      schemas visited_refs path
                  with
                  | Ok (), else_state ->
                      eval_state := merge_eval_state !eval_state else_state
                  | Error e, else_state ->
                      errors := e :: !errors;
                      eval_state := merge_eval_state !eval_state else_state)
              | None -> ()))
      | None -> ());

      (* unevaluatedProperties validation *)
      (match v with
      | `Assoc props when schema.unevaluated_properties <> None -> (
          match schema.unevaluated_properties with
          | Some uneval_idx -> (
              (* Find properties that haven't been evaluated *)
              let unevaluated_props =
                List.filter
                  (fun (p, _) -> not (List.mem p !eval_state.evaluated_props))
                  props
              in
              if unevaluated_props <> [] then
                let uneval_schema = get_schema schemas uneval_idx in
                (* Check if it's a boolean schema *)
                match uneval_schema.boolean with
                | Some false ->
                    (* unevaluatedProperties: false *)
                    add_error
                      (Unevaluated_properties
                         { got = List.map fst unevaluated_props })
                | Some true ->
                    (* unevaluatedProperties: true - all unevaluated properties are valid *)
                    ()
                | None ->
                    (* unevaluatedProperties: schema - validate each unevaluated property *)
                    List.iter
                      (fun (p_name, p_value) ->
                        let prop_path =
                          { tokens = path.tokens @ [ Error.Prop p_name ] }
                        in
                        match
                          validate_with_path p_value uneval_schema schemas
                            visited_refs prop_path
                        with
                        | Ok (), _ -> ()
                        | Error e, _ -> errors := e :: !errors)
                      unevaluated_props)
          | None -> ())
      | _ -> ());

      (* unevaluatedItems validation *)
      (match v with
      | `List items when schema.unevaluated_items <> None -> (
          match schema.unevaluated_items with
          | Some uneval_idx -> (
              (* Find items that haven't been evaluated *)
              let unevaluated_count =
                let len = List.length items in
                if !eval_state.evaluated_items then 0
                else len - !eval_state.evaluated_item_count
              in
              if unevaluated_count > 0 then
                let uneval_schema = get_schema schemas uneval_idx in
                (* Check if it's a boolean schema *)
                match uneval_schema.boolean with
                | Some false ->
                    (* unevaluatedItems: false *)
                    add_error (Unevaluated_items { got = unevaluated_count })
                | Some true ->
                    (* unevaluatedItems: true - all unevaluated items are valid *)
                    ()
                | None ->
                    (* unevaluatedItems: schema - validate each unevaluated item *)
                    List.iteri
                      (fun i item ->
                        if i >= !eval_state.evaluated_item_count then
                          let item_path =
                            { tokens = path.tokens @ [ Error.Item i ] }
                          in
                          match
                            validate_with_path item uneval_schema schemas
                              visited_refs item_path
                          with
                          | Ok (), _ -> ()
                          | Error e, _ -> errors := e :: !errors)
                      items)
          | None -> ())
      | _ -> ());

      match List.rev !errors with
      | [] -> (Ok (), !eval_state)
      | [ e ] -> (Error e, !eval_state)
      | errs ->
          ( Error
              {
                schema_url = schema.location;
                instance_location = path;
                kind = Group;
                causes = errs;
              },
            !eval_state ))

let validate v schema schemas =
  let result, _ = validate_with_path v schema schemas [] { tokens = [] } in
  result

let validate_with_schemas t v idx =
  if not (contains_schema t idx) then
    Error
      {
        schema_url = "";
        instance_location = { tokens = [] };
        kind = Error.Schema { url = "Schema index out of bounds" };
        causes = [];
      }
  else
    let sch = get_schema t idx in
    validate v sch t
