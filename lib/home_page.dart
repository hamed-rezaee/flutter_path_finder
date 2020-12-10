import 'package:flutter/material.dart';

import 'package:flutter_path_finder/element.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int rowSize = 50;
  final int columnSize = 36;

  int selectedRow;
  int selectedColumn;

  int startRow;
  int startColumn;

  int goalRow;
  int goalColumn;

  List<List<PathElement>> grid;

  @override
  void initState() {
    super.initState();

    grid = initialGrid();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('Flutter Path Finder'),
        ),
        body: _buildGrid(),
      );

  Widget _buildGrid() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            for (int row = 0; row < rowSize; row++)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int column = 0; column < columnSize; column++)
                    GestureDetector(
                      child: Container(
                        height: 8,
                        width: 8,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: row == startRow && column == startColumn
                              ? Colors.green
                              : row == goalRow && column == goalColumn
                                  ? Colors.red
                                  : grid[row][column].inPath
                                      ? Colors.orange
                                      : grid[row][column].visited
                                          ? Colors.black
                                          : grid[row][column].passable
                                              ? Colors.blue[200]
                                              : Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      onTap: () {
                        grid[row][column].passable =
                            !grid[row][column].passable;

                        selectedRow = row;
                        selectedColumn = column;

                        setState(() {});
                      },
                    )
                ],
              ),
            _buildButtonBar()
          ],
        ),
      );

  Widget _buildButtonBar() => ButtonBar(
        alignment: MainAxisAlignment.center,
        children: <Widget>[
          FlatButton(
            child: const Text('SET START'),
            onPressed: () {
              if (selectedRow != null && selectedColumn != null) {
                startRow = selectedRow;
                startColumn = selectedColumn;

                setState(() {});
              }
            },
          ),
          FlatButton(
            child: const Text('SET GOAL'),
            onPressed: () {
              if (selectedRow != null && selectedColumn != null) {
                goalRow = selectedRow;
                goalColumn = selectedColumn;

                grid[goalRow][goalColumn].passable = true;

                setState(() {});
              }
            },
          ),
          FlatButton(
            child: const Text('RUN PATH FINDER'),
            onPressed: () => runFinder(),
          ),
        ],
      );

  List<List<PathElement>> initialGrid() {
    final List<List<PathElement>> grid = <List<PathElement>>[<PathElement>[]];

    for (int row = 0; row < rowSize; row++) {
      grid.add(<PathElement>[]);

      for (int column = 0; column < columnSize; column++) {
        grid[row].add(PathElement(row: row, column: column));
      }
    }

    return grid;
  }

  Future<void> runFinder({bool isBFS = false}) async {
    final List<PathElement> queue = <PathElement>[]
      ..add(grid[startRow][startColumn]..visited = true);

    int currentRow;
    int currentColumn;

    PathElement currentPathElement = queue.removeAt(0);

    currentPathElement
      ..g = 0
      ..h = calculateHeuristic(
        row: currentPathElement.row,
        column: currentPathElement.column,
        isBFS: isBFS,
      );

    currentRow = currentPathElement.row;
    currentColumn = currentPathElement.column;

    while (grid[goalRow][goalColumn] != currentPathElement) {
      await Future<void>.delayed(const Duration(milliseconds: 10), () {
        _addChild(
          row: currentRow - 1,
          column: currentColumn - 1,
          queue: queue,
          element: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          row: currentRow - 1,
          column: currentColumn,
          queue: queue,
          element: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          row: currentRow - 1,
          column: currentColumn + 1,
          queue: queue,
          element: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          row: currentRow,
          column: currentColumn - 1,
          queue: queue,
          element: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          row: currentRow,
          column: currentColumn + 1,
          queue: queue,
          element: currentPathElement,
          isBFS: isBFS,
        );
        _addChild(
          row: currentRow + 1,
          column: currentColumn - 1,
          queue: queue,
          element: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          row: currentRow + 1,
          column: currentColumn,
          queue: queue,
          element: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          row: currentRow + 1,
          column: currentColumn + 1,
          queue: queue,
          element: currentPathElement,
          isBFS: isBFS,
        );

        currentPathElement = getBestChild(queue);

        currentRow = currentPathElement.row;
        currentColumn = currentPathElement.column;

        setState(() {});
      });
    }

    _showShortestPath(currentPathElement);
  }

  void _addChild({
    @required int row,
    @required int column,
    @required List<PathElement> queue,
    @required PathElement element,
    @required bool isBFS,
  }) {
    if (row >= 0 && column >= 0 && row < rowSize && column < columnSize) {
      if (!grid[row][column].visited && grid[row][column].passable) {
        final double h =
            calculateHeuristic(row: row, column: column, isBFS: isBFS);

        queue.add(
          grid[row][column]
            ..visited = true
            ..parent = element
            ..g = element.g
            ..h = h,
        );
      }
    }
  }

  PathElement getBestChild(List<PathElement> queue) {
    int minIndex = 0;
    double minValue = double.infinity;

    for (int i = 0; i < queue.length; i++) {
      if (queue[i].g + queue[i].h < minValue) {
        minIndex = i;
        minValue = queue[i].g + queue[i].h;
      }
    }

    return queue.removeAt(minIndex);
  }

  double calculateHeuristic({
    @required int row,
    @required int column,
    @required bool isBFS,
  }) =>
      isBFS
          ? 0
          : ((row - goalRow).abs() + (column - goalColumn).abs()).toDouble();

  void _showShortestPath(PathElement goal) {
    PathElement pathElement = goal;

    while (pathElement.parent != null) {
      pathElement.inPath = true;
      pathElement = pathElement.parent;
    }

    setState(() {});
  }
}
