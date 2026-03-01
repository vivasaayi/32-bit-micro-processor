use clap::{Parser, Subcommand};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

#[derive(Parser)]
#[command(name = "riscv_test_runner")]
#[command(about = "RISC-V Cross-Check Test Runner")]
struct Cli {
    #[arg(short, long, default_value = "test_report.html")]
    output: String,
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    RiscvAssemblerOnRiscvCore {
        #[arg(num_args = 0..)]
        paths: Vec<String>,
    },
    RiscvAssemblerOnAruviCore { #[arg(num_args = 0..)] paths: Vec<String> },
    AruviAssemblerOnRiscvCore { #[arg(num_args = 0..)] paths: Vec<String> },
    AruviAssemblerOnAruviCore { #[arg(num_args = 0..)] paths: Vec<String> },
}

#[derive(Debug)]
struct TestResult {
    file: String,
    passed: bool,
    output: String,
}

fn collect_asm_files(path: &Path, out: &mut Vec<PathBuf>) {
    if path.is_file() {
        if path.extension().and_then(|e| e.to_str()) == Some("s") {
            out.push(path.to_path_buf());
        }
    } else if path.is_dir() {
        if let Ok(entries) = fs::read_dir(path) {
            let mut children: Vec<_> = entries.flatten().map(|e| e.path()).collect();
            children.sort();
            for child in children {
                collect_asm_files(&child, out);
            }
        }
    }
}

fn resolve_files(paths: &[String], root: &Path) -> Vec<PathBuf> {
    let roots: Vec<PathBuf> = if paths.is_empty() {
        vec![root.join("sample_programs")]
    } else {
        paths.iter().map(|p| {
            let pb = PathBuf::from(p);
            if pb.is_absolute() { pb } else { root.join(p) }
        }).collect()
    };
    let mut files = Vec::new();
    for r in roots {
        collect_asm_files(&r, &mut files);
    }
    files
}

fn find_project_root() -> PathBuf {
    let cwd = std::env::current_dir().expect("cwd");
    let mut dir = cwd.clone();
    loop {
        if dir.join("sample_programs").exists() && dir.join("Makefile").exists() {
            return dir;
        }
        if !dir.pop() {
            return cwd;
        }
    }
}

fn run_riscv_asm_on_qemu(asm_file: &Path, root: &Path) -> (bool, String) {
    let tmp = root.join("temp");
    let _ = fs::create_dir_all(&tmp);
    let obj = tmp.join("test.o");
    let elf = tmp.join("test.elf");
    let ld  = tmp.join("link.ld");
    let mut log = String::new();

    let r = Command::new("riscv64-elf-as")
        .arg(asm_file).arg("-o").arg(&obj)
        .current_dir(root)
        .stdout(Stdio::piped()).stderr(Stdio::piped())
        .output();
    match r {
        Err(e) => return (false, format!("assembler error: {}", e)),
        Ok(o) => {
            log += &String::from_utf8_lossy(&o.stderr);
            if !o.status.success() {
                return (false, format!("assemble failed:\n{}", log));
            }
        }
    }

    let r = Command::new("riscv64-elf-ld")
        .arg("-T").arg(&ld).arg(&obj).arg("-o").arg(&elf)
        .current_dir(root)
        .stdout(Stdio::piped()).stderr(Stdio::piped())
        .output();
    match r {
        Err(e) => return (false, format!("linker error: {}", e)),
        Ok(o) => {
            log += &String::from_utf8_lossy(&o.stderr);
            if !o.status.success() {
                return (false, format!("link failed:\n{}", log));
            }
        }
    }

    let r = Command::new("gtimeout")
        .arg("10")
        .arg("qemu-system-riscv32")
        .arg("-nographic")
        .arg("-machine").arg("virt")
        .arg("-bios").arg("none")
        .arg("-kernel").arg(&elf)
        .current_dir(root)
        .stdout(Stdio::piped()).stderr(Stdio::piped())
        .output();
    match r {
        Err(e) => (false, format!("qemu error: {}", e)),
        Ok(o) => {
            let stdout = String::from_utf8_lossy(&o.stdout).to_string();
            let stderr = String::from_utf8_lossy(&o.stderr).to_string();
            log += &stdout;
            log += &stderr;
            let passed = stdout.contains("PASS") || stderr.contains("PASS");
            (passed, log)
        }
    }
}

fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
}

fn generate_html_report(results: &[TestResult], title: &str) -> String {
    let total  = results.len();
    let passed = results.iter().filter(|r| r.passed).count();
    let failed = total - passed;

    let mut html = format!(
        "<!DOCTYPE html><html><head><title>RISC-V Test Report</title><style>\
         body{{font-family:Arial,sans-serif;margin:20px}}\
         .summary{{background:#f0f0f0;padding:10px;border-radius:5px;margin-bottom:20px}}\
         .test{{border:1px solid #ccc;margin:8px 0;padding:10px;border-radius:5px}}\
         .passed{{background:#d4edda;border-color:#c3e6cb}}\
         .failed{{background:#f8d7da;border-color:#f5c6cb}}\
         .log{{background:#f8f9fa;padding:8px;margin-top:8px;border-radius:3px;\
               white-space:pre-wrap;font-family:monospace;font-size:.82em}}\
         </style></head><body>\
         <h1>RISC-V Cross-Check</h1><h2>{}</h2>\
         <div class=\"summary\">Total: <b>{}</b> &nbsp; \
         <span style=\"color:green\">Passed: {} ✓</span> &nbsp; \
         <span style=\"color:red\">Failed: {} ✗</span></div>\n",
        title, total, passed, failed
    );

    for r in results {
        let cls = if r.passed { "passed" } else { "failed" };
        let st  = if r.passed { "PASSED" } else { "FAILED" };
        html += &format!(
            "<div class=\"test {}\"><b>{}</b> — {}<div class=\"log\">{}</div></div>\n",
            cls, html_escape(&r.file), st, html_escape(&r.output)
        );
    }
    html += "</body></html>\n";
    html
}

fn main() {
    let cli  = Cli::parse();
    let root = find_project_root();
    println!("Project root: {}", root.display());
    let report = root.join(&cli.output);

    match cli.command {
        Commands::RiscvAssemblerOnRiscvCore { paths } => {
            let files = resolve_files(&paths, &root);
            println!("Found {} assembly file(s)", files.len());

            let results: Vec<TestResult> = files.iter().map(|f| {
                let label = f.strip_prefix(&root).unwrap_or(f).display().to_string();
                println!("  Testing: {}", label);
                let (passed, output) = run_riscv_asm_on_qemu(f, &root);
                println!("    => {}", if passed { "PASS" } else { "FAIL" });
                TestResult { file: label, passed, output }
            }).collect();

            let p = results.iter().filter(|r| r.passed).count();
            println!("\nResults: {}/{} passed", p, results.len());

            fs::write(&report, generate_html_report(&results, "RISC-V Assembler on RISC-V Core"))
                .expect("Failed to write report");
            println!("Report: {}", report.display());
        }
        _ => println!("Not yet implemented"),
    }
}
