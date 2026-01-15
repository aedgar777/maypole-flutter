fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android deploy_dev_internal

```sh
[bundle exec] fastlane android deploy_dev_internal
```

Deploy dev build to Play Store Internal Testing track

### android deploy_beta_open

```sh
[bundle exec] fastlane android deploy_beta_open
```

Deploy prod build to Play Store Open Testing (beta) track

### android promote_to_production

```sh
[bundle exec] fastlane android promote_to_production
```

Promote build from beta to production

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
