# TCADiagram

## Build & Test

```sh
make build
make test
```

## Usage

```sh
USAGE: tca-diagram [--root-directory <root-directory>] <output>

ARGUMENTS:
  <output>                Markdown file

OPTIONS:
  -r, --root-directory <root-directory>
                          Root directory of swift files (default: .)
  --version               Show the version.
  -h, --help              Show help information.
```

## Release

```sh
VERSION=<version> make release
```
