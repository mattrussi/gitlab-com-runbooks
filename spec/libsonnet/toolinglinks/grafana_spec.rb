require 'spec_helper'

describe 'libsonnet/toolinglinks/grafana.libsonnet' do
  describe '#grafanaUid' do
    using RSpec::Parameterized::TableSyntax

    context 'input path is at the root directory' do
      it 'raises an error' do
        result = JsonnetTestHelper.render(
          <<~JSONNET
            local grafana = import 'toolinglinks/grafana.libsonnet';

            grafana.grafanaUid("bare-file.jsonnet")
          JSONNET
        )
        expect(result.success?).to be(false)
        expect(result.error_message).to match(/invalid dashboard path/i)
      end
    end

    context 'input file is too deep' do
      it 'raises an error' do
        result = JsonnetTestHelper.render(
          <<~JSONNET
            local grafana = import 'toolinglinks/grafana.libsonnet';

            grafana.grafanaUid("folder1/folder2/bare-file.jsonnet")
          JSONNET
        )
        expect(result.success?).to be(false)
        expect(result.error_message).to match(/invalid dashboard path/i)
      end
    end

    context 'valid paths' do
      where(:path, :uid) do
        'product/plan.jsonnet' | 'product-plan'
        'product/plan.error_budget.jsonnet' | 'product-plan'
        'product/plan-error-budget.jsonnet' | 'product-plan-error-budget'
        'stage-groups/access.dashboard.jsonnet' | 'stage-groups-access'
        'stage-groups/code_review.dashboard.jsonnet' | 'stage-groups-code_review'
      end

      with_them do
        it 'returns legitimate UIDs' do
          result = JsonnetTestHelper.render(
            <<~JSONNET
              local grafana = import 'toolinglinks/grafana.libsonnet';

              grafana.grafanaUid("#{path}")
            JSONNET
          )
          expect(result.success?).to be(true)
          expect(result.data).to eql(uid)
        end
      end
    end
  end
end
