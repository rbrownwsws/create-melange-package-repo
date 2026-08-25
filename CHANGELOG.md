# Changelog

## 1.0.0 (2026-08-25)


### ⚠ BREAKING CHANGES

* include .apk in attest bundle filenames
* create own directory to output repo instead of asking for one as input

### Features

* alert what key is used to sign index ([345667a](https://github.com/rbrownwsws/create-melange-package-repo/commit/345667af01b7b9e02bd8fc97fa6ae677d19fc151))
* create own directory to output repo instead of asking for one as input ([4cd703d](https://github.com/rbrownwsws/create-melange-package-repo/commit/4cd703d1327399f8ac099cb4493b0ccecd59ffc8))
* include .apk in attest bundle filenames ([9a968c8](https://github.com/rbrownwsws/create-melange-package-repo/commit/9a968c859109a9fd8a08ff115f32a51eb3494c22))
* include signed attestation bundles in repo ([a168b22](https://github.com/rbrownwsws/create-melange-package-repo/commit/a168b22fdfafd1fd34bd037f670f03a6475d10e4))


### Bug Fixes

* actually download attestations instead of downloading packages again ([1091984](https://github.com/rbrownwsws/create-melange-package-repo/commit/1091984cbc1f90ea23d8e11f05a0602963e6211b))
* actually include .apk in attest bundle filenames ([2b7cedc](https://github.com/rbrownwsws/create-melange-package-repo/commit/2b7cedcffc83eb7a6f624377292961d27776f555))
* don't mangle signing key name as verification relies on it ([589957f](https://github.com/rbrownwsws/create-melange-package-repo/commit/589957f140564d80521515e25133b294c237f004))


### Continuous Integration

* add reusable workflows for zizmor and release-please ([d3ff499](https://github.com/rbrownwsws/create-melange-package-repo/commit/d3ff4990d8554eda6f164085e58c7a8cc67d469a))
