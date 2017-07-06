# ksr-maybe

This gem provides a `Maybe` type. The `Maybe` type either contains a value
(represented as `Just`) or it is empty (represented as `Nothing`).

# Installation

Install the `ksr-maybe` gem, or add it to your Gemfile with bundler:

```ruby
# In your Gemfile
gem 'ksr-maybe'
```

# Usage

Maybe is useful for handling potentially null values:

```ruby
User = Struct.new(:email, :name)

users = [
  User.new("jane@doe.com", "Jane Doe"),
  User.new("john@doe.com", "John Doe")
]

# When value is not null

user = users.find { |user| user.email == "jane@doe.com" }

Maybe.from_nullable(user)
  .map { |user| user.name }
  .get_or_else { "User not found" }

#=> "Jane Doe"

# When value is null

user = users.find { |user| user.email == "not@present.com" }

Maybe.from_nullable(user)
  .map { |user| user.name }
  .get_or_else { "User not found" }

#=> "User not found"
```

## Contracts

This gem utilizes the ['contracts.ruby' gem][contracts], which adds dynamic type-checking to the 'ruby-maybe' codebase. By default, the 'contracts.ruby' gem will `raise` an error during runtime upon a type mismatch. To override this error throwing behavior, see [this 'contracts.ruby' documentation][contracts-override].

## Licenses

See [LICENSES.md](./LICENSES.md).

[contracts]: http://egonschiele.github.io/contracts.ruby/
[contracts-override]: https://github.com/egonSchiele/contracts.ruby/blob/master/TUTORIAL.md#failure-callbacks
