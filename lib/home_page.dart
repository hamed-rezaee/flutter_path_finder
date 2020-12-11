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
  final int _size = 20;

  Position _startPosition;
  Position _goalPosition;
  Position _selectedPosition;

  List<List<PathElement>> _grid;

  bool _isAStar = false;

  @override
  void initState() {
    super.initState();

    _grid = _initialGrid();
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Checkbox(
                    value: _isAStar,
                    onChanged: (bool value) => setState(() => _isAStar = value),
                  ),
                  const Text('Use A* Algorithm'),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildGrid() => Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _size,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          shrinkWrap: true,
          itemCount: _size * _size,
          itemBuilder: (BuildContext context, int index) {
            final int row = index ~/ _size;
            final int column = index % _size;

            return GestureDetector(
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Position(row: row, column: column) == _startPosition
                      ? Colors.green
                      : Position(row: row, column: column) == _goalPosition
                          ? Colors.red
                          : _grid[row][column].inPath
                              ? Colors.yellow[300]
                              : _grid[row][column].visited
                                  ? Colors.orange[400]
                                  : _grid[row][column].passable
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
            onPressed: () => _runFinder(_isAStar),
          ),
        ],
      );

  List<List<PathElement>> _initialGrid() {
    final List<List<PathElement>> grid = <List<PathElement>>[<PathElement>[]];

    for (int row = 0; row < _size; row++) {
      grid.add(<PathElement>[]);

      for (int column = 0; column < _size; column++) {
        grid[row].add(
          PathElement(position: Position(row: row, column: column)),
        );
      }
    }

    return grid;
  }

  void _restartGrid() {
    for (int row = 0; row < _size; row++) {
      for (int column = 0; column < _size; column++) {
        _grid[row][column]
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
    if (_selectedPosition != null) {
      _startPosition = _selectedPosition;

      setState(() {});
    }
  }

  void _setGoal() {
    if (_selectedPosition != null) {
      _goalPosition = _selectedPosition;

      _grid[_goalPosition.row][_goalPosition.column].passable = true;

      setState(() {});
    }
  }

  void _setWall(int row, int column) {
    _grid[row][column].passable = !_grid[row][column].passable;

    _selectedPosition = Position(row: row, column: column);

    setState(() {});
  }

  Future<void> _runFinder(bool isAStar) async {
    final List<PathElement> queue = <PathElement>[]
      ..add(_grid[_startPosition.row][_startPosition.column]..visited = true);

    PathElement currentPathElement = _getBestChild(queue);
    Position currentPosition = currentPathElement.position;

    while (
        _grid[_goalPosition.row][_goalPosition.column] != currentPathElement) {
      await Future<void>.delayed(const Duration(milliseconds: 5), () {
        _addChild(
          costMultiplier: 1,
          row: currentPosition.row - 1,
          column: currentPosition.column,
          queue: queue,
          parent: currentPathElement,
          isAStar: isAStar,
        );

        _addChild(
          costMultiplier: 1,
          row: currentPosition.row,
          column: currentPosition.column - 1,
          queue: queue,
          parent: currentPathElement,
          isAStar: isAStar,
        );

        _addChild(
          costMultiplier: 1,
          row: currentPosition.row,
          column: currentPosition.column + 1,
          queue: queue,
          parent: currentPathElement,
          isAStar: isAStar,
        );

        _addChild(
          costMultiplier: 1,
          row: currentPosition.row + 1,
          column: currentPosition.column,
          queue: queue,
          parent: currentPathElement,
          isAStar: isAStar,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentPosition.row - 1,
          column: currentPosition.column - 1,
          queue: queue,
          parent: currentPathElement,
          isAStar: isAStar,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentPosition.row - 1,
          column: currentPosition.column + 1,
          queue: queue,
          parent: currentPathElement,
          isAStar: isAStar,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentPosition.row + 1,
          column: currentPosition.column - 1,
          queue: queue,
          parent: currentPathElement,
          isAStar: isAStar,
        );

        _addChild(
          costMultiplier: 1.3,
          row: currentPosition.row + 1,
          column: currentPosition.column + 1,
          queue: queue,
          parent: currentPathElement,
          isAStar: isAStar,
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
    @required bool isAStar,
  }) {
    if (row >= 0 && column >= 0 && row < _size && column < _size) {
      if (!_grid[row][column].visited && _grid[row][column].passable) {
        queue.add(
          _grid[row][column]
            ..visited = true
            ..g = parent.g + _grid[row][column].cost * costMultiplier
            ..h = _calculateHeuristic(
              position: Position(row: row, column: column),
              isAStar: isAStar,
            ),
        );
      }

      _grid[row][column].parents.add(parent);

      _grid[row][column].g = min(
        _grid[row][column].g,
        parent.g + _grid[row][column].cost * costMultiplier,
      );
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
    @required bool isAStar,
  }) =>
      isAStar
          ? sqrt(pow(position.row - _goalPosition.row, 2) +
              pow(position.column - _goalPosition.column, 2))
          : 0;

  Future<void> _showShortestPath(PathElement goal) async {
    final List<PathElement> shortestPath = <PathElement>[];
    PathElement pathElement = goal;

    while (pathElement.parents.isNotEmpty &&
        pathElement.position != _startPosition) {
      shortestPath.add(pathElement = _getBestParent(pathElement.parents));
    }

    while (shortestPath.isNotEmpty) {
      await Future<void>.delayed(
        const Duration(milliseconds: 10),
        () => setState(() => shortestPath.removeLast()..inPath = true),
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

    return bestParent;
  }
}
