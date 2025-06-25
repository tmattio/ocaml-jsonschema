open Error

type schemas = {
  mutable list : Schema.t list;
  mutable map : (string, int) Hashtbl.t; (* location -> schema index *)
}

let create_schemas () = { list = []; map = Hashtbl.create 32 }

let insert_schemas t locs schemas =
  List.iter2
    (fun loc sch ->
      let idx = List.length t.list in
      t.list <- t.list @ [ sch ];
      Hashtbl.add t.map loc idx)
    locs schemas

let get_schema t idx = List.nth t.list idx

let get_schema_by_loc t loc =
  match Hashtbl.find_opt t.map loc with
  | Some idx -> Some (List.nth t.list idx)
  | None -> None

let contains_schema t idx = idx >= 0 && idx < List.length t.list

let validate _v _schema _schemas =
  (* TODO: Implement full validation logic *)
  Ok ()

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
