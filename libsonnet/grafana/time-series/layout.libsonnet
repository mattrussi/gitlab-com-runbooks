local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local row = g.panel.row;

local row(
  title,
  collapse=false,
      ) =
  row.new(title) +
  row.withCollapsed(collapse) +
  {
    addPanels(panels)::
      self +
      row.withPanelsMixin(panels),
  };

{
  row: row,
}
