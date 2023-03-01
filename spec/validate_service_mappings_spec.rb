# frozen_string_literal: true
require 'spec_helper'

require_relative '../scripts/validate-service-mappings'

describe ValidateServiceMappings do
  subject(:validator) { described_class.new(raw_catalog_path).validate }

  let(:tmp_dir) { Dir.mktmpdir }
  let(:raw_catalog_path) { "#{tmp_dir}/raw-catalog.jsonnet" }

  before do
    File.write(raw_catalog_path, raw_catalog_jsonnet)
  end

  after do
    FileUtils.remove_entry tmp_dir
  end

  describe "validating service labels" do
    let(:base_catalog) do
      <<-JSONNET
        {
          "teams": [
            {
              "name": "sre_reliability"
            }
          ],
          "tiers": [
            {
              "name": "sv"
            }
          ]
        }
      JSONNET
    end

    where(:services_jsonnet, :error_msg) do
      [
        [<<~JSONNET, nil],
        {
          "services": [
            {
              "name" : "Foo",
              "tier": "sv",
              "friendly_name": "mr_foo",
              "label": "Foo"
            },
            {
              "name" : "Bar",
              "tier": "sv",
              "friendly_name": "mr_bar",
              "label": "Bar"
            }
          ]
        }
        JSONNET

        # empty label case
        [<<~JSONNET, "'Foo' | label field must be string"],
        {
          "services": [
            {
              "name" : "Foo",
              "tier": "sv",
              "friendly_name": "mr_foo"
            }
          ]
        }
        JSONNET

        # label is an integer
        [<<~JSONNET, "'Foo' | label field must be string"],
        {
          "services": [
            {
              "name" : "Foo",
              "tier": "sv",
              "friendly_name": "mr_foo",
              "label": 123
            }
          ]
        }
        JSONNET

        # Label not unique (same case)
        [<<~JSONNET, "'Foo' | duplicated labels found in service catalog. Label field must be unique (case insensitive)"],
        {
          "services": [
            {
              "name" : "Foo",
              "tier": "sv",
              "friendly_name": "mr_foo",
              "label": "Foo"
            },
            {
              "name" : "Bar",
              "tier": "sv",
              "friendly_name": "mr_bar",
              "label": "Foo"
            }
          ]
        }
        JSONNET

        # Label not unique (different case)
        [<<~JSONNET, "'foO' | duplicated labels found in service catalog. Label field must be unique (case insensitive)"]
        {
          "services": [
            {
              "name" : "Foo",
              "tier": "sv",
              "friendly_name": "mr_foo",
              "label": "Foo"
            },
            {
              "name" : "Bar",
              "tier": "sv",
              "friendly_name": "mr_bar",
              "label": "foO"
            }
          ]
        }
        JSONNET
      ]
    end

    with_them do
      let(:raw_catalog_jsonnet) { JSON.dump(JSON.parse(base_catalog).merge(JSON.parse(services_jsonnet))) }

      it "validates whether success or raise an error" do
        if error_msg.nil?
          expect { validator }.not_to raise_error
        else
          expect { validator }.to raise_error(error_msg)
        end
      end
    end
  end
end
