require "rails_helper"

class FakesController < ApplicationController
  include ParameterConverters
end

RSpec.describe FakesController do
  RSpec.shared_examples "corrects nested params" do |input, output|
    it "converts #{input} to #{output}" do
      expect(subject.repair_nested_params(input)).to eq(output)
    end
  end

  RSpec.shared_examples "converts params" do |input, output|
    it "converts #{input} to #{output}" do
      expect(subject.convert_params(input)).to eq(output)
    end
  end

  it_behaves_like "converts params", { "foo" => "" }, { "foo" => nil }
  it_behaves_like "converts params", [{ "foo" => "" }], [{ "foo" => nil }]
  it_behaves_like "converts params", [{ "foo" => [{ "bar" => "" }] }], [{ "foo" => [{ "bar" => nil }] }]
  it_behaves_like "corrects nested params",
    {
      "person" => {
        "dogs_attributes" => {
          "0" => {
            "name" => "Fido"
          },
          "1" => {
            "name" => "Rocket"
          }
        }
      }
    },
    {
      "person" => {
        "dogs_attributes" => [
          {
            "name" => "Fido"
          },
          {
            "name" => "Rocket"
          }
        ]
      }
    }
end
