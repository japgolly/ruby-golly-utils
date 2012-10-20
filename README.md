# Golly-Utils [![Build Status](https://secure.travis-ci.org/japgolly/golly-utils.png?branch=master)](http://travis-ci.org/japgolly/golly-utils)


`golly-utils` is a collection of Ruby utility code with specific focus or application other than
simply providing value when reused in multiple unrelated projects.

Features (highlights)
=====================

This is a subset of the available functionality. Browse the Yardoc or code for more.

Callbacks
---------

GollyUtils::Callbacks -- Simple event-and-listener style callbacks with a few bells-and-whistles.
```ruby
class Engine
  include GollyUtils::Callbacks
  define_callback :on_save
end

class HappyEngine < Engine
  on_save{ puts 'Saving!!'}
  on_save(priority: -1){ puts 'FIRST!' }
  on_save(priority:  1){ puts 'Last.' }
end

HappyEngine.new.run_callback :on_save     # => FIRST!
                                          # => Saving!!
                                          # => Last.
```

Declarative Attributes
----------------------

attr_declarative -- Declarative attributes that avoid typos in subclasses, have default values, and
more.
```ruby
class Plugin
  attr_declarative :name, :author
  attr_declarative version: 10
  attr_declarative :hobby, required: true
end

class BluePlugin < Plugin
  name 'The Blue Plugin'
end

p = BluePlugin.new
puts p.name              # => The Blue Plugin
puts p.author            # => nil
puts p.version           # => 10
puts p.hobby             # => RuntimeError: Attribute 'hobby' required by Plugin but not set in BluePlugin.
```

Ruby Extension
--------------

* `Object.deep_dup` with collection-aware implementations for Array and Hash.
* Array to Hash conversion

  ```ruby
  ['m','abc'].to_hash_keyed_by{ |v| v.length }   # => {1 => 'm', 3 => 'abc}
  [2,5].to_hash_with_values{ |k| 'xo' * k }      # => {2 => 'xoxo', 5 => 'xoxoxoxoxo'}
  ```
* Enumerable.frequency_map
  ```ruby
  %w[big house big car].frequency_map  # => {"big"=>2, "car"=>1, "house"=>1}
  ```
* `Kernel.at_exit_preserving_exit_status`
* Object.superclasses
  ```ruby
  Fixnum.superclasses  # <= [Fixnum, Integer, Numeric, Object, BasicObject]
  ```
* `StandardError.to_pretty_s`
* GollyUtils::EnvHelpers
  ```ruby
  ENV['debug'] = '1'     # can also be: y, yes, t, true, on, enabled
  ENV.on?('debug')       # <= true
  ENV.enabled?('debug')  # <= true
  ```
* GollyUtils::Singleton -- Extends Ruby's Singleton module.
  ```ruby
  class Stam1na
    include GollyUtils::Singleton
    def band_rating; puts 'AWESOME!!' end
  end

  # No need to call .instance all the time
  Stam1na.band_rating           #=> AWESOME!!
  Stam1na.instance.band_rating  #=> AWESOME!!

  # Provides a helper to define itself as an attribute in other classes
  # and use the singleton instance as the default.
  class ElseWhere
    Stam1na.def_accessor self
  end
  ```

Testing
-------

* RSpec Matchers
  ```ruby
  # Array testing
  %w[a a b].should     equal_array %w[a a b]
  %w[b a b].should_not equal_array %w[a a b]
  %w[a b c d e f g h].should equal_array %w[B C d e f g h]
      # Failure/Error: expected that arrays would match.
      #   Missing elements: ["B", "C"]
      #   Unexpected elements: ["a", "b", "c"]

  # File system testing
  'lib'       .should     exist_as_a_dir
  'Gemfile'   .should_not exist_as_a_file
  '/tmp/stuff'.should     exist_as_a_file
      # Failure/Error: expected that '/tmp/stuff' would be an existing file.
      #   Files found in /tmp: .X0-lock  .s.PGSQL.5432.lock  .xfsm-ICE-TVOQMW


  # File content testing
  'version.txt'.should be_file_with_contents "2\n"
  'Gemfile'    .should be_file_with_contents(/['"]rspec['"]/).and(/['"]golly-utils['"]/)
  'Gemfile'    .should be_file_with_contents(/gemspec/).and_not(/rubygems/)
  'version.txt'.should be_file_with_contents("2").when_normalised_with(&:chomp)
  'stuff.txt'  .should be_file_with_contents(/ABC/)
                         .and(/DEF/)
                         .and(/123\n/)
                         .when_normalised_with(&:upcase)
                         .and(&:chomp)
  ```

* Testing in clean-slate, empty directories
  ```ruby
  # Test some code from an empty temp directory
  def test_stuff
    inside_empty_dir {
      puts Dir.pwd      # => /tmp/abcdef123567
    }
  end

  # RSpec declarations
  describe 'Demo' do
    run_each_in_empty_dir   # Each test/example will be run in its own empty temp dir
    run_all_in_empty_dir    # Each test/example will be run in the same empty temp dir
  end
  ```

* Polling
  ```ruby
  within(5).seconds{ 'Gemfile'.should exist_as_a_file }
  ```

* Dynamic Fixtures
  ```ruby
  # Provides globally-shared, cached, lazily-loaded fixtures that are generated once on-demand,
  # and copied when access is required.
  describe 'My Git Utility' do
    include GollyUtils::Testing::DynamicFixtures

    def_fixture :git do                             # Dynamic fixture definition.
      system 'git init'                             # Expensive to create.
      File.write 'test.txt', 'hello'                # Only runs once.
      system 'git add -A && git commit -m x'
    end

    run_each_in_dynamic_fixture :git                # RSpec helper for fixture usage.

    it("detects deleted files") {                   # Runs in a copy of the fixture.
      File.delete 'test.txt'                        # Free to modify its fixture copy.
      subject.deleted_files.should == %w[test.txt]  # Other tests isolated from these these changes.
    }

    it("detects new files") {                       # Runs in a clean copy of the fixture.
      File.create 'new.txt'                         # Generated quickly by copying cache.
      subject.new_files.should == %w[new.txt]       # Unaffected by other tests' fixture modification.
    }

  end
  ```

Validation
----------

* Object.validate_type!
  ```ruby
  3     .validate_type nil, Numeric
  nil   .validate_type nil, Numeric
  'What'.validate_type nil, Numeric # <= raises TypeValidationError
  tracer.validate_type! 'the tracer flag', true, false  # Validate boolean with nice err msg
  ```
* Symbol.validate_lvar_type! -- Validates local variables without you having to specify the variable
  value or name in error messages.
  ```ruby
  def save_person(name, eyes)
    :name.validate_lvar_type!{ String }
    :eyes.validate_lvar_type!{ [nil,Fixnum] }
  ```
* `Hash.validate_keys`
* `Hash.validate_option_keys`


&nbsp;

&nbsp;

----

Legal
=====

Copyright &copy; 2012 David Barri.

This program is licenced under the LGPL (Lesser General Public License).
For details see `LICENCE-LGPL.txt` or <http://www.gnu.org/licenses/lgpl-3.0.txt>.


    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

