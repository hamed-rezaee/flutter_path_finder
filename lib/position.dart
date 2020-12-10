import 'package:equatable/equatable.dart';

class Position extends Equatable {
  const Position({this.row, this.column});

  final int row;
  final int column;

  @override
  List<Object> get props => <int>[row, column];
}
