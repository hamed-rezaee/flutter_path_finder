class PathElement {
  PathElement({this.row, this.column});

  double g = 0;
  double h = 0;

  int row;
  int column;

  bool passable = true;
  bool visited = false;
  bool inPath = false;

  PathElement parent;
  List<PathElement> children = <PathElement>[];
}
