import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_path_finder/path_element.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int rowSize = 20;
  final int columnSize = 20;

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

    grid = _initialGrid();
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
                        height: 16,
                        width: 16,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: row == startRow && column == startColumn
                              ? Colors.green
                              : row == goalRow && column == goalColumn
                                  ? Colors.red
                                  : grid[row][column].inPath
                                      ? Colors.yellow[300]
                                      : grid[row][column].visited
                                          ? Colors.orange[400]
                                          : grid[row][column].passable
                                              ? Colors.blue[300]
                                              : Colors.grey[700],
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
            onPressed: _setStart,
          ),
          FlatButton(
            child: const Text('SET GOAL'),
            onPressed: _setGoal,
          ),
          FlatButton(
            child: const Text('RUN PATH FINDER'),
            onPressed: () => _runFinder(isBFS: true),
          ),
          FlatButton(
            child: const Text('RESTART'),
            onPressed: _restartGrid,
          ),
        ],
      );

  List<List<PathElement>> _initialGrid() {
    final List<List<PathElement>> grid = <List<PathElement>>[<PathElement>[]];

    for (int row = 0; row < rowSize; row++) {
      grid.add(<PathElement>[]);

      for (int column = 0; column < columnSize; column++) {
        grid[row].add(PathElement(row: row, column: column));
      }
    }

    return grid;
  }

  void _restartGrid() {
    for (int row = 0; row < rowSize; row++) {
      for (int column = 0; column < columnSize; column++) {
        grid[row][column]
          ..parent = null
          ..visited = false
          ..inPath = false
          ..g = 0
          ..h = 0;
      }
    }

    setState(() {});
  }

  void _setStart() {
    if (selectedRow != null && selectedColumn != null) {
      startRow = selectedRow;
      startColumn = selectedColumn;

      setState(() {});
    }
  }

  void _setGoal() {
    if (selectedRow != null && selectedColumn != null) {
      goalRow = selectedRow;
      goalColumn = selectedColumn;

      grid[goalRow][goalColumn].passable = true;

      setState(() {});
    }
  }

  Future<void> _runFinder({bool isBFS = false}) async {
    final List<PathElement> queue = <PathElement>[];

    int currentRow;
    int currentColumn;

    PathElement currentPathElement = grid[startRow][startColumn]
      ..visited = true;

    currentPathElement
      ..g = 0
      ..h = _calculateHeuristic(
        row: currentPathElement.row,
        column: currentPathElement.column,
        isBFS: isBFS,
      );

    currentRow = currentPathElement.row;
    currentColumn = currentPathElement.column;

    while (grid[goalRow][goalColumn] != currentPathElement) {
      await Future<void>.delayed(const Duration(milliseconds: 10), () {
        _addChild(
          costMultiplier: 1,
          row: currentRow - 1,
          column: currentColumn,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1,
          row: currentRow,
          column: currentColumn - 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1,
          row: currentRow,
          column: currentColumn + 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1,
          row: currentRow + 1,
          column: currentColumn,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentRow - 1,
          column: currentColumn - 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentRow - 1,
          column: currentColumn + 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentRow + 1,
          column: currentColumn - 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentRow + 1,
          column: currentColumn + 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        currentPathElement = _getBestChild(queue);

        currentRow = currentPathElement.row;
        currentColumn = currentPathElement.column;

        setState(() {});
      });
    }

    _showShortestPath(currentPathElement);
  }

  void _addChild({
    @required double costMultiplier,
    @required int row,
    @required int column,
    @required List<PathElement> queue,
    @required PathElement parent,
    @required bool isBFS,
  }) {
    if (row >= 0 && column >= 0 && row < rowSize && column < columnSize) {
      if (!grid[row][column].visited && grid[row][column].passable) {
        queue.add(
          grid[row][column]
            ..visited = true
            ..parent = parent
            ..g = parent.g + grid[row][column].cost * costMultiplier
            ..h = _calculateHeuristic(row: row, column: column, isBFS: isBFS),
        );
      }
    }
  }

  PathElement _getBestChild(List<PathElement> queue) {
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

  double _calculateHeuristic({
    @required int row,
    @required int column,
    @required bool isBFS,
  }) =>
      isBFS ? 0 : sqrt(pow(row - goalRow, 2) + pow(column - goalColumn, 2));

  void _showShortestPath(PathElement goal) {
    PathElement pathElement = goal;

    while (pathElement.parent != null) {
      pathElement.inPath = true;
      pathElement = pathElement.parent;
    }

    setState(() {});
  }
}
