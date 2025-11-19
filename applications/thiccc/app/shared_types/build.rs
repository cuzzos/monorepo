use crux_core::typegen::TypeGen;
use shared::Thiccc;
use std::path::PathBuf;

fn main() -> anyhow::Result<()> {
    println!("cargo:rerun-if-changed=../shared");

    let mut typegen = TypeGen::new();

    typegen.register_app::<Thiccc>()?;

    let output_root = PathBuf::from("./generated");

    typegen.swift("SharedTypes", output_root.join("swift"))?;

    Ok(())
}

