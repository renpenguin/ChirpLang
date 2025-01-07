# Chirp Language

A statically typed interpreted language, made to be a beginner programming language that doesn't sacrifice long-term quality of life for short-term readability. Examples can be found in `examples/`.

A blog post about the development of this language can be found [here](https://redpengu.in/blog/2025/chirp-lang)
## Compiling from source:

### Nix

If you use Nix, you can compile the project without installing any additional packages onto your system by running the following command from the project root:
```sh
nix develop -c odin build src
./src.bin examples/hello_world.ch
# or with `odin run`:
nix develop -c odin run src -- examples/hello_world.ch
```

### Other

If you don't use Nix, you will need to [install Odin manually](https://odin-lang.org/docs/install/). From there you can compile with:
```sh
odin build src
./src.bin examples/hello_world.ch
# or with `odin run`:
odin run src -- examples/hello_world.ch
```