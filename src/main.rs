mod compile;
mod expand_vars;
mod parse;
mod tokenizer;

use std::env;
use std::process::Command;
use std::time::Instant;

use clap::Parser;
use which::which;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args
{
    /// Output executable to compile input file to
    #[arg(short, long)]
    output: String,

    /// Input batch file to compile
    #[arg(short, long)]
    input: String,
}

fn main()
{
    let start_time = Instant::now();

    if env::args().len() < 3 {
        eprintln!("Usage: batch-compiler -o <output> -i <input>");
        std::process::exit(1);
    }

    let args = Args::parse();
    println!("Compile {} to {}", args.input, args.output);

    if !std::path::Path::new(&args.input).exists() {
        eprintln!("Input file does not exist");
        std::process::exit(1);
    }

    if args.input == args.output {
        eprintln!("Input and output files cannot be the same");
        std::process::exit(1);
    }

    if std::path::Path::new(&args.output).exists() {
        std::fs::remove_file(&args.output).unwrap();
    }

    let output_filename = args.output.split('.').collect::<Vec<&str>>()[0];

    let asm_path = format!("{}.asm", output_filename);
    if std::path::Path::new(&asm_path).exists() {
        std::fs::remove_file(&asm_path).unwrap();
    }

    println!("Checks passed, begin tokenization");

    let file_contents = std::fs::read_to_string(&args.input).expect("Failed to read input file");

    let tokens = tokenizer::tokenize(&file_contents);
    println!("Tokenization complete");
    println!("Tokens: {}", tokens.len());
    for token_info in &tokens {
        println!(
            "{:?} (invisible: {})",
            token_info.token, token_info.invisible
        );
    }

    println!("Begin parsing");
    let mut statements = parse::parse(tokens);
    println!("Parsing complete");
    println!("Statements: {}", statements.len());
    for stmt in &statements {
        println!("{:?}", stmt);
    }

    println!("Begin variable expansion");
    expand_vars::expand_vars(&args.input, &mut statements);
    println!("Variable expansion complete");

    println!("Begin compilation");
    compile::compile(&statements, &args.output, &args.input);
    println!("Compilation complete");

    let duration = start_time.elapsed();
    println!("Total compile time: {:.2?}", duration);

    println!("Assembling program");

    if cfg!(target_os = "windows") {
        // Check required tools
        if which("nasm").is_err() {
            eprintln!("Error: 'nasm' not found. Please install it via Scoop or manually.");
            std::process::exit(1);
        }
        if which("lld-link").is_err() {
            eprintln!(
                "Error: 'lld-link' not found. Please install LLVM via a package that includes lld-link."
            );
            std::process::exit(1);
        }

        // Assemble
        let nasm_status = Command::new("nasm")
            .arg("-f")
            .arg("win64")
            .arg(&asm_path)
            .arg("-o")
            .arg(format!("{}.obj", output_filename))
            .status()
            .expect("Failed to run nasm");
        if !nasm_status.success() {
            eprintln!("nasm failed");
            std::process::exit(1);
        }

        // Link
        let link_status = Command::new("lld-link")
            .arg(format!("{}.obj", output_filename))
            .arg("kernel32.lib")
            .arg("/subsystem:console")
            .arg("/entry:_start")
            .arg(format!("/out:{}", &args.output))
            .status()
            .expect("Failed to run lld-link");
        if !link_status.success() {
            eprintln!("lld-link failed");
            std::process::exit(1);
        }
    } else {
        // Assume Linux with nasm + ld
        if which("nasm").is_err() {
            eprintln!("Error: 'nasm' not found. Install it with your package manager.");
            std::process::exit(1);
        }
        if which("ld").is_err() {
            eprintln!("Error: 'ld' not found. Install it with your package manager.");
            std::process::exit(1);
        }

        let nasm_status = Command::new("nasm")
            .arg("-f")
            .arg("win64")
            .arg(&asm_path)
            .arg("-o")
            .arg(format!("{}.o", output_filename))
            .status()
            .expect("Failed to run nasm");
        if !nasm_status.success() {
            eprintln!("nasm failed");
            std::process::exit(1);
        }

        let ld_status = Command::new("ld")
            .arg("-o")
            .arg(&args.output)
            .arg(format!("{}.o", output_filename))
            .status()
            .expect("Failed to run ld");
        if !ld_status.success() {
            eprintln!("ld failed");
            std::process::exit(1);
        }
    }

    println!("Build successful: {}", args.output);
}
