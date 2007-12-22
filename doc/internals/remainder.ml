let divN a b =
  assert (a >= 0);
  assert (b > 0);
  a/b,a mod b

let div a b =
  if a >= 0 then
    if b > 0 then divN a b
    else
      let q,r = divN a (-b) in -q,r
  else
    if b > 0 then
      let q,r = divN (-a) b in
      let q = - q and r = - r in
	if r < 0 then q-1,r+b
	else q,r
    else
      let q,r = divN (-a) (-b) in
      let r = -r in
	if r < 0 then q+1,r-b
	else q,r

let k v x = 
  let i = ref 0 in
  let x = x -. 1. in
    while x +. (float_of_int !i) *. v < 0. do
      incr i
    done;
    !i

let rec r v r0 n =
  if n = 0 then r0
  else 
    let rn_1 = r v r0 (n-1) in
      rn_1 -. 1. +. (float_of_int (k v rn_1)) *. v

let rec y v r0 n =
  if n = 0 then 0
  else 
    let yn_1 = y v r0 (n-1) in
    let rn_1 = r v r0 (n-1) in
      yn_1 + (k v rn_1)

let get_value d i = (float_of_int i) /. (float_of_int d)

let d = 32
let r0 = get_value d 53
let v = get_value d 12

let compute_y_r dv dr0 d n =
  let drn = dr0 - d * n in
    if drn >= 0 then 0,(get_value d drn)
    else 
      let q,r = div drn (-dv) in
	q,(get_value d r)

      
      
      
