# Scapa

![master](https://github.com/brunvez/scapa/workflows/tests/badge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/brunvez/scapa/badge.svg?branch=master)](https://coveralls.io/github/brunvez/scapa?branch=master)

**A static code analysis tool focused on keeping documentation up to date with the related code.**

## Installation

The package can be installed
by adding `scapa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scapa, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```



## For devs

### Run coverage report

```bash
mix coveralls.html -o cover
```
