Golly's Utils: Changelog
========================

## 0.1.0 (WIP)

WIP

#### Added
* Added {GollyUtils::Testing::DynamicFixtures}.
* Added {Hash#validate_keys} and {Hash#validate_option_keys}.
* Added {Kernel#at_exit_preserving_exit_status}.
* {GollyUtils::Singleton Singleton} module.
* Added new {GollyUtils::Delegator Delegator} option: `:allow_protected`
* {GollyUtils::Callbacks Callbacks} can now be defined in modules.
* Added {GollyUtils::Callbacks::ClassMethods#callbacks} and {GollyUtils::Callbacks::ModuleMethods#callbacks} to provide a list of all defined and inherited callbacks.
* {GollyUtils::Callbacks::InstanceMethods#run_callbacks Callbacks#run_callbacks} now accepts options which currently allows for callback arguments to be specified.
* {GollyUtils::Callbacks::InstanceMethods#run_callback Callbacks#run_callback} and {GollyUtils::Callbacks::InstanceMethods#run_callbacks Callbacks#run_callbacks}
  now accept an option to pass arguments to callback functions.
* {GollyUtils::Callbacks::InstanceMethods#run_callback Callbacks#run_callback} and {GollyUtils::Callbacks::InstanceMethods#run_callbacks Callbacks#run_callbacks}
  now accept an option to provide a context for callback function execution.
* Added Ruby extensions:
  * {Enumerable#frequency_map}
* Added test helpers:
  * {GollyUtils::Testing::Helpers#get_dirs get_dirs}
  * {GollyUtils::Testing::Helpers#get_files get_files}
  * {GollyUtils::Testing::Helpers#get_dir_entries get_dir_entries}
  * {GollyUtils::Testing::Helpers#inside_empty_dir inside_empty_dir}
  * {GollyUtils::Testing::Helpers#in_tmp_dir? in_tmp_dir?}
  * {GollyUtils::Testing::Helpers#step_out_of_tmp_dir step_out_of_tmp_dir}
* Added RSpec helpers:
  * {GollyUtils::Testing::Helpers::ClassMethods#run_all_in_empty_dir run_all_in_empty_dir}
  * {GollyUtils::Testing::Helpers::ClassMethods#run_each_in_empty_dir run_each_in_empty_dir}
  * {GollyUtils::Testing::Helpers::ClassMethods#run_each_in_empty_dir_unless_in_one_already run_each_in_empty_dir_unless_in_one_already}
  * {GollyUtils::Testing::RSpecMatchers#be_file_with_contents be_file_with_contents}
  * {GollyUtils::Testing::RSpecMatchers#exist_as_a_dir exist_as_a_dir}
  * {GollyUtils::Testing::RSpecMatchers#exist_as_a_file exist_as_a_file}
  * {GollyUtils::Testing::RSpecMatchers#equal_array equal_array}

#### Modified
* Finished the experiment that was {GollyUtils::AttrDeclarative}. No mucking around with blocks, eager/lazy evaluation anymore; now it's all values.
* {GollyUtils::Delegator#respond_to? Delegator#respond_to?} now also indicates `true` for local methods (in addition to delegatable).
* {GollyUtils::Callbacks::InstanceMethods#run_callback Callbacks#run_callback} now only runs a single callback.
* Renamed dir: `golly-utils/test` => `golly-utils/testing`.
* Renamed dir: `golly-utils/test/spec` => `golly-utils/testing/rpsec`.
* Renamed module: `GollyUtils::TestHelpers` => `GollyUtils::Testing::Helpers`
* Renamed module: `GollyUtils::DeferrableSpecs` => `GollyUtils::Testing::DeferrableSpecs`

## 0.0.1 (2012-07-16)

Initial version.
