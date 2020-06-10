let max_step = 256

let pi = 4. *. atan 1.

let rad_of_step x = (float_of_int x) *. 2. *. pi /. (float_of_int max_step)

let cos_step x = cos (rad_of_step x)
let sin_step x = sin (rad_of_step x)

let round x = int_of_float (x +. 0.5)

let fixval x = round (x *. (float_of_int (1 lsl 16)))

let string_of_char c = String.make 1 c

let hexstring_of_int ?(dollar = true) nb n =
  let s = ref "" and n = ref n in
    for i = 0 to nb-1 do
      let d = !n land 0xf in
        n := !n lsr 4;
        if (0 <= d) && (d <= 9) then s := (string_of_char (Char.chr (d+(Char.code '0'))))^(!s)
        else s := (string_of_char (Char.chr (d-10+(Char.code 'A'))))^(!s)
    done;
    (if dollar then "$" else "")^(!s)

let string_of_long x =
  let h = (x asr 16) land 0xffff
  and l = x land 0xffff 
  in
    (hexstring_of_int 4 h)^(hexstring_of_int ~dollar:false 4 l)

let dc_print = 
  let counter = ref 0 in
    function s ->
      if !counter = 0 then print_string "\tdc.l\t";
      print_string s;
      incr counter;
      counter := !counter mod 8;
      if !counter <> 0 then print_string ", "
      else print_newline ()

let _ =
  for i = 0 to max_step-1 do
    let v = fixval (cos_step i) in
      dc_print (string_of_long v);
  done
