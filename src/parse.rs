// Abstract syntax tree for the batch compiler

use crate::tokenizer::{Token, TokenInfo};

#[derive(Debug)]
pub enum Statement
{
    Echo
    {
        value: Vec<String>,
        invisible: bool,
        redirection: Option<Redirection>,
    },
    Exit
    {
        invisible: bool,
        value: Vec<String>,
    },
    Goto
    {
        label: String,
        invisible: bool,
    },
    EchoNewLine
    {
        value: Vec<String>,
        invisible: bool,
        redirection: Option<Redirection>,
    },
    Label(String),
    Rem(String),
    Set
    {
        variable: Vec<String>,
        value: String,
        invisible: bool,
    },
    RedirectionOverwriteFile(String),
    RedirectionAppendFile(String),
    RedirectionStderrOverwriteFile(String),
    RedirectionStderrAppendFile(String),
    AmpersandOnlyIfSuccess,
    AmpersandAlways,
    NewLine,
    Identifier(String),
    Unknown(TokenInfo),
}

// Redirection structs

#[derive(Debug)]
pub struct Redirection
{
    pub kind: RedirectionKind,
    pub target: String,
}

#[derive(Debug)]
pub enum RedirectionKind
{
    Overwrite,
    Append,
    StderrOverwrite,
    StderrAppend,
}

// Helper function to parse one or more redirections after command arguments
fn parse_redirections<I>(iter: &mut std::iter::Peekable<I>) -> Option<Redirection>
where
    I: Iterator<Item = TokenInfo>,
{
    let mut redirection = None;

    // Loop to consume all redirection tokens and their targets from the iterator
    while let Some(TokenInfo { token, .. }) = iter.peek() {
        match token {
            Token::RedirectionOverwriteFile => {
                // Consume the redirection token '>'
                iter.next();
                // Consume the next token as the target filename if it's an Identifier
                if let Some(TokenInfo {
                    token: Token::Identifier(target),
                    ..
                }) = iter.next()
                {
                    redirection = Some(Redirection {
                        kind: RedirectionKind::Overwrite,
                        target,
                    })
                } else {
                    // Stop if no valid target found after redirection token
                    break;
                }
            }
            Token::RedirectionAppendFile => {
                // Consume the redirection token '>>'
                iter.next();
                // Consume the target filename token
                if let Some(TokenInfo {
                    token: Token::Identifier(target),
                    ..
                }) = iter.next()
                {
                    redirection = Some(Redirection {
                        kind: RedirectionKind::Append,
                        target,
                    })
                } else {
                    break;
                }
            }

            Token::RedirectionStderrOverwriteFile => {
                // Consume the redirection token '2>'
                iter.next();
                // Consume the target filename token
                if let Some(TokenInfo {
                    token: Token::Identifier(target),
                    ..
                }) = iter.next()
                {
                    redirection = Some(Redirection {
                        kind: RedirectionKind::StderrOverwrite,
                        target,
                    })
                } else {
                    break;
                }
            }

            Token::RedirectionStderrAppendFile => {
                // Consume the redirection token '2>>'
                iter.next();
                // Consume the target filename token
                if let Some(TokenInfo {
                    token: Token::Identifier(target),
                    ..
                }) = iter.next()
                {
                    redirection = Some(Redirection {
                        kind: RedirectionKind::StderrAppend,
                        target,
                    })
                } else {
                    break;
                }
            }
            // If no redirection token, exit the loop
            _ => break,
        }
    }

    redirection
}

pub fn parse(tokens: Vec<TokenInfo>) -> Vec<Statement>
{
    let mut statements = Vec::new();
    let mut iter = tokens.into_iter().peekable();

    while let Some(token_info) = iter.next() {
        let invisible = token_info.invisible;

        let stmt = match token_info.token {
            Token::Echo => {
                // Collect all consecutive identifiers as arguments for echo
                let mut args = Vec::new();
                while let Some(TokenInfo {
                    token: Token::Identifier(arg),
                    ..
                }) = iter.peek()
                {
                    args.push(arg.clone());
                    iter.next();
                }
                // Parse all redirections after arguments using helper function
                let redirection = parse_redirections(&mut iter);
                // Return echo statement with args invisible flag and optional redirection
                Statement::Echo {
                    value: args,
                    invisible,
                    redirection,
                }
            }

            Token::EchoNewLine => {
                // Collect all consecutive identifiers as arguments for echo
                let mut args = Vec::new();
                // Arguments will always be _NEW.LINE_
                args.push(String::from("_NEW.LINE_"));
                // Parse all redirections after arguments using helper function
                let redirection = parse_redirections(&mut iter);
                // Return echo statement with args invisible flag and optional redirection
                Statement::EchoNewLine {
                    value: args,
                    invisible,
                    redirection,
                }
            }

            Token::Identifier(identifier) => {
                // It is an identifier, so it is not a command
                // Return the identifier as a statement
                Statement::Identifier(identifier)
            }

            Token::Exit => {
                let mut args = Vec::new();
                while let Some(token_info) = iter.peek() {
                    match &token_info.token {
                        Token::Identifier(arg) => {
                            args.push(arg.clone());
                            iter.next();
                        }
                        Token::Integer(num) => {
                            args.push(num.to_string());
                            iter.next();
                        }
                        _ => break,
                    }
                }
                Statement::Exit {
                    value: args,
                    invisible,
                }
            }

            Token::Set => {
                let mut args = Vec::new();
                while let Some(token_info) = iter.peek() {
                    match &token_info.token {
                        Token::Identifier(arg) => {
                            args.push(arg.clone());
                            iter.next();
                        }
                        _ => break,
                    }
                }
                // Split args into variable and value by '=' and store each part in variable and
                // value
                let args_str = args.join("");
                let parts: Vec<&str> = args_str.split('=').collect();

                let variable = parts[0].to_string();
                // Convert variable to Vec<String>
                //let variable: Vec<String> = variable.split(' ').map(|s| s.to_string()).collect();
                let value = parts[1].to_string();

                // Strip out trailing quotes from value
                let value = value.trim_matches('"').to_string();
                // Strip out trailing quotes from variable
                let variable = variable.trim_matches('"').to_string();

                // Convert variable to Vec<String>
                let variable: Vec<String> = variable.split(' ').map(|s| s.to_string()).collect();

                Statement::Set {
                    variable,
                    value,
                    invisible,
                }
            }

            Token::Goto => {
                // Expect an identifier as the label to go to
                if let Some(TokenInfo {
                    token: Token::Identifier(label),
                    ..
                }) = iter.next()
                {
                    Statement::Goto { label, invisible }
                } else {
                    Statement::Unknown(token_info)
                }
            }

            Token::NewLine => Statement::NewLine,

            Token::Rem => {
                let mut comment = String::new();
                while let Some(next_token_info) = iter.peek() {
                    if let Token::NewLine = next_token_info.token {
                        break; // stop at newline
                    }
                    // Add the string representation of any token to the comment (not just
                    // identifiers)
                    match &next_token_info.token {
                        Token::Identifier(word) => comment.push_str(word),
                        Token::Integer(num) => comment.push_str(&num.to_string()),
                        Token::Exit => comment.push_str("exit"),
                        Token::Echo => comment.push_str("echo"),
                        Token::Goto => comment.push_str("goto"),
                        Token::Label => comment.push_str(":"),
                        Token::Rem => comment.push_str("rem"),
                        Token::RedirectionOverwriteFile => comment.push_str(">"),
                        Token::RedirectionAppendFile => comment.push_str(">>"),
                        Token::RedirectionStderrOverwriteFile => comment.push_str("2>"),
                        Token::RedirectionStderrAppendFile => comment.push_str("2>>"),
                        Token::AmpersandOnlyIfSuccess => comment.push_str("&&"),
                        Token::AmpersandAlways => comment.push_str("&"),
                        Token::NewLine => break,
                        _ => comment.push_str(&format!("{:?}", next_token_info.token)),
                    }
                    comment.push(' ');
                    iter.next(); // consume the token
                }
                Statement::Rem(comment.trim_end().to_string())
            }

            Token::Label => {
                // Expect next token as identifier for label name
                if let Some(TokenInfo {
                    token: Token::Identifier(label),
                    ..
                }) = iter.next()
                {
                    Statement::Label(label)
                } else {
                    Statement::Unknown(token_info)
                }
            }

            Token::RedirectionOverwriteFile => {
                // Consume next identifier as filename for standalone redirection statement
                if let Some(TokenInfo {
                    token: Token::Identifier(filename),
                    ..
                }) = iter.next()
                {
                    Statement::RedirectionOverwriteFile(filename)
                } else {
                    Statement::Unknown(token_info)
                }
            }

            Token::RedirectionAppendFile => {
                if let Some(TokenInfo {
                    token: Token::Identifier(filename),
                    ..
                }) = iter.next()
                {
                    Statement::RedirectionAppendFile(filename)
                } else {
                    Statement::Unknown(token_info)
                }
            }

            Token::RedirectionStderrOverwriteFile => {
                if let Some(TokenInfo {
                    token: Token::Identifier(filename),
                    ..
                }) = iter.next()
                {
                    Statement::RedirectionStderrOverwriteFile(filename)
                } else {
                    Statement::Unknown(token_info)
                }
            }

            Token::RedirectionStderrAppendFile => {
                if let Some(TokenInfo {
                    token: Token::Identifier(filename),
                    ..
                }) = iter.next()
                {
                    Statement::RedirectionStderrAppendFile(filename)
                } else {
                    Statement::Unknown(token_info)
                }
            }

            Token::AmpersandOnlyIfSuccess => Statement::AmpersandOnlyIfSuccess,

            Token::AmpersandAlways => Statement::AmpersandAlways,

            _ => Statement::Unknown(token_info),
        };

        statements.push(stmt);
    }

    statements
}
