let table = [| 0; 1; 3; 4; 6; 7; 9; 10;
	       12; 13; 15; 16; 18; 20; 21; 23;
	       25; 27; 29; 31; 33; 35; 37; 39; 
	       41; 43; 45; 48; 50; 52; 55; 58;
	       60; 63; 66; 69; 72; 75; 78; 82;
	       85; 89; 93; 97; 101; 105; 110; 115;
	       120; 126; 132; 138; 145; 153; 161; 170;
	       181; 192; 206; 221; 241; 266; 301; 361 |]

let fact = 256.

let fixp x = int_of_float (x *. fact)

let valp x = (float_of_int x) /. fact

let coef i = 
  if i = 0 then 0.
  else 
    let i = i-1 in
    exp (-. (float_of_int table.(63-i)) /. 100.)

let abs_float x = 
  if x < 0. then (-. x) else x

let show () = 
  let delta = ref 0. in
  for i = 0 to 64 do
    let c = coef i in
    let n = fixp c in
    let v = valp n in
    let d = abs_float (v -. c) in
    delta := max d !delta;
    Format.printf "%d: %f %d %f\n" i c n v
  done;
  Format.printf "delta = %f\n" !delta;
  !delta

let gen_data () =
  for i = 0 to 63 do
    if i mod 8 = 0 then Format.printf "\n\tdc.b\t";
    Format.printf "%d" (fixp (coef i));
    if i mod 8 != 7 then Format.printf ", ";
  done

let _ = 
  gen_data()
