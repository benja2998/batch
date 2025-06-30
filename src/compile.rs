use std::io::Write;

use sha2::{Digest, Sha256};

use crate::parse::{RedirectionKind, Statement};

pub fn compile(statements: &[Statement], output_filename: &str, input_filename: &str)
{
    // Get file name without extension
    let filename = output_filename.split(".").collect::<Vec<&str>>()[0];
    let mut asm_filename = format!("{}.asm", filename);
    // If the asm file already exists, remove it
    if std::path::Path::new(&asm_filename).exists() {
        std::fs::remove_file(&asm_filename).unwrap();
    }
    // Create a new asm file
    let mut asm_file = std::fs::File::create(&asm_filename).unwrap();

    let mut data_section_included = false;

    writeln!(asm_file, "; Compiled by benja2998/batch").unwrap();
    writeln!(asm_file, "; Original file: {}", input_filename).unwrap();
    writeln!(asm_file, "extern CreateProcessA").unwrap();
    writeln!(asm_file, "extern ExitProcess").unwrap();
    writeln!(asm_file, "extern GetStdHandle").unwrap();
    writeln!(asm_file, "extern WriteFile").unwrap();
    writeln!(asm_file, "extern GetLastError").unwrap();
    writeln!(asm_file, "extern WriteConsoleA").unwrap();
    writeln!(asm_file, "section .bss").unwrap();
    writeln!(asm_file, "    written resd 1").unwrap();

    // Check if data section is included
    if !data_section_included {
        writeln!(asm_file, "section .data").unwrap();
        writeln!(asm_file, "    _NEW.LINE_ db 0x0D, 0x0A, 0").unwrap();
        writeln!(asm_file, "    _NEW.LINE_len equ $ - _NEW.LINE_").unwrap();
        data_section_included = true;
    }

    for stmt in statements {
        match stmt {
            Statement::Echo {
                value,
                invisible,
                redirection,
            } => {
                print!("Echo:");
                if *invisible {
                    print!(" (invisible)");
                }

                // Print out the echo arguments joined by spaces
                println!(" {}", value.join(" "));

                // Hash the echo arguments

                let mut hasher = Sha256::new();
                for arg in value {
                    hasher.update(arg.as_bytes());
                }
                let hash = hasher.finalize();
                let hash_str = format!("{:x}", hash);

                // Write the hash to the asm file
                // something like: hash db "string", 0
                // Check if the file already contains that hash
                let mut file_contents = std::fs::read_to_string(&asm_filename).unwrap();
                if !file_contents.contains(&hash_str) {
                    // Write the hash to the asm file
                    writeln!(
                        asm_file,
                        "    l{} db \"{}\", 0Dh, 0Ah",
                        hash_str,
                        value.join(" ")
                    )
                    .unwrap();
                    // Write hash length
                    writeln!(asm_file, "    l{}_len equ $ - l{}", hash_str, hash_str).unwrap();
                }
            }

            Statement::Exit { invisible, value } => {
                println!("Exit command encountered");
            }

            Statement::Goto { label, invisible } => {
                println!("Goto label: {}", label);
            }

            Statement::Label(name) => {
                println!("Label: {}", name);
            }

            Statement::Rem(comment) => {
                println!("Comment: {}", comment);
            }

            Statement::NewLine => {
                println!("New line");
            }

            Statement::EchoNewLine {
                value,
                invisible,
                redirection,
            } => {
                println!("Echo new line");
            }

            Statement::Set {
                variable,
                value,
                invisible,
            } => {
                println!("Set variable: {}", variable.join(" "));
                println!("Value: {}", value);

                // Set is handled in expand_vars.rs before compilation
                // This is because batch works by expanding variables
            }

            stmt => {
                println!("Unhandled statement: {:?}", stmt);
            }
        }
    }

    // Close the asm file
    asm_file.flush().unwrap();

    // Enter the second phase of compilation
    compile_phase_2(statements, output_filename);
}

fn compile_phase_2(statements: &[Statement], output_filename: &str)
{
    // Get file name without extension
    let filename = output_filename.split(".").collect::<Vec<&str>>()[0];
    let mut asm_filename = format!("{}.asm", filename);
    // By this point, the asm file should exist already
    let mut asm_file = std::fs::OpenOptions::new()
        .write(true)
        .append(true)
        .open(&asm_filename)
        .unwrap();

    let mut text_section_included = false;

    if !text_section_included {
        writeln!(asm_file, "section .text").unwrap();
        writeln!(asm_file, "    global _start").unwrap();
        writeln!(asm_file, "_start:").unwrap();
        text_section_included = true;
    }

    for stmt in statements {
        match stmt {
            Statement::Echo {
                value,
                invisible,
                redirection,
            } => {
                print!("Echo:");
                if *invisible {
                    print!(" (invisible)");
                }

                // Print out the echo arguments joined by spaces
                println!(" {}", value.join(" "));

                // If there's redirection, handle it here
                if let Some(redir) = redirection {
                    match redir.kind {
                        RedirectionKind::Overwrite => {
                            println!("Redirecting output to {}", redir.target);
                            // TODO: implement file write overwrite
                        }
                        RedirectionKind::Append => {
                            println!("Appending output to {}", redir.target);
                            // TODO: implement file append
                        }
                        RedirectionKind::StderrOverwrite => {
                            println!("Redirecting stderr to {}", redir.target);
                            // TODO: implement stderr redirect overwrite
                        }
                        RedirectionKind::StderrAppend => {
                            println!("Appending stderr to {}", redir.target);
                            // TODO: implement stderr append
                        }
                    }
                } else {
                    println!("No redirection");
                    // Hash the echo arguments

                    let mut hasher = Sha256::new();
                    for arg in value {
                        hasher.update(arg.as_bytes());
                    }
                    let hash = hasher.finalize();
                    let hash_str = format!("{:x}", hash);

                    // We will use Windows x64 calling convention to call WriteConsoleA
                    // We also need to get std handle.

                    writeln!(asm_file, "sub rsp, 40").unwrap();
                    writeln!(asm_file, "mov ecx, -11").unwrap();
                    writeln!(asm_file, "call GetStdHandle").unwrap();
                    writeln!(asm_file, "mov rcx, rax").unwrap();
                    writeln!(asm_file, "lea rdx, [rel l{}]", hash_str).unwrap();
                    writeln!(asm_file, "mov r8d, l{}_len", hash_str).unwrap();
                    writeln!(asm_file, "lea r9, [rel written]").unwrap();
                    writeln!(asm_file, "call WriteConsoleA").unwrap();
                    writeln!(asm_file, "add rsp, 40").unwrap();
                }
            }

            Statement::EchoNewLine {
                value,
                invisible,
                redirection,
            } => {
                print!("Echo:");
                if *invisible {
                    print!(" (invisible)");
                }

                // Print out the echo arguments joined by spaces
                println!(" {}", value.join(" "));

                // If there's redirection, handle it here
                if let Some(redir) = redirection {
                    match redir.kind {
                        RedirectionKind::Overwrite => {
                            println!("Redirecting output to {}", redir.target);
                            // TODO: implement file write overwrite
                        }
                        RedirectionKind::Append => {
                            println!("Appending output to {}", redir.target);
                            // TODO: implement file append
                        }
                        RedirectionKind::StderrOverwrite => {
                            println!("Redirecting stderr to {}", redir.target);
                            // TODO: implement stderr redirect overwrite
                        }
                        RedirectionKind::StderrAppend => {
                            println!("Appending stderr to {}", redir.target);
                            // TODO: implement stderr append
                        }
                    }
                } else {
                    println!("No redirection");

                    // We will use Windows x64 calling convention to call WriteConsoleA
                    // We also need to get std handle.

                    writeln!(asm_file, "sub rsp, 40").unwrap();
                    writeln!(asm_file, "mov ecx, -11").unwrap();
                    writeln!(asm_file, "call GetStdHandle").unwrap();
                    writeln!(asm_file, "mov rcx, rax").unwrap();
                    writeln!(asm_file, "lea rdx, [rel _NEW.LINE_]").unwrap();
                    writeln!(asm_file, "mov r8d, _NEW.LINE_len").unwrap();
                    writeln!(asm_file, "lea r9, [rel written]").unwrap();
                    writeln!(asm_file, "call WriteConsoleA").unwrap();
                    writeln!(asm_file, "add rsp, 40").unwrap();
                }
            }

            Statement::Exit { invisible, value } => {
                if !*invisible {
                    println!("Exit command encountered");
                }
                // Use Windows x64 calling convention to call ExitProcess

                writeln!(asm_file, "sub rsp, 40").unwrap();
                let mut exit_code = 0; // Initialize with default value

                // Loop for each argument
                for arg in value {
                    // Check if the argument is a number
                    if let Ok(num) = arg.parse::<i32>() {
                        exit_code = num;
                        break;
                    }
                }

                writeln!(asm_file, "mov ecx, {}", exit_code).unwrap();
                writeln!(asm_file, "call ExitProcess").unwrap();
            }

            Statement::Goto { label, invisible } => {
                if !*invisible {
                    println!("Goto label: {}", label);
                }
                // This translates exactly to a jmp instruction
                writeln!(asm_file, "jmp {}", label).unwrap();
            }

            Statement::Label(name) => {
                println!("Label: {}", name);
                // This translates exactly to a label
                writeln!(asm_file, "{}:", name).unwrap();
            }

            Statement::Rem(comment) => {
                // Translate it to a ;
                println!("Rem: {}", comment);
                writeln!(asm_file, "; {}", comment).unwrap();
            }

            Statement::Set {
                variable,
                value,
                invisible,
            } => {
                println!("Set variable: {}", variable.join(" "));
                println!("Value: {}", value);

                // Set is handled in expand_vars.rs before compilation
                // This is because batch works by expanding variables
            }

            Statement::NewLine => {
                // Append a new line to the asm file
                writeln!(asm_file).unwrap();
            }

            stmt => {
                println!("Unhandled statement: {:?}", stmt);
            }
        }
    }

    // Close the asm file
    asm_file.flush().unwrap();
}
