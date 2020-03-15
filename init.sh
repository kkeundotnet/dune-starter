#!/bin/bash

set -e -u

which ocaml > /dev/null || {
    echo "ocaml required" 1>&2;
    exit 1;
}

which ocamlfind > /dev/null || {
    echo "ocamlfind required" 1>&2;
    exit 1;
}

ocaml \
    `ocamlfind query unix -suffix /unix.cma` \
    `ocamlfind query str -suffix /str.cma` \
    init.ml
