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
make test1
```

## Limitations

* Not all batch commands are supported (yet)

## Features

* Significantly faster than the `cmd.exe` interpreter
* Runs on older Windows OSes that don't have the latest `cmd.exe` features

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

**Q: Why did you make this?**
A: There are still people writing batch files and I am one of them, but the problem is that the `cmd.exe` interpreter is slow.

**Q: Why Rust?**

A: Initially this project was written in batch, I decided to rewrite it in Rust because of how horrific the codebase was getting.

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
