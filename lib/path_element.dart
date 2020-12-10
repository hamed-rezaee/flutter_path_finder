import 'package:flutter_path_finder/position.dart';

class PathElement {
  PathElement({this.position});

  double g = 0;
  double h = 0;

  double cost = 1;

  Position position;

  bool passable = true;
  bool visited = false;
  bool inPath = false;

  PathElement parent;
  List<PathElement> children = <PathElement>[];
}
