fn main() {
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let linker_script = format!("{}/src/linker.ld", manifest_dir);

    // Use our custom linker script
    println!("cargo:rustc-link-arg=--script={}", linker_script);

    // Set the entry point explicitly
    println!("cargo:rustc-link-arg=--entry=_start");

    println!("cargo:rerun-if-changed=src/linker.ld");
    println!("cargo:rerun-if-changed=x86_64-aruvios.json");
}
