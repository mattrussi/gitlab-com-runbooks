local g = import 'grafonnet-dashboarding/grafana/g.libsonnet';

{
  forPanel(p):: {
    local standardOptions = p.standardOptions,
    local override = standardOptions.override,
    local custom = p.fieldConfig.defaults.custom,

    fromOptions(options)::
      override.byRegexp.new(options.alias)
      + override.byRegexp.withPropertiesFromOptions(
        {}
        + (
          if std.objectHas(options, 'color') then
            standardOptions.color.withFixedColor(options.color)
            + standardOptions.color.withMode('shades')
          else
            {}
        )
        + (
          if std.get(options, 'dashes') == true then
            custom.lineStyle.withFill('dash')
            + custom.lineStyle.withDash([options.dashLength, options.spaceLength])
          else
            {}
        )
        + (
          if std.objectHas(options, 'linewidth') then
            custom.withLineWidth(options.linewidth)
          else
            {}
        )
        + (
          if std.get(options, 'legend') == false then
            custom.hideFrom.withLegend(true)
          else
            {}
        )
      ),
  },

}
