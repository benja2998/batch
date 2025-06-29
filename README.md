# benja2998/batch

Batch compiler written in Rust

## Usage

Install the compiler:

```bash
make # .cargo/bin has to be in PATH
# You can also run "make install", or "cargo install --path ." as they do the same thing
```

Run the compiler after installing:

```bash
make run ARGS="-h" # or "batch-compiler -h"
```

You can also try some of the tests:

```bash
make test<num> # where <num> is the test number
```

## Limitations

* If the batch file has no `exit` commands that are **always** executed, it may lead to undefined behavior in the compiled binary.
* Many batch features are not supported, such as variaables, `if` statements, `for` loops, etc.

## Features

* Significantly faster than the `cmd.exe` interpreter

## Currently supported batch features

* Echo command
* Exit command
* Labels
* Goto command
* Comments (`rem` or `::`)

## Supported OSes

### Compiler itself

* All OSes that support modern Cargo

### Compiled batch files

* All "Modern" versions of Windows (Windows Vista and later, but only tested on Windows 11)
* Linux via Wine (no official support, untested)
* Android via Termux & [Box64Droid](https://github.com/Ilya114/Box64Droid) (no official support, untested)
* macOS via Wine (no official support, untested)

## License

The [Apache License 2.0](LICENSE).

## FAQ

**Q: How can I contact you privately?**

A: You can contact me at [benja2998@duck.com](mailto:benja2998@duck.com). Responses won't be guaranteed as I don't look at it often.

**Q: Will you add official Linux support?**

A: Yes, but currently it is not a priority.

**Q: Will you add official macOS support?**

A: No.

**Q: How can I contribute?**

A: See [CONTRIBUTING.md](CONTRIBUTING.md).

**Q: What is batch?**

A: Batch is a Windows scripting language developed by Microsoft. It is used in .cmd files, .bat files and the Windows command prompt.
