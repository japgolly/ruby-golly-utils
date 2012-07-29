Golly's Utils: Changelog
========================

## 0.1.0 (WIP)

WIP

#### Added
* Added new {GollyUtils::Delegator} option: `:allow_protected`
* Added test helpers:
    * `get_files`
    * `inside_empty_dir`
* Added RSpec helpers:
  * `run_all_in_empty_dir`
  * `run_each_in_empty_dir`
  * `exist_as_a_dir`
  * `exist_as_a_file`

#### Modified
* Renamed dir: `golly-utils/test` => `golly-utils/testing`.
* Renamed dir: `golly-utils/test/spec` => `golly-utils/testing/rpsec`.
* Renamed module: `GollyUtils::TestHelpers` => `GollyUtils::Testing::Helpers`
* Renamed module: `GollyUtils::DeferrableSpecs` => `GollyUtils::Testing::DeferrableSpecs`

#### Removed
* Removed `attr_declarative` (experiment that didn't prove useful).

## 0.0.1 (2012-07-16)

Initial version.
