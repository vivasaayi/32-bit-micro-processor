use std::env;
use std::path::PathBuf;

fn main() {
    // Tell cargo to pass the linker script to LLD
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let linker_script = manifest_dir.join("src").join("linker.ld");

    println!("cargo:rustc-link-arg=-T{}", linker_script.display());
    println!("cargo:rerun-if-changed=src/linker.ld");
    println!("cargo:rerun-if-changed=src/boot.S");
}
