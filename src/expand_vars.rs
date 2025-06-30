use std::collections::{HashMap, VecDeque};
use std::io::Write;

use crate::parse::Statement;

// Expand variables in statements by simulating label-based control flow.
pub fn expand_vars(input_file: &str, statements: &mut [Statement])
{
    // Step 1: Map labels to indices
    let mut label_map = HashMap::new();
    for (i, stmt) in statements.iter().enumerate() {
        if let Statement::Label(name) = stmt {
            label_map.insert(name.clone(), i);
        }
    }

    // Step 2: Set up the execution queue
    let mut queue = VecDeque::new();
    let mut visited = HashMap::new();
    queue.push_back((0, HashMap::new())); // start at statement 0 with empty vars

    while let Some((mut idx, mut vars)) = queue.pop_front() {
        while idx < statements.len() {
            match &mut statements[idx] {
                Statement::Set {
                    variable, value, ..
                } => {
                    // Expand strings and trim whitespace and quotes
                    let variable = expand_string(&variable[0], &vars)
                        .trim()
                        .trim_matches('"')
                        .to_string();
                    let value = expand_string(value, &vars)
                        .trim()
                        .trim_matches('"')
                        .to_string();
                    vars.insert(variable, value);
                    // Print the vars
                    println!("vars: {}", vars.iter().map(|(k, v)| format!("{}: {}", k, v)).collect::<Vec<_>>().join(", "));
                    idx += 1;
                }

                Statement::Echo { value, .. } | Statement::EchoNewLine { value, .. } => {
                    for val in value.iter_mut() {
                        *val = expand_string(val, &vars);
                    }
                    idx += 1;
                }

                Statement::Goto { label, .. } => {
                    // Expand the label
                    let label = expand_string(label, &vars);
                    if let Some(&target_idx) = label_map.get(&label) {
                        queue.push_back((target_idx, vars.clone()));
                    }
                    break; // Stop current linear flow
                }

                Statement::Exit { value, .. } => {
                    for val in value.iter_mut() {
                        *val = expand_string(val, &vars);
                    }
                    break;
                }

                Statement::Label(name) => {
                    let var_snapshot = visited.entry(name.clone()).or_insert(Vec::new());
                    if var_snapshot.contains(&vars) {
                        break; // already visited this label with same vars
                    }
                    var_snapshot.push(vars.clone());
                    idx += 1;
                }

                Statement::Identifier(name) => {
                    // Expand the identifier
                    let name = expand_string(name, &vars);
                    if let Some(value) = vars.get(&name) {
                        print!("{}", value);
                    }
                    idx += 1;
                }

                _ => idx += 1,
            }
        }
    }
}

// Replaces %VAR% in a string with values from `vars`, stripping quotes from replacements
fn expand_string(input: &str, vars: &HashMap<String, String>) -> String
{
    let re = regex::Regex::new(r#"%([^%]+)%"#).unwrap();
    re.replace_all(input, |caps: &regex::Captures| {
        if let Some(val) = vars.get(&caps[1]) {
            if val.starts_with('"') && val.ends_with('"') && val.len() >= 2 {
                val[1..val.len() - 1].to_string()
            } else {
                val.clone()
            }
        } else {
            String::new()
        }
    })
    .into_owned()
}
