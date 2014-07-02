# once-ler

once-ler supercharges your `let`s and `before`s with the performance
of `before(:all)`. You get the performance of fixtures without all the
headaches.

## Setup

Add it to your Gemfile

```ruby
gem "once-ler"
```

And then in spec_helper.rb (or wherever):

```ruby
RSpec.configure do |config|
  config.include Onceler::BasicHelpers
end
```

## Basic usage

### before(:once) { ... }

Change a slow `before` to `before(:once)` to speed it up.

### let_once(...) { ... }

Change a slow `let` (or `let!`) to `let_once` to speed it up.

### subject_once(...) { ... }

Change a slow `subject` (or `subject!`) to `subject_once` to speed it up.

## Ambitious usage

If you're feeling bold, you can automatically speed up all
`let`s/`before`s in an example group:

```ruby
describe "something" do
  onceler!

  let(:foo) { ... }      # behaves like let_once
  before { ... }         # behaves like before(:once)

  # but if you need explict eaches, you can still do them:
  let_each(:foo) { ... }
  before(:each) { ... }
end
```

## How much of a speedup will I get?

YMMV, it depends on how bad your `let`s/`before`s are. For example,
adding once-ler to a subset of [canvas-lms](https://github.com/instructure/canvas-lms)'s
model specs (spec/models/a*) **reduces their runtime by 40%**.

## How does it work?

Any `before(:once)`/`let_once` blocks will run just once for the current
context/describe block, before any of its examples run. Any side effects
(ivars) and return values will be recorded, and will then be reapplied
before each spec in the block runs. Once-ler uses nested transactions
(savepoints) to ensure that specs don't mess with each other's database
rows.

This can give you a dramatic speedup, since you can minimize the number
of activerecord callbacks/inserts/updates.

## Caveats

* If you are doing anything database-y, you need to use transactional
  tests (either via `use_transactional_fixtures=true`, or something like
  [database_cleaner](https://github.com/DatabaseCleaner/database_cleaner))
* Your once'd blocks should have no side effects other than database
  statements, return values, and instance variables.
* Your return values and instance variables:
  1. need to be able to handle a `Marshal.dump`/`load` round trip.
  1. should implement `#==` and `#hash`. for built-ins types (e.g. String)
     or models, this isn't a problem, but if it's a custom class you might
     need to add them.
* Your once'd blocks' behavior should not depend on side effects of other
  non-once'd blocks. For example:
  * a `before(:once)` block should not reference instance variables set by a
    `before` (but the inverse is fine).
  * a `let_once` block should not call non-once'd `let`s or `subject`s.
* Because all `let_once`s will be recorded and replayed (even if not used
  in a particular example), you should ensure they don't conflict with
  each other (e.g. unique constraint violations, or one `let_once`
  mutating the return value of another).
