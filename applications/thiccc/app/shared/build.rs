// /shared/build.rs
fn main() {
    uniffi::generate_scaffolding("./src/shared.udl").unwrap();
}