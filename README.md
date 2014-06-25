# once-ler

once-ler supercharges your `let`s and `before`s with the performance
of `before(:all)`.

## Basic usage

### before(:once) { ... }

Change a slow `before` to `before(:once)`

### let_once(...) { ... }

Change a slow `let` (or `let!`) to `let_once`

## Ambitious usage

Automatically speed up all `let`s/`before`s in an example group:

    describe "something" do
      onceler!
      ...
    end

Or even more ambitiously, apply it to all your specs:

    RSpec.configure do |c|
      c.onceler!
    end

## How does it work?

Any `before(:once)`/`let_once` blocks will run just once for the current
context/describe block, before any of its examples run. Any side effects
(ivars) and return values will be recorded and replayed before each spec
in the block runs. Database statements are replayed/rolled back via
nested transactions (savepoints).

This can give you a dramatic speedup, since you can minimize the number
of activerecord callbacks/inserts/updates.

## Caveats

* You need to use transactional fixtures.
* Your once'd blocks should have no side effects other than database
  statements, return variables, and instance variables.
* Your once'd blocks' behavior should not depend on side effects of other
  non-once'd blocks. For example:
  * a `before(:once)` block should not reference instance variables set by a
    `before`.
  * a `let_once` block should not call non-once'd `let`s or `subject`s.
* Because all once'd blocks will be recorded (even if not all used in an
  example), you should ensure they don't conflict with each other (e.g.
  unique constraint violations).
