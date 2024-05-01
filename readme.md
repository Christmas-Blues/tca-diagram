# TCADiagram

Create [mermaid](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams) md file from [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) to show the full diagram of your feature relationships.

Refer to example here: https://github.com/tisohjung/ifletstore/blob/main/diagram.md

```mermaid
%%{ init : { "theme" : "default", "flowchart" : { "curve" : "monotoneY" }}}%%
graph LR
    Feature1 -- optional --> SubFeature1
    Feature1 -- optional --> SubFeature2
    Feature1 -- optional --> SubFeature3
    Feature1 -- optional --> SubFeature4
    Feature1 -- optional --> SubFeature5
    Feature1 -- optional --> SubFeature6
    Feature1 -- optional --> SubFeature7
    Feature1 -- optional --> SubFeature8
    Feature1 -- optional --> SubFeature9
    Main -- optional --> Feature1

    Feature1(Feature1: 1)
    SubFeature1(SubFeature1: 1)
    SubFeature2(SubFeature2: 1)
    SubFeature3(SubFeature3: 1)
    SubFeature4(SubFeature4: 1)
    SubFeature5(SubFeature5: 1)
    SubFeature6(SubFeature6: 1)
    SubFeature7(SubFeature7: 1)
    SubFeature8(SubFeature8: 1)
    SubFeature9(SubFeature9: 1)
```

## Build & Test the Library

build this project or download the tca-diagram file from the latest release
Build:
```sh
make build
make test
```
Run:
```
./tca-diagram -r . tca-diagram.md
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

## Todos
- [x] ~~Scopes~~
- [x] ~~optionals~~
- [x] ~~ifLet~~
- [x] ~~functions inside `extension Reducer {...}` isn't parsed.~~
- [x] ~~case paths like `.ifLet(\.$destination, action: \.destination) {`~~
