import 'pellet.dart';

class MiniPellet extends Pellet {
  MiniPellet({required super.position})
      : super(radiusFactor: 1 / 3, hitBoxRadiusFactor: 0);
}
