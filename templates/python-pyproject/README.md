# templates/python-pyproject

This flake template builds a `devShell` based on the dependencies in a `pyproject.toml`.

## Dev Shells

Two shells are provided:

- **`default`** — Includes runtime dependencies *and* dev dependencies from `[project.optional-dependencies.dev]`. This is what you get with `nix develop`.
- **`runtime`** — Includes only the runtime dependencies from `[project.dependencies]`. Useful for verifying your production dependency set is complete. Access with `nix develop .#runtime`.

## Configuration

- **Python version**: Change `pkgs.python311` in `flake.nix` to the version you need.
- **Dev extras**: If your dev dependencies live under a different group name (e.g., `test`, `docs`), update the `extras` list in `pythonEnvDev`:
  ```nix
  extras = ["dev" "test" "docs"];
  ```

## pyproject.toml example

```toml
[project]
name = "my-app"
requires-python = ">=3.11"
dependencies = [
  "requests",
]

[project.optional-dependencies]
dev = [
  "pytest",
  "ruff",
]
```
