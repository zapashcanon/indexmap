type ('index, 'element) t = {
  get : 'index -> 'element;
  mem : 'index -> bool;
}

let mem_default c get i =
  try
    ignore (get c i);
    true
  with
  | Not_found
  | Invalid_argument _ -> false

let make ?mem ~get container =
  let mem =
    match mem with
    | Some f -> fun i -> f container i
    | None -> fun i -> mem_default container get i
  in
  let get i = get container i in
  { get; mem }

let get { get; _ } i = get i
let mem { mem; _ } i = mem i

let map index f = {
  index with
    get = (fun i -> f (index.get i))
}

let map_index index f = {
  get = (fun i -> index.get (f i));
  mem = (fun i -> index.mem (f i));
}

let of_array a =
  let length = Array.length a in
  let mem i = i >= 0 && i < length in
  { mem; get = (fun i -> Array.get a i) }

let of_arrays a =
  make ~get:(fun a (i, j) -> a.(i).(j)) a

(* No custom mem functions for bigarrays because of the difference in initial
    index between C and Fortran layouts. *)
let of_array1 a =
  make ~get:Bigarray.Array1.get a
let of_array2 a =
  make ~get:(fun a (i, j) -> Bigarray.Array2.get a i j) a
let of_array3 a =
  make ~get:(fun a (i, j, k) -> Bigarray.Array3.get a i j k) a
let of_genarray a =
  make ~get:Bigarray.Genarray.get a

let of_function ?mem get =
  let mem =
    match mem with
    | Some f -> f
    | None -> begin
      fun i ->
        try
          ignore (get i);
          true
        with
        | Not_found
        | Invalid_argument _ -> false
    end
  in
  { get; mem }

let to_row_major index ~columns =
  map_index index (fun (i, j) -> i * columns + j)
let to_column_major index ~rows =
  map_index index (fun (i, j) -> i + rows * j)

module Tuple2 = struct
  let fix_first index i = map_index index (fun j -> (i, j))
  let fix_second index j = map_index index (fun i -> (i, j))

  let transpose index = map_index index (fun (i, j) -> (j, i))
end
module Tuple3 = struct
  let fix_first index i = map_index index (fun (j, k) -> (i, j, k))
  let fix_second index j = map_index index (fun (i, k) -> (i, j, k))
  let fix_third index k = map_index index (fun (i, j) -> (i, j, k))

  let fix_first_second index i j = map_index index (fun k -> (i, j, k))
  let fix_first_third index i k = map_index index (fun j -> (i, j, k))
  let fix_second_third index j k = map_index index (fun i -> (i, j, k))
end

