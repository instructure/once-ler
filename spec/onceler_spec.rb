require "onceler"
require "active_record/connection_adapters/sqlite3_adapter"
ActiveRecord::Base.establish_connection(database: ":memory:", adapter: "sqlite3")

class User < ActiveRecord::Base; end

User.connection.create_table :users do |t|
  t.string :name
end

describe Onceler do
  include Onceler::BasicHelpers
  describe ".let_once" do
    user_create_count = 0

    let_once(:user) {
      user_create_count += 1
      User.create(name: "bob")
    }

    it "should be memoized within a spec" do
      user.update_attribute(:name, "joe")
      expect(user.name).to eql("joe")
    end

    it "should give each spec a blank slate" do
      expect(user.name).to eql("bob")
    end

    context "with nesting" do
      it "should work" do
        expect(user.name).to eql("bob")
      end
    end

    context "with overrides" do
      let_once(:user) {
        User.create(name: "billy")
      }

      it "should override inherited lets" do
        expect(User.count).to eql(2)
        expect(user.name).to eql("billy")
      end
    end

    after(:all) do
      expect(user_create_count).to eql(1)
      expect(User.count).to eql(1)
    end
  end

  describe ".before(:once)" do
    user_create_count = 0

    before(:once) {
      user_create_count += 1
      @user = User.create(name: "sally")
    }

    it "should set instance variables" do
      @user.update_attribute(:name, "jane")
      expect(@user).to be_present
      expect(@user).to eql(User.first)
    end

    it "should give each spec a blank slate" do
      expect(@user.name).to eql("sally")
    end

    context "with nesting" do
      it "should work" do
        expect(@user).to be_present
        expect(@user).to eql(User.first)
      end
    end

    context "with overrides" do
      before(:once) {
        @user = User.create(name: "mary")
      }

      it "should override inherited lets" do
        expect(User.count).to eql(2)
        expect(@user.name).to eql("mary")
      end
    end

    after(:all) do
      expect(user_create_count).to eql(1)
      expect(User.count).to eql(1)
    end
  end

  after(:all) do
    # yay cleaned up
    expect(User.count).to eql(0)
  end
end
