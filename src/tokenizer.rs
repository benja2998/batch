#[derive(Debug, PartialEq, Eq)]
pub enum Token
{
    Echo,
    EchoNewLine,
    Exit,
    Goto,
    Rem,
    Label,
    Set,
    RedirectionOverwriteFile,
    RedirectionAppendFile,
    RedirectionStderrOverwriteFile,
    RedirectionStderrAppendFile,
    AmpersandOnlyIfSuccess,
    AmpersandAlways,
    NewLine,
    CmdLineOption,
    String(String),
    Identifier(String),
}

#[derive(Debug, PartialEq, Eq)]
pub struct TokenInfo
{
    pub token: Token,
    pub invisible: bool,
}

pub fn tokenize(input: &str) -> Vec<TokenInfo>
{
    let mut tokens = Vec::new();
    let mut chars = input.chars().peekable();
    let mut next_invisible = false;
    let mut is_after_newline = true;

    while let Some(&ch) = chars.peek() {
        // Skip carriage returns to handle Windows CRLF newlines
        if ch == '\r' {
            chars.next();
            continue;
        }

        if ch.is_whitespace() && ch != '\n' {
            chars.next();
            continue;
        }

        if ch == '@' {
            println!("Found @");
            chars.next();
            next_invisible = true;
            continue;
        }

        if ch == '\n' {
            println!("Found newline");
            tokens.push(TokenInfo {
                token: Token::NewLine,
                invisible: next_invisible,
            });
            chars.next();
            next_invisible = false;
            is_after_newline = true;
            continue;
        }

        if ch == '&' {
            println!("Found &");
            chars.next();
            let token = if chars.peek() == Some(&'&') {
                chars.next();
                Token::AmpersandOnlyIfSuccess
            } else {
                Token::NewLine // Basically a new command
            };
            tokens.push(TokenInfo {
                token,
                invisible: next_invisible,
            });
            next_invisible = false;
            is_after_newline = true;
            continue;
        }

        if ch == '>' {
            println!("Found >");
            chars.next();
            let token = if chars.peek() == Some(&'>') {
                chars.next();
                Token::RedirectionAppendFile
            } else {
                Token::RedirectionOverwriteFile
            };
            tokens.push(TokenInfo {
                token,
                invisible: next_invisible,
            });
            next_invisible = false;
            continue;
        }

        if ch == ':' {
            println!("Found :");
            chars.next(); // consume first ':'

            if chars.peek() == Some(&':') {
                println!("Found :: (comment)");
                chars.next(); // consume second ':'
                tokens.push(TokenInfo {
                    token: Token::Rem,
                    invisible: next_invisible,
                });
            } else {
                tokens.push(TokenInfo {
                    token: Token::Label,
                    invisible: next_invisible,
                });
            }

            next_invisible = false;
            continue;
        }

        if ch == '2' {
            // Check if the next character is '>' and if so it's redirecting stderr somewhere
            // After that check if the next character is also '>' and if so it's redirecting stderr
            // somewhere and appending
            if chars.peek() == Some(&'>') {
                chars.next();
                let token = if chars.peek() == Some(&'>') {
                    chars.next();
                    Token::RedirectionStderrAppendFile
                } else {
                    Token::RedirectionStderrOverwriteFile
                };
                tokens.push(TokenInfo {
                    token,
                    invisible: next_invisible,
                });
                next_invisible = false;
                continue;
            }
        }

        let mut word = String::new();
        while let Some(&c) = chars.peek() {
            if c.is_whitespace() || c == '&' || c == '>' || c == '@' {
                break;
            }
            word.push(c);
            chars.next();
        }

        let token = match word.to_ascii_lowercase().as_str() {
            "echo" if is_after_newline => Token::Echo,
            "exit" if is_after_newline => Token::Exit,
            "goto" if is_after_newline => Token::Goto,
            "rem" if is_after_newline => Token::Rem,
            "echo." if is_after_newline => Token::EchoNewLine,
            "set" if is_after_newline => Token::Set,
            _ => {
                Token::Identifier(word)
            }
        };

        tokens.push(TokenInfo {
            token,
            invisible: next_invisible,
        });
        next_invisible = false;
        is_after_newline = false;
    }

    tokens
}