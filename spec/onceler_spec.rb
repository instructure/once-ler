require "onceler"
require "database_cleaner"
require "active_record/connection_adapters/sqlite3_adapter"
ActiveRecord::Base.establish_connection(database: ":memory:", adapter: "sqlite3")

class User < ActiveRecord::Base; end

User.connection.create_table :users do |t|
  t.string :name
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

shared_examples_for ".let_once" do |let_method = :let_once|
  user_create_calls = 0

  send let_method, :user do
    user_create_calls += 1
    User.create(name: "bob")
  end

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

  context "with nesting" do
    it "should work" do
      expect(user.name).to eql("bob")
    end
  end

  context "with overrides" do
    send let_method, :user do
      User.create(name: "billy")
    end

    it "should override inherited let_onces" do
      expect(user.name).to eql("billy")
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
  end

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
      @user = User.create(name: "mary")
    end

    it "should override results of inherited before(:once)s" do
      expect(@user.name).to eql("mary")
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

  describe ".before(:once)" do
    it_behaves_like ".before(:once)"
    include_context "user cleanup"
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

  context "identity" do
    let_once(:user) { User.new }
    before { @user = @user2 = user }

    it "should generally be preserved" do
      expect(user).to equal(@user)
      expect(@user).to equal(@user2)
    end
  end

  after(:all) do
    # yay cleaned up
    expect(User.count).to eql(0)
  end
end
