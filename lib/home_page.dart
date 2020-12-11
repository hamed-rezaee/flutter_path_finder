import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_path_finder/path_element.dart';
import 'package:flutter_path_finder/position.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int size = 20;

  Position startPosition;
  Position goalPosition;
  Position selectedPosition;

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
        body: Column(
          children: <Widget>[
            _buildGrid(),
            _buildButtonBar(),
          ],
        ),
      );

  Widget _buildGrid() => Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          shrinkWrap: true,
          itemCount: size * size,
          itemBuilder: (BuildContext context, int index) {
            final int row = index ~/ size;
            final int column = index % size;

            return GestureDetector(
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Position(row: row, column: column) == startPosition
                      ? Colors.green
                      : Position(row: row, column: column) == goalPosition
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
              onTap: () => _setWall(row, column),
            );
          },
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
            child: const Text('RESTART'),
            onPressed: _restartGrid,
          ),
          FlatButton(
            child: const Text('RUN'),
            onPressed: () => _runFinder(false),
          ),
        ],
      );

  List<List<PathElement>> _initialGrid() {
    final List<List<PathElement>> grid = <List<PathElement>>[<PathElement>[]];

    for (int row = 0; row < size; row++) {
      grid.add(<PathElement>[]);

      for (int column = 0; column < size; column++) {
        grid[row].add(
          PathElement(position: Position(row: row, column: column)),
        );
      }
    }

    return grid;
  }

  void _restartGrid() {
    for (int row = 0; row < size; row++) {
      for (int column = 0; column < size; column++) {
        grid[row][column]
          ..parents = <PathElement>[]
          ..visited = false
          ..inPath = false
          ..g = 0
          ..h = 0;
      }
    }

    setState(() {});
  }

  void _setStart() {
    if (selectedPosition != null) {
      startPosition = selectedPosition;

      setState(() {});
    }
  }

  void _setGoal() {
    if (selectedPosition != null) {
      goalPosition = selectedPosition;

      grid[goalPosition.row][goalPosition.column].passable = true;

      setState(() {});
    }
  }

  void _setWall(int row, int column) {
    grid[row][column].passable = !grid[row][column].passable;

    selectedPosition = Position(row: row, column: column);

    setState(() {});
  }

  Future<void> _runFinder(bool isBFS) async {
    final List<PathElement> queue = <PathElement>[]
      ..add(grid[startPosition.row][startPosition.column]..visited = true);

    PathElement currentPathElement = _getBestChild(queue);
    Position currentPosition = currentPathElement.position;

    while (grid[goalPosition.row][goalPosition.column] != currentPathElement) {
      await Future<void>.delayed(const Duration(milliseconds: 5), () {
        _addChild(
          costMultiplier: 1,
          row: currentPosition.row - 1,
          column: currentPosition.column,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1,
          row: currentPosition.row,
          column: currentPosition.column - 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1,
          row: currentPosition.row,
          column: currentPosition.column + 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1,
          row: currentPosition.row + 1,
          column: currentPosition.column,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentPosition.row - 1,
          column: currentPosition.column - 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentPosition.row - 1,
          column: currentPosition.column + 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentPosition.row + 1,
          column: currentPosition.column - 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentPosition.row + 1,
          column: currentPosition.column + 1,
          queue: queue,
          parent: currentPathElement,
          isBFS: isBFS,
        );

        currentPathElement = _getBestChild(queue);

        currentPosition = currentPathElement.position;

        setState(() {});
      });
    }

    await _showShortestPath(currentPathElement);
  }

  void _addChild({
    @required double costMultiplier,
    @required int row,
    @required int column,
    @required List<PathElement> queue,
    @required PathElement parent,
    @required bool isBFS,
  }) {
    if (row >= 0 && column >= 0 && row < size && column < size) {
      if (!grid[row][column].visited && grid[row][column].passable) {
        queue.add(
          grid[row][column]
            ..visited = true
            ..g = parent.g + grid[row][column].cost * costMultiplier
            ..h = _calculateHeuristic(
              position: Position(row: row, column: column),
              isBFS: isBFS,
            ),
        );
      }

      grid[row][column].parents.add(parent);
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
    @required Position position,
    @required bool isBFS,
  }) =>
      isBFS
          ? 0
          : sqrt(pow(position.row - goalPosition.row, 2) +
              pow(position.column - goalPosition.column, 2));

  Future<void> _showShortestPath(PathElement goal) async {
    PathElement pathElement = goal;

    while (pathElement.parents.isNotEmpty &&
        pathElement.position != startPosition) {
      await Future<void>.delayed(
        const Duration(milliseconds: 10),
        () => setState(() => pathElement = _getBestParent(pathElement.parents)),
      );
    }
  }

  PathElement _getBestParent(List<PathElement> parents) {
    PathElement bestParent;

    for (final PathElement parent in parents) {
      if (!parent.inPath) {
        if (bestParent == null) {
          bestParent = parent;
        } else if (parent.g < bestParent.g) {
          bestParent = parent;
        }
      }
    }

    return bestParent..inPath = true;
  }
}
