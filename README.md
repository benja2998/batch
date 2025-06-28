# compiler.bat

## Usage

Test by running test.bat:

```powershell
.\src\compiler.bat .\test\test.bat
```

You can also keep the asm code by running it like this:

```powershell
.\src\compiler.bat .\test\test.bat keep_asm # keep_asm HAS to be argument 2
```

## Limitations

* Batch file must contain an exit that will always be executed.
* Not all batch commands are implemented. We plan to implement all commands in the future.

## Non-limitations

* MUCH better performance than running the batch files directly, as it directly translates batch commands to assembly equivalents.

## Commands

* EXIT
* ECHO
* GOTO
* :LABEL
* All other batch commands are implemented via WinExec fallback and will not get the better performance.

## Supported OSes

* Windows

> [!IMPORTANT]
>
> ### Windows for ARM compatibility
>
> While it is not guaranteed, if you're on aarch64 you may be able to run compiled output via the built-in emulation.

## TODO

* Add Linux support (medium priority)
* Add macOS support (low priority)
* Support all batch features (high priority)
* Properly handle `@echo off`/`@echo on` instead of ignoring them (low priority)
* Ability to compile itself (high priority)
