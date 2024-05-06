set windows-shell := [ "nu", "-c" ]

_default:
  @just --list

clean:
  crystal clear_cache

[windows]
check *flags:
  ./bin/ameba.exe {{ flags }}

[unix]
check *flags:
  ./bin/ameba {{ flags }}

docs *flags:
  crystal docs {{ flags }}

test *spec_files_or_flags:
  crystal spec --progress {{ spec_files_or_flags }}

build *flags:
  shards build --production --release --no-debug --verbose --progress --time {{ flags }}

run *flags:
  shards run --error-trace --progress {{ flags }}

exec exec_file *flags:
  crystal run --error-trace --progress {{ flags }} {{ exec_file }}

bench bench_file *flags:
  crystal run --release --progress {{ flags }} {{ bench_file }}

[windows]
runExample example_file *flags:
  #! nu
  shards install --skip-postinstall --skip-executables
  $env.CRYSTAL_LIBRARY_PATH = $'(pwd)\clib;(crystal env CRYSTAL_LIBRARY_PATH)'
  $env.Path = ($env.Path | prepend $'(pwd)\clib')
  crystal run --progress {{ flags}} {{ example_file }}

[unix]
runExample example_file *flags:
  #!/usr/bin/env bash
  shards install --skip-postinstall --skip-executables
  export CRYSTAL_LIBRARY_PATH="$(pwd)/clib:$(crystal env CRYSTAL_LIBRARY_PATH)"
  crystal run --progress {{ flags}} {{ example_file }}

