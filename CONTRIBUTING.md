# Contributing to compiler.bat

We welcome contributions from the community, but they must follow these guidelines:

* Your code should be tested.
    To test the code, run this in a command prompt in the directory that contains the script:

    ```batch
    compiler.bat ..\test\test.bat keep_asm
    ```

* Your code should follow the style of the rest of the code.
  * Use proper tabbing.

    For example, do this:
        ```batch
        if "%foo%"=="bar" (
            echo foo
        )
        ```
        And not this:
        ```batch
        if "%foo%"=="bar" (
        echo foo
        )
        ```
* Your code should have comments documenting what it does.

    For example, do this:

    ```batch
    rem Set foo to bar
    set foo=bar
    ```

    And not this:

    ```batch
    set foo=bar
    ```

## Where to start?

Visit [this link](https://github.com/benja2998/compiler.bat/fork) to fork the compiler.bat repository.

Clone your fork to your local machine:

```bash
git clone git@github.com:your-username/compiler.bat.git
```

From there, you can make changes to the code.

*Note: You can also use https, and the name of the repo may be different if you specify a different name when you fork the repo.*

You can also make changes directly in the GitHub web interface.
