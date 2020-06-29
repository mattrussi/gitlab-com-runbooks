local generateColumnOffsets(columnWidths) =
  std.foldl(function(columnOffsets, width) columnOffsets + [width + columnOffsets[std.length(columnOffsets) - 1]], columnWidths, [0]);

// Grafana uses a grid with width 24 for layout
local grafanaGridWidth = 24;

local grid(panels, cols, rowHeight, startRow) =
  local colsSafe = if cols > grafanaGridWidth then grafanaGridWidth else cols;

  std.mapWithIndex(
    function(index, panel)
      panel {
        gridPos: {
          x: std.floor(((grafanaGridWidth / colsSafe) * index) % grafanaGridWidth),
          y: std.floor(((grafanaGridWidth / colsSafe) * index) / grafanaGridWidth) * rowHeight + startRow,
          w: std.floor(grafanaGridWidth / colsSafe),
          h: rowHeight,
        },
      },
    panels
  );

local horizontalLayoutRow(panels, rowHeight=10, startRow=0) =
  if !std.isArray(panels) then
    grid([panels], 1, rowHeight, startRow)
  else if std.length(panels) == 0 then
    []
  else
    grid(panels, std.length(panels), rowHeight, startRow);

{
  grid(panels, cols=2, rowHeight=10, startRow=0)::
    grid(panels=panels, cols=cols, rowHeight=rowHeight, startRow=startRow),

  columnGrid(rowsOfPanels, columnWidths, rowHeight=10, startRow=0)::
    local columnOffsets = generateColumnOffsets(columnWidths);

    std.flattenArrays(
      std.mapWithIndex(
        function(rowIndex, rowOfPanels)
          std.mapWithIndex(
            function(colIndex, panel)
              panel {
                gridPos: {
                  x: columnOffsets[colIndex],
                  y: rowIndex * rowHeight + startRow,
                  w: columnWidths[colIndex],
                  h: rowHeight,
                },
              },
            rowOfPanels
          ),
        rowsOfPanels
      )
    ),

  horizontalLayout(rows, rowHeight, startRow=0)::
    local positionedRows = std.foldl(
      function(memo, row) memo + horizontalLayoutRow(row, startRow=rowHeight * std.length(memo), rowHeight=rowHeight),
      rows,
      []
    );
    positionedRows,

  // std.flattenArrays(positionedRows),
}
