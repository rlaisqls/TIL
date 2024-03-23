## go.mod

Module is go support for dependency management. A module by definition is a collection of related packages with `go.mod` at its root. The go.mod file defines the:

- **Module import path.**
- **The version** of go with which the module is created
- **Dependency requirements of the module for a successful build**. It defines both project’s dependencies requirement and also locks them to their correct version.

go.mod file only records the direct dependency. However, it may record an indirect dependency in the below case

Any indirect dependency which is not listed in the go.mod file of your direct dependency or if direct dependency doesn’t have a go.mod file, then that dependency will be added to the go.mod file with `//indirect` as the suffix.

## go.sum

This file lists down the checksum of direct and indirect dependency required along with the version.

It is to be mentioned that the go.mod file is enough for a successful build. And the checksum present in `go.sum` file is used to **validate the checksum of each of direct and indirect dependency to confirm that none of them has been modified.**

---
reference
- https://golangbyexample.com/go-mod-sum-module/