require "database_cleaner"
require "onceler"
require "active_record/connection_adapters/sqlite3_adapter"
# Minimal set of requires to get FixtureSupport
require "rspec/rails/adapters"
require "rspec/rails/fixture_support"
ActiveRecord::Base.establish_connection(database: ":memory:", adapter: "sqlite3")

class User < ActiveRecord::Base
  belongs_to :group
end

class Group < ActiveRecord::Base
  has_many :users
end

User.connection.create_table :users do |t|
  t.string :name
  t.integer :group_id
end

User.connection.create_table :groups do |t|
  t.string :name
end

RSpec.configure do |config|
  # Adapted from rspec/rails/configuration to be the minimal set
  config.add_setting :use_active_record, default: true
  config.add_setting :use_transactional_fixtures
  config.add_setting :use_instantiated_fixtures
  config.add_setting :global_fixtures
  config.add_setting :fixture_path
  config.include RSpec::Rails::FixtureSupport

  config.use_transactional_fixtures = true

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

Onceler.configure do |config|
  config.before(:record) do
    @global_before_ran = true
  end

  config.after(:record) do
    @global_after_ran = true
  end
end

shared_examples_for ".let_once" do |let_method = :let_once|
  user_create_calls = 0

  send let_method, :user do
    user_create_calls += 1
    User.create(name: "bob")
  end

  send(let_method, :things){ [1] }

  let_each(:num){ 1 }

  it "should be memoized within a spec" do
    user.update_attribute(:name, "joe")
    expect(user.name).to eql("joe")
  end

  it "should give each spec a blank slate" do
    expect(user.name).to eql("bob")
  end

  context "calling instance methods" do
    send let_method, :call_my_method do
      my_method
    end

    def my_method
      @my_method_called = true
    end

    it "should work" do
      expect(@my_method_called).to eql(true)
    end
  end

  context "inheritance" do
    send(let_method, :name){ "Bob" }
    context "through" do
      send(let_method, :bar){ "bar" }
      context "contexts" do
        before :once do
          # lookups here work differently than in examples, so it's good to test both
          expect(name).to eql("Bob")
        end
        it "works" do
          expect(name).to eql("Bob")
        end
      end
    end
  end

  context "with nesting" do
    it "should work" do
      expect(user.name).to eql("bob")
    end
  end

  context "with overrides" do
    send let_method, :user do
      User.create(name: "billy")
    end

    send(let_method, :mutated_things) { things << 2 }

    send(let_method, :num){ 2 }

    it "should override inherited let_onces" do
      expect(user.name).to eql("billy")
    end

    it "should preserve mutated inherited let_eaches" do
      expect(things).to eql mutated_things
    end

    it "should override inherited let_eaches" do
      expect(num).to eql 2
    end

    it "should not prevent inherited let_onces from running" do
      expect(User.where(name: "bob")).to be_present
    end
  end

  after(:all) do
    expect(user_create_calls).to eql(1)
  end
end

shared_examples_for ".before(:once)" do |scope = :once|
  user_create_calls = 0

  before(scope) do
    user_create_calls += 1
    @user = User.create(name: "sally")
    @user2 = User.create(name: "melissa")
    @group = Group.new(name: "red")
    @user3 = User.create(name: "jessica", group: @group)
    @user4 = User.create(name: "dawn", group: @group)
  end

  before(:each) { @num = 1 }

  it "should set instance variables" do
    @user.update_attribute(:name, "jane")
    expect(@user).to be_present
    expect(@user).to eql(User.first)
  end

  it "should give each spec a blank slate" do
    expect(@user.name).to eql("sally")
  end

  context "calling instance methods" do
    before(scope) do
      my_method
    end

    def my_method
      @my_method_called = true
    end

    it "should work" do
      expect(@my_method_called).to eql(true)
    end
  end

  context "with nesting" do
    it "should work" do
      expect(@user).to be_present
    end
  end

  context "with overrides" do
    before(scope) do
      # there are many ways we might mutate things...
      @user = User.create(name: "mary")
      @user2.update_attribute(:name, "michelle")
      @user3.group.update_attribute(:name, "blue")
      expect(@user4.instance_variable_get(:@association_cache).size).to eql(1)
      @user4.reload
    end

    before(scope) { @num = 2 }

    it "should override results of inherited before(:once)s" do
      expect(@user.name).to eql("mary")
      expect(@user2.name).to eql("michelle")
      expect(@user3.group.name).to eql("blue")
      expect(@user4.instance_variable_get(:@association_cache).size).to eql(0)
    end

    it "should override results of inherited before(:each)s" do
      expect(@num).to eql 2
    end

    it "should not prevent inherited before(:once)s from running" do
      expect(User.where(name: "sally")).to be_present
    end
  end

  after(:all) do
    expect(user_create_calls).to eql(1)
  end
end

shared_context "user cleanup" do
  after(:all) { expect(User.count).to eql(0) }
end

describe Onceler do
  include Onceler::BasicHelpers

  describe ".let_once" do
    it_behaves_like ".let_once"
    include_context "user cleanup"
  end

  describe ".around(:once)" do
    # don't use an ivar, they're not shared between arounds and examples
    x = 0
    around(:once) do |block|
      expect(x).to eq 0
      x += 1
      block.call
      # 2 not 3 because the block is JUST the before(:once) block
      expect(x).to eq 2
    end

    before(:once) do
      expect(x).to eq 1
      x += 1
    end

    it "runs" do
      expect(x).to eq 2
      x += 1
    end
  end

  describe ".around(:once) nested" do
    x = 0
    block_called = false

    # around(:once) called, x: 0 -> 1
    # no before(:once) at this level
    # around(:once) called, x: 1 -> 2
    #   before(:once) called, x: 2 -> 3
    # example called, x: 3 -> 4
    around(:once) do |block|
      expect(x).to eq (block_called ? 1 : 0)
      x += 1
      block.call
      expect(x).to eq (block_called ? 3 : 1)
      block_called = true
    end

    context "in nested block" do
      before(:once) do
        expect(x).to eq 2
        x += 1
      end

      it "runs" do
        expect(x).to eq 3
        x += 1
      end
    end
  end

  describe ".around(:once_and_each)" do
    x = 0

    around(:once_and_each) do |block|
      x += 1
      block.call
    end

    # only runs once, first
    before(:once) do
      expect(x).to eq 1
    end

    first_example_ran = false

    # runs before each of the two examples
    before(:each) do
      if first_example_ran
        expect(x).to eq 3
      else
        expect(x).to eq 2
      end
    end

    it "runs example 1" do
      if first_example_ran
        expect(x).to eq 3
      else
        first_example_ran = true
        expect(x).to eq 2
      end
    end

    it "runs example 2" do
      if first_example_ran
        expect(x).to eq 3
      else
        first_example_ran = true
        expect(x).to eq 2
      end
    end

    # before(:once) + before(:each) + before(:each)
    after(:all) do
      expect(x).to eq 3
    end
  end

  describe ".before(:once)" do
    it_behaves_like ".before(:once)"
    include_context "user cleanup"
  end

  describe ".before(:record)" do
    context "without recording" do
      before(:record) { @ran = true }
      it "never runs" do
        expect(@ran).to be_nil
      end
    end

    context "with recording" do
      before(:record) do
        @ran = true
        @global_before_already_ran = @global_before_ran
      end

      before(:once) { }

      it "runs" do
        expect(@ran).to be true
      end

      it "runs after the global hook" do
        expect(@global_before_already_ran).to be true
      end
    end

    context "in a parent group" do
      before(:record) { @ran = true }
      context "with recording" do
        before(:once) { }
        it "runs" do
          expect(@ran).to be true
        end
      end
    end
  end

  describe ".after(:record)" do
    context "without recording" do
      after(:record) { @ran = true }
      it "never runs" do
        expect(@ran).to be_nil
      end
    end

    context "with recording" do
      after(:record) do
        @run_counts ||= 0
        @run_counts += 1
        @global_after_ran_early = @global_after_ran
        @recording_already_ran = @recorded
      end

      before(:once) { @recorded = true }

      it "runs" do
        expect(@run_counts).to eq 1
      end

      it "runs after recording" do
        expect(@recording_already_ran).to be true
        expect(@recorded).to be true
      end

      it "runs before the global hook" do
        expect(@global_after_ran_early).not_to be
        expect(@global_after_ran).to be true
      end

      context "at multiple levels" do
        before(:once) { }

        it "runs at each level" do
          expect(@run_counts).to eq 2
        end
      end
    end

    context "in a parent group" do
      after(:record) do
        @ran = true
        @recording_already_ran = @recorded
      end

      context "with recording" do
        before(:once) { @recorded = true }

        it "runs" do
          expect(@ran).to be true
        end

        it "runs after recording" do
          expect(@recording_already_ran).to be true
        end
      end
    end
  end

  context "with onceler!" do
    onceler!

    describe ".let" do
      it_behaves_like ".let_once", :let
      include_context "user cleanup"
    end

    describe ".let_each" do
      count = 0
      let_each(:foo) { count += 1 }
      it("should behave like let") { foo }
      it("should behave like let (2)") { foo }

      after(:all) { expect(count).to eql(2) }
    end

    describe ".before(nil)" do
      it_behaves_like ".before(:once)", nil
      include_context "user cleanup"
    end
  end

  context "object identity" do
    let_once(:group) { Group.create }
    let_once(:user) { User.create(group: group) }
    let_once(:users) { [user] }
    before { @user = @user2 = user }

    it "should be preserved" do
      expect(user).to equal(@user)
      expect(@user).to equal(@user2)
      expect(user.group).to equal(group)
      expect(users.first).to equal(user)
    end
  end

  describe "error messages" do
    include Onceler::Recordable

    SomeObject = Class.new

    def dump(bad_var)
      find_dump_error :bad_var, bad_var
    end

    it "should help you find problematic instance variables" do
      bad_var = SomeObject.new
      bad_var.instance_variable_set(:@danger, Class.new)
      expect { dump bad_var }.to raise_error(/Unable to dump bad_var \(#<SomeObject>\) => @danger \(#<Class>\)/)
    end

    it "should include the original TypeError text" do
      bad_var = SomeObject.new
      bad_var.instance_variable_set(:@danger, Class.new)
      expect { dump bad_var }.to raise_error(/can't dump anonymous class/)
    end

    it "should help you find problematic array elements" do
      bad_var = [1, Class.new]
      expect { dump bad_var }.to raise_error(/Unable to dump bad_var \(#<Array>\) => \[1\] \(#<Class>\)/)
    end

    it "should help you find problematic hash keys" do
      bad_var = { Class.new => 1 }
      expect { dump bad_var }.to raise_error(/Unable to dump bad_var \(#<Hash>\) => hash key .* \(#<Class>\)/)
    end

    it "should help you find problematic hash values" do
      bad_var = { k: Class.new }
      expect { dump bad_var }.to raise_error(/Unable to dump bad_var \(#<Hash>\) => \[:k\] \(#<Class>\)/)
    end

    it "should handle objects with custom marshaling" do
      # it should complain about b, not a
      CustomMarshaling = Struct.new(:a, :b) do
        def marshal_dump
          [ b ]
        end
      end
      nested = SomeObject.new
      nested.instance_variable_set(:@danger, Class.new)
      bad_var = CustomMarshaling.new(Class.new, nested)
      expect { dump bad_var }.to raise_error(/Unable to dump bad_var \(#<CustomMarshaling>\) => marshal_dump \(#<Array>\) => \[0\] \(#<SomeObject>\) => @danger \(#<Class>\)/)
    end

    it "should recurse until it finds the problem" do
      bad_var = ('a'..'e').to_a.reverse.inject(Class.new) do |var, name|
        outer = SomeObject.new
        outer.instance_variable_set("@#{name}", var)
        outer
      end
      expect { dump bad_var }.to raise_error(/Unable to dump bad_var \(#<SomeObject>\) => @a \(#<SomeObject>\) => @b \(#<SomeObject>\) => @c \(#<SomeObject>\) => @d \(#<SomeObject>\) => @e \(#<Class>\)/)
    end

    it "should detect cycles" do
      s = SomeObject.new
      s.instance_variable_set(:@danger, Class.new)
      bad_var = [s]
      bad_var.unshift(bad_var)
      expect { dump bad_var }.to raise_error(/Unable to dump bad_var \(#<Array>\) => \[1\] \(#<SomeObject>\) => @danger \(#<Class>\)/)
    end
  end

  after(:all) do
    # yay cleaned up
    expect(User.count).to eql(0)
  end
end
