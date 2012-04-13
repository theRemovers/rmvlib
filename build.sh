#!/bin/sh

cpath=`pwd`

if [ -z "$M68KTOOLS" ]
then
    echo "Please define M68KTOOLS environment variable"
    exit
fi

tpath="$M68KTOOLS"
#tpath=/usr/local/m68k-aout

if [ ! -d "$tpath" ]
then
    echo "Path $tpath does not exist"
    exit
fi

ipath=$tpath/m68k-aout/include
lpath=$tpath/m68k-aout/lib/m68000

for file in `make -s list-headers`
do
  name=`basename $file`
  echo "Symbolic linking $cpath/$file to $ipath/$name"
  if [ -e "$ipath/$name" ]
      then
      echo "Skipping"
  else
      ln -s "$cpath/$file" "$ipath/$name"
  fi
done

make > log 2>&1

for file in `make -s list-objects`
do
  name=`basename $file`
  echo "Symbolic linking $cpath/$file to $lpath/$name"
  if [ -e "$lpath/$name" ]
      then
      echo "Skipping"
  else
      ln -s "$cpath/$file" "$lpath/$name"
  fi
done


