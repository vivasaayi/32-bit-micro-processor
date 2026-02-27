use clap::{Parser, Subcommand};
use std::process::{Command, Stdio};
use std::fs;
use std::path::Path;

#[derive(Parser)]
#[command(name = "riscv_test_runner")]
#[command(about = "RISC-V Cross-Check Test Runner")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Run assembly using RISC-V assembler on RISC-V core (QEMU)
    RiscvAssemblerOnRiscvCore {
        /// Assembly file(s) to test (if not specified, runs all)
        #[arg(short, long)]
        files: Vec<String>,
    },
    /// Run assembly using RISC-V assembler on Aruvi core
    RiscvAssemblerOnAruviCore {
        /// Assembly file(s) to test
        #[arg(short, long)]
        files: Vec<String>,
    },
    /// Run assembly using Aruvi assembler on RISC-V core
    AruviAssemblerOnRiscvCore {
        /// Assembly file(s) to test
        #[arg(short, long)]
        files: Vec<String>,
    },
    /// Run assembly using Aruvi assembler on Aruvi core
    AruviAssemblerOnAruviCore {
        /// Assembly file(s) to test
        #[arg(short, long)]
        files: Vec<String>,
    },
}

#[derive(Debug)]
struct TestResult {
    file: String,
    passed: bool,
    output: String,
    error: String,
}

fn run_make_command(make_target: &str, file: Option<&str>) -> Result<String, String> {
    let mut cmd = Command::new("make");
    cmd.arg(make_target)
       .current_dir("/Users/rajanpanneerselvam/work/AruviXPlatform")
       .stdout(Stdio::piped())
       .stderr(Stdio::piped());

    if let Some(f) = file {
        cmd.env("FILE", f);
    }

    let output = cmd.output().map_err(|e| format!("Failed to run make: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();

    if output.status.success() {
        Ok(format!("{}{}", stdout, stderr))
    } else {
        Err(format!("Make failed: {}{}", stdout, stderr))
    }
}

fn run_test(make_target: &str, file: &str) -> TestResult {
    let result = run_make_command(make_target, Some(file));
    let (passed, output, error) = match result {
        Ok(out) => {
            let pass = out.contains("PASS");
            (pass, out, String::new())
        }
        Err(err) => (false, String::new(), err),
    };

    TestResult {
        file: file.to_string(),
        passed,
        output,
        error,
    }
}

fn find_assembly_files() -> Vec<String> {
    let mut files = Vec::new();
    let patterns = [
        "sample_programs/arithmetic/assembly/handcrafted/*.s",
        "sample_programs/graphics/assembly/handcrafted/*.s",
        "sample_programs/functions/assembly/handcrafted/*.s",
    ];

    for pattern in &patterns {
        if let Ok(entries) = glob::glob(&format!("/Users/rajanpanneerselvam/work/AruviXPlatform/{}", pattern)) {
            for entry in entries {
                if let Ok(path) = entry {
                    if let Some(file) = path.to_str() {
                        files.push(file.to_string());
                    }
                }
            }
        }
    }

    files
}

fn generate_html_report(results: &[TestResult], test_name: &str) -> String {
    let total = results.len();
    let passed = results.iter().filter(|r| r.passed).count();
    let failed = total - passed;

    let mut html = format!(r#"<!DOCTYPE html>
<html>
<head>
    <title>RISC-V Test Report - {}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .summary {{ background: #f0f0f0; padding: 10px; border-radius: 5px; margin-bottom: 20px; }}
        .test {{ border: 1px solid #ccc; margin: 10px 0; padding: 10px; border-radius: 5px; }}
        .passed {{ background: #d4edda; border-color: #c3e6cb; }}
        .failed {{ background: #f8d7da; border-color: #f5c6cb; }}
        .output {{ background: #f8f9fa; padding: 10px; margin-top: 10px; border-radius: 3px; white-space: pre-wrap; font-family: monospace; }}
    </style>
</head>
<body>
    <h1>RISC-V Cross-Check Test Report</h1>
    <h2>Test: {}</h2>
    <div class="summary">
        <h3>Summary</h3>
        <p>Total Tests: {}</p>
        <p>Passed: {} <span style="color: green;">✓</span></p>
        <p>Failed: {} <span style="color: red;">✗</span></p>
    </div>
"#, test_name, test_name, total, passed, failed);

    for result in results {
        let class = if result.passed { "passed" } else { "failed" };
        let status = if result.passed { "PASSED" } else { "FAILED" };

        html.push_str(&format!(r#"
    <div class="test {}">
        <h4>File: {} - {}</h4>
        <div class="output">
            <strong>Output:</strong><br>{}
        </div>
        <div class="output">
            <strong>Error:</strong><br>{}
        </div>
    </div>
"#, class, result.file, status, result.output, result.error));
    }

    html.push_str("</body></html>");
    html
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::RiscvAssemblerOnRiscvCore { files } => {
            let test_files = if files.is_empty() {
                find_assembly_files()
            } else {
                files
            };

            let mut results = Vec::new();
            for file in &test_files {
                println!("Running test for: {}", file);
                let result = run_test("run_assembly_using_riscv_assembler_on_riscv_core", file);
                results.push(result);
            }

            let html = generate_html_report(&results, "RISC-V Assembler on RISC-V Core");
            fs::write("test_report.html", html).expect("Failed to write report");
            println!("Report generated: test_report.html");
        }
        Commands::RiscvAssemblerOnAruviCore { files } => {
            println!("RISC-V Assembler on Aruvi Core test not yet implemented");
        }
        Commands::AruviAssemblerOnRiscvCore { files } => {
            println!("Aruvi Assembler on RISC-V Core test not yet implemented");
        }
        Commands::AruviAssemblerOnAruviCore { files } => {
            println!("Aruvi Assembler on Aruvi Core test not yet implemented");
        }
    }
}
