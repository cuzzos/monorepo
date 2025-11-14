fn main() {
    uniffi::generate_scaffolding("./src/shared.udl")
        .expect("Failed to generate UniFFI scaffolding");
}

