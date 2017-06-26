# ksr-maybe

This gem provides a `Maybe` type. The `Maybe` type either contains a value
(represented as `Just`) or it is empty (represented as `Nothing`).


## Contracts

This gem utilizes the ['contracts.ruby' gem][contracts], which adds dynamic type-checking to the 'ruby-maybe' codebase. By default, the 'contracts.ruby' gem will `raise` an error during runtime upon a type mismatch. To override this error throwing behavior, see [this 'contracts.ruby' documentation][contracts-override].

## Licenses

See [LICENSES.md](./LICENSES.md).

[contracts]: http://egonschiele.github.io/contracts.ruby/
[contracts-override]: https://github.com/egonSchiele/contracts.ruby/blob/master/TUTORIAL.md#failure-callbacks
