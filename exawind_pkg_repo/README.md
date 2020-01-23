This is a [spack repository](https://spack.readthedocs.io/en/latest/repositories.html) for overriding problem packages.
It allows us to update packages without creating conflicts in our spack git repositories, but it also allows us to make updates without having to wait for spack to merge files in.

To use make sure you've sourced spack and then issue the command

```
spack repo add [build_test_location]/exawind_pkg_repo]
```

Now the package files in this repo will take precident over the builtin packages.