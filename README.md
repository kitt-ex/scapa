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

## Usage

The purpose of `Scapa` is to let you know when documentation needs to be updated. It does so
by keeping track of how a function signature changes. For example, if there's a function `get_user` defined as

```elixir
@doc "Gets a user from a user_id"
def get_user(user_id) do
  # ...
end
```

Which then changes to

```elixir
@doc "Gets a user from a user_id"
def get_user(query) do
  # ...
end
```

`Scapa` will prompt you to revise the documentation of that function since the signature has changed.

The way it tracks what needs to be updated is by assigning versions based on the signature. These versions can be stored in two places, each
with their own trade offs.

### Tags

The first way to store the versions is by using `@doc` tags with custom attributes. This keeps the version above the function definition:

```elixir
@doc "Gets a user from a user_id"
@doc version: "ODgwNzQxMg"
def get_user(user_id) do
  # ...
end
```

This setting is great to avoid merge conflicts, keep the data close to the source and be reminded of the documentation changes that need to happen. On
the other hand though, it can make your code "dirty" by adding metadata that could get in the way.

### Versions file

The alternation to tags is keeping a versions file (by default `priv/doc_versions.ex`) which contains the versions of all the functions in the entire project.
Assuming our example function belongs to the `User` module, the file would look like this:

```elixir
# priv/doc_versions.ex
%{
  # ...
  {User, :get_user, 1} => "ODgwNzQxMg",
  # ...
}
```

In this way we keep the metadata away from our code, but this can cause more merge conflicts (which we mitigate by ordering the keys alphabetically). It could also
become a just a file that gets automatically updated and not really payed attention to.

It's up to your team to decide which version to use based on your preferences and project needs.

### Running Scapa

In order for `Scapa` to actually do something you'll want to run a mix task. The two tasks provided are:

- `scapa`
- `scapa.gen.versions`

After you install scapa ideally you want to configure it and run `mix scapa.gen.versions` which will scan your code for the first time, determine which functions
need to be versioned and then store those versions.

When working on a feature or in the CI environment you probably want to run `mix scapa`. This task will give you a detailed output of which functions need to be
versioned and which functions have changed so you may revise the documentation for any outdated content. Something like this:

```
...
File lib/your_project/config.ex is up to date.
File lib/your_project/user.ex has a function with a missing or outdated version number.
lib/your_project/user.ex:16: User.get_user/1 outdated version
  @doc version: "ODgwNzQxMg"
  def get_user(user_id) do
    # ...
```

After that you can either update the version manually or run `mix scapa.gen.versions` again so the tool does it for you.


## Configuration

`Scapa` allows configurations through the `.scapa.exs` file. This file must contain a keyword list with the options listed below

- **include:** A list or a singular glob expression of the files you wish `Scapa` to keep track of. Defaults to `"lib/**/*.ex"`
- **store:** Where the function signature versions will be stored. The possible values are `:tags`, `:file` or `{:file, file_path}`. Defaults to `:tags`

The default configuration looks like this

```elixir
# .scapa.exs
[
  include: "lib/**/*.ex",
  store: :tags
]
```

You can run `mix scapa.gen.config` to have this file created automatically for you.

## Contributing
1. Fork it!
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Fetch (`mix deps.get`)
1. Make sure everything works correctly (`mix test`)
1. Implement your feature!
1. Commit your changes (git commit -am 'Add some feature')
1. Push to the branch (git push origin my-new-feature)
1. Create new Pull Request

## License
Scapa is released under the MIT License. See the LICENSE file for further details.
