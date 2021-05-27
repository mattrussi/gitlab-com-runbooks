# frozen_string_literal: true

require 'spec_helper'

require_relative '../scripts/update_stage_error_budget_dashboards.rb'

describe UpdateStageErrorBudgetDashboards do
  describe '.render_template' do
    context 'when input stage key is empty' do
      it 'raises an exception' do
        expect do
          described_class.render_template(nil)
        end.to raise_error(/stage key is empty/i)
      end
    end

    context 'when input stage key is nil' do
      it 'raises an exception' do
        expect do
          described_class.render_template('')
        end.to raise_error(/stage key is empty/i)
      end
    end
  end

  describe '#call' do
    let(:dashboard_dir) { Dir.mktmpdir }
    let(:mapping_path) { "#{dashboard_dir}/stage-group-mapping.jsonnet" }
    let(:output) { StringIO.new }

    let(:groups_jsonnet) do
      file_fixture('stage-group-mapping-fixtures.jsonnet')
    end

    let(:operation) { described_class.new(dashboards_dir: dashboard_dir, mapping_path: mapping_path, output: output) }

    after do
      FileUtils.remove_entry dashboard_dir
    end

    context 'when the mapping file does not exist' do
      it 'raises an exception' do
        expect { operation.call }.to raise_error(/does not exist/i)
      end
    end

    context 'when the mapping file is invalid' do
      it 'raises an exception' do
        File.write(mapping_path, 'A junk file')
        expect { operation.call }.to raise_error(/fail to compile/i)
      end
    end

    context 'when the mapping file is valid' do
      let(:should_remove_file) { "#{dashboard_dir}/should-remove.error_budget.jsonnet" }

      let(:should_remove_file_2) { "#{dashboard_dir}/should-remove-2.error_budget.jsonnet" }
      let(:should_remove_content_2) { described_class.render_template('should-remove-2') + "\nThis template is customized" }

      let(:manage_file) { "#{dashboard_dir}/manage.error_budget.jsonnet" }
      let(:manage_template) { described_class.render_template('manage') }

      let(:comply_file) { "#{dashboard_dir}/comply.error_budget.jsonnet" }
      let(:comply_template) { described_class.render_template('comply') }

      let(:plan_file) { "#{dashboard_dir}/plan.error_budget.jsonnet" }
      let(:plan_template) { described_class.render_template('plan') }

      before do
        File.write(mapping_path, groups_jsonnet)

        File.write(should_remove_file, described_class.render_template('should-remove'))
        File.write(should_remove_file_2, should_remove_content_2)
        File.write(manage_file, manage_template)
        File.write(comply_file, comply_template)
      end

      it 'synchronizes groups into the dashboard dir' do
        operation.call

        expect(File.exist?(should_remove_file)).to eql(false)
        expect(File.exist?(should_remove_file_2)).to eql(false)

        expect(File.exist?(plan_file)).to eql(true)
        expect(File.read(plan_file)).to eql(plan_template)

        expect(File.exist?(comply_file)).to eql(true)
        expect(File.read(comply_file)).to eql(comply_template)

        expect(File.exist?(manage_file)).to eql(true)
        expect(File.read(manage_file)).to eql(manage_template)
      end
    end
  end
end
