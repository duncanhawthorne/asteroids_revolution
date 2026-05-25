enum Tile {
  miniPellet(_kMiniPellet),
  wall(_kWall),
  movingWall(_kMovingWall),
  lair(_kLair),
  superPellet(_kSuperPellet),
  empty(_kEmpty),
  ghostStart(_kGhostStart),
  pacmanStart(_kPacmanStart),
  cage(_kCage);

  const Tile(this.code);

  final String code;

  static final Map<String, Tile> _codeLookup = <String, Tile>{
    for (final Tile tile in Tile.values) tile.code: tile,
  };

  /// Decodes a single character into a [Tile], defaulting to [Tile.empty]
  static Tile fromCode(String char) => _codeLookup[char] ?? Tile.empty;
}

const String _kMiniPellet = "0"; //quad of dots
const String _kWall = "1";
const String _kMovingWall = "6";
const String _kLair = "2";
const String _kSuperPellet = "3"; //quad top
const String _kEmpty = "4";
const String _kGhostStart = "7";
const String _kPacmanStart = "8";
const String _kCage = "9";
