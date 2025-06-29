use std::io::Write;
use sha2::{Sha256, Digest};

use crate::parse::{RedirectionKind, Statement};

pub fn compile(statements: &[Statement], output_filename: &str)
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

                // Check if data section is included
                if !data_section_included {
                    writeln!(asm_file, "section .data").unwrap();
                    data_section_included = true;
                }

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
                    writeln!(asm_file, "    l{} db \"{}\", 0", hash_str, value.join(" ")).unwrap();
                }
            }

            Statement::Exit { invisible, value } => {
                if !*invisible {
                    println!("Exit command encountered");
                }
                // TODO: implement exit behavior
                break;
            }

            Statement::Goto { label, invisible } => {
                if !*invisible {
                    println!("Goto label: {}", label);
                }
            }

            Statement::Label(name) => {
                println!("Label: {}", name);
            }

            Statement::Rem(comment) => {
                // Rem comments usually don’t produce output or runtime behavior
                println!("Comment: {}", comment);
            }

            Statement::NewLine => {
                // Append a new line to the asm file
                //writeln!(asm_file).unwrap();
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

                // If there’s redirection, handle it here (placeholder)
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
                    // TODO: implement standard output
                }
            }

            Statement::Exit { invisible, value } => {
                if !*invisible {
                    println!("Exit command encountered");
                }
                // TODO: implement exit behavior
                break;
            }

            Statement::Goto { label, invisible } => {
                if !*invisible {
                    println!("Goto label: {}", label);
                }
                // TODO: implement jumping logic, label lookup etc
            }

            Statement::Label(name) => {
                println!("Label: {}", name);
                // TODO: store label location for goto
            }

            Statement::Rem(comment) => {
                // Rem comments usually don’t produce output or runtime behavior
                println!("Comment: {}", comment);
            }

            Statement::NewLine => {
                // Append a new line to the asm file
                writeln!(asm_file).unwrap();
            }

            // Handle other statements or unknowns here
            stmt => {
                println!("Unhandled statement: {:?}", stmt);
            }
        }
    }

    // Close the asm file
    asm_file.flush().unwrap();
}
