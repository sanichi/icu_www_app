require 'rails_helper'

describe Failure do
  let(:name) { "MyFailure" }

  context "log" do
    before(:each) do
      Failure.log(name, details)
      @failure = Failure.first
    end

    context "string details" do
      let(:details) { "my details" }

      it "name and details" do
        expect(@failure.name).to eq name
        expect(@failure.details).to eq details
      end
    end

    context "hash details" do
      let(:details) { { key1: "val1", key2: "val2" } }

      it "name and details" do
        expect(@failure.name).to eq name
        expect(@failure.details).to eq "key1: val1\nkey2: val2"
      end
    end

    context "hash details with exception array" do
      let(:details) { { exception: ["Name1", "message1"], other: "more" } }

      it "name and details" do
        expect(@failure.name).to eq name
        expect(@failure.details).to eq "message: message1\nname: Name1\nother: more"
      end
    end

    context "hash details with exception exception" do
      let(:details) { { exception: RuntimeError.new("message2"), another: "extra" } }

      it "name and details" do
        expect(@failure.name).to eq name
        expect(@failure.details).to eq "another: extra\nmessage: message2\nname: RuntimeError"
      end
    end
  end
end
