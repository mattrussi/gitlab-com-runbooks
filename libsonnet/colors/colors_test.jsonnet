local test = import "github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet";
local colors = import 'colors.libsonnet';

test.suite({
  testRGBABlackToString: { actual: colors.rgba(0, 0, 0, 0).toString(), expect: 'rgba(0,0,0,0.00)' },
  testRGBABlueToString: { actual: colors.rgba(0, 0, 255, 1).toString(), expect: '#0000ff' },
  testRGBARedToString: { actual: colors.rgba(255, 0, 0, 0.5).toString(), expect: 'rgba(255,0,0,0.50)' },
  testLinearGradient: {
    actual: std.map(function(x) x.toString(), colors.linearGradient(colors.rgba(0, 0, 0, 1), colors.rgba(255, 255, 0, 1), 10)),
    expect: [
      "#000000",
      "#191900",
      "#333300",
      "#4c4c00",
      "#666600",
      "#7f7f00",
      "#999900",
      "#b2b200",
      "#cccc00",
      "#ffff00"
    ],
  },
})
