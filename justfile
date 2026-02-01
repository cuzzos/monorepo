# Cuzzo Monorepo Justfile
#
# Central command hub for all applications.
# Run `just --list` to see available commands.

# Namespaced application modules
mod thiccc 'applications/thiccc/justfile'

# Show all available commands
default:
    @just --list
