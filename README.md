# compiler.bat

## Usage

Test by running test.bat:

```powershell
.\src\compiler.bat .\test\test.bat
```

You can also keep the asm code by running it like this:

```powershell
.\src\compiler.bat .\test\test.bat keep_asm # keep_asm HAS to be argument 2 because i didn't think of it since the start
```

## Limitations

* Batch file must contain an exit that will always be executed.
* Not all batch commands are implemented.

## Non-limitations

* MUCH better performance than running the batch files directly, as it directly translates batch commands to assembly equivalents.

## Commands

* EXIT
* ECHO
* GOTO
* :LABEL

## Windows for ARM compatibility
> [!IMPORTANT]
> While it is not guaranteed, if you're on aarch64 you may be able to run compiled output via the built-in emulation.

## Supported OSes

* Windows
* Linux support is planned