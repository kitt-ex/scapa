# Change log
## master (unreleased)

### New features
- Allows storing versions on a dedicated file
- Version macro docs
- Does not override unchanged files
- Shows errors per file

### Bug fixes
- Fix multiple versions or errors for injected functions
- Fix error on project with nested modules

## 0.1.1 (2022-05-09)

### Bug fixes
- Fix `mix scapa.gen.versions` not running due to compilation not being required.

## 0.1.0 (2022-05-09)

### New features

- Run `mix scapa.gen.versions` to setup the project, adding doc versions to all @doc tags.
- Use `.scapa.exs` to config the mix tasks.
