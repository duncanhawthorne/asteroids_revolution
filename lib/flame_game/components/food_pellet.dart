import 'pellet.dart';

const double hitboxGenerosity = 0;

class Food extends Pellet {
  Food({required super.position})
      : super(radiusFactor: 2, hitBoxRadiusFactor: (1 + hitboxGenerosity));
}
