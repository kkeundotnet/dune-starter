# Dune starter

This repository provides templates to help you start an OCaml project.
It can be used to create libraries, executables, and test suites.

## How to set up

```
$ git clone https://github.com/kkeundotnet/dune-starter
$ cd dune-starter
$ bash init.sh
...
$ cd <target directory>
$ git init
$ git add .
```

The shell script `init.sh` will ask you about some information that
are required to setting start files including the project name, the
target directory, etc..

Play around and make sure everything works. Try `make`, `make test`,
`make clean`.

Consult the [dune docs](https://dune.readthedocs.io/) as needed.

Thanks to @mjambon, the original author of the dune-starter.  Thanks
to the authors of dune and @rgrinberg in particular for this great
tool!
