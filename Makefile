.PHONY: install clean

install:
	cargo install --path .

run:
	batch-compiler $(ARGS)

test1:
	cargo install --path .
	clear
	batch-compiler -o test.exe -i examples\hello.bat

test2:
	cargo install --path .
	clear
	batch-compiler -o test.exe -i examples\labels.bat

test3:
	cargo install --path .
	clear
	batch-compiler -o test.exe -i examples\vars.bat

clean:
	cargo clean
