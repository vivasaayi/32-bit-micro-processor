use std::process::Command;

fn main() {
    // Build the kernel
    let status = Command::new("cargo")
        .args(&["build", "--bin", "aruvix_hobby_os"])
        .current_dir("kernel")
        .status()
        .expect("Failed to build kernel");

    if !status.success() {
        panic!("Kernel build failed");
    }

    // Use bootloader to create disk image
    bootloader::create_disk_image(
        "kernel/target/x86_64-unknown-none/debug/aruvix_hobby_os",
        "target/bootimage-aruvix_hobby_os.bin"
    ).expect("Failed to create disk image");

    println!("Bootable image created: target/bootimage-aruvix_hobby_os.bin");
}