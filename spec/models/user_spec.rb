require 'spec_helper'

describe User do
  context "model validation" do
    it "the factory test user should be valid" do
      expect { FactoryGirl.create(:user) }.to_not raise_error
    end

    it "should not allow duplicate emails (case insensitively)" do
      user = FactoryGirl.create(:user)
      expect { FactoryGirl.create(:user, email: user.email) }.to raise_error(/email.*already.*taken/i)
      expect { FactoryGirl.create(:user, email: user.email.upcase) }.to raise_error(/email.*already.*taken/i)
    end

    it "should have an encrypted password" do
      expect { FactoryGirl.create(:user, encrypted_password: "") }.to raise_error(/password.*blank/i)
    end

    it "should have a 32 character salt" do
      expect { FactoryGirl.create(:user, salt: "abc") }.to raise_error(/salt.*length/i)
    end

    it "should have an expiry date" do
      expect { FactoryGirl.create(:user, expires_on: nil) }.to raise_error(/expires.*blank/i)
    end

    it "should have a positive ICU ID" do
      expect { FactoryGirl.create(:user, icu_id: nil) }.to raise_error(/icu.*not.*number/i)
      expect { FactoryGirl.create(:user, icu_id: 0) }.to raise_error(/icu.*greater.*than.*0/i)
    end

    it "should have a valid set of roles" do
      expect { FactoryGirl.create(:user, roles: User::ROLES.join(" ")) }.to_not raise_error
      expect { FactoryGirl.create(:user, roles: User::ROLES.sample(2).join(" ")) }.to_not raise_error
      #expect { FactoryGirl.create(:user, roles: User::ROLES.sample) }.to_not raise_error
      expect { FactoryGirl.create(:user, roles: nil) }.to_not raise_error
      expect { FactoryGirl.create(:user, roles: "rubbish") }.to raise_error(/role.*invalid/i)
    end
  end

  context "#valid_password?" do
    it "default factory password should pass" do
      user = FactoryGirl.create(:user)
      expect(user.valid_password?("password")).to be_true
      expect(user.valid_password?("drowssap")).to be_false
    end

    it "random password should pass" do
      password = "password" + rand(1000).to_s
      salt = User.random_salt
      encrypted_password = User.encrypt_password(password, salt)
      user = FactoryGirl.create(:user, encrypted_password: encrypted_password, salt: salt)
      expect(user.valid_password?(password)).to be_true
      expect(user.valid_password?(password.upcase)).to be_false
    end
  end

  context "#authenticate!" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @addr = @user.email
      @pass = "password"
    end

    it "successful login" do
      expect(User.authenticate!(@addr, @pass)).to eql(@user)
    end

    it "invalid password" do
      expect { User.authenticate!(@addr, "bad") }.to raise_error("invalid_details")
    end

    it "unknown email" do
      expect { User.authenticate!("bad" + @addr, @pass) }.to raise_error("invalid_details")
    end

    it "subscription expired" do
      @user.expires_on = Date.yesterday
      @user.save
      expect { User.authenticate!(@addr, @pass) }.to raise_error("subscription_expired")
      expect { User.authenticate!(@addr, "bad") }.to raise_error("subscription_expired")
    end

    it "unverified email" do
      @user.verified_at = nil
      @user.save
      expect { User.authenticate!(@addr, @pass) }.to raise_error("unverified_email")
      expect { User.authenticate!(@addr, "bad") }.to raise_error("unverified_email")
    end

    it "bad status" do
      @user.status = "Banned"
      @user.save
      expect { User.authenticate!(@addr, @pass) }.to raise_error("account_disabled")
      expect { User.authenticate!(@addr, "bad") }.to raise_error("account_disabled")
    end
  end
end
