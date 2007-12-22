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

let check a b = 
  let q,r = div a b in
    assert (0 <= r);
    assert (r < abs b);
    assert (a = b * q + r);
    q,r
