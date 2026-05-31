/// Enum representing different types of tiles in the maze layout.
enum Tile {
  /// A small pellet for Pacman to eat.
  miniPellet(_kMiniPellet),

  /// A solid, static wall.
  wall(_kWall),

  /// A dynamic or moving wall.
  movingWall(_kMovingWall),

  /// The ghost's home or lair area.
  lair(_kLair),

  /// A larger power-up pellet.
  superPellet(_kSuperPellet),

  /// An empty space.
  empty(_kEmpty),

  /// The starting position for ghosts.
  ghostStart(_kGhostStart),

  /// The starting position for Pacman.
  pacmanStart(_kPacmanStart),

  /// The cage area where ghosts wait.
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
