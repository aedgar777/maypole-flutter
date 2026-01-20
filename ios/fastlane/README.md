fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios sync_dev_signing

```sh
[bundle exec] fastlane ios sync_dev_signing
```

Sync development certificates and provisioning profiles

### ios sync_prod_signing

```sh
[bundle exec] fastlane ios sync_prod_signing
```

Sync production certificates and provisioning profiles

### ios deploy_dev

```sh
[bundle exec] fastlane ios deploy_dev
```

Archive and upload development to TestFlight

### ios deploy_beta

```sh
[bundle exec] fastlane ios deploy_beta
```

Build and upload beta to TestFlight

### ios upload_ipa_only

```sh
[bundle exec] fastlane ios upload_ipa_only
```

Upload pre-built IPA to TestFlight

### ios upload_beta_ipa

```sh
[bundle exec] fastlane ios upload_beta_ipa
```

Upload pre-built IPA to TestFlight Beta Testing

### ios deploy_dev_debug

```sh
[bundle exec] fastlane ios deploy_dev_debug
```

Debug build using xcodebuild directly (alternative to gym)

### ios deploy_prod

```sh
[bundle exec] fastlane ios deploy_prod
```

Build and upload production to TestFlight/App Store

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
