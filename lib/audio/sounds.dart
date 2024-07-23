List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.ghostsScared:
      return const [
        'ghosts_runaway.mp3',
      ];
    case SfxType.endMusic:
      return const [
        'win.mp3',
      ];
    case SfxType.eatGhost:
      return const ['eat_ghost.mp3'];
    case SfxType.pacmanDeath:
      return const ['pacman_death.mp3'];
    case SfxType.waka:
      return const [
        'pacman_waka_waka.mp3',
      ];
    case SfxType.startMusic:
      return const [
        'pacman_beginning.mp3',
      ];
    case SfxType.ghostsRoamingSiren:
      return const [
        'ghosts_siren.mp3',
      ];
  }
}

const double volumeScalar = 0.5;

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.waka:
    case SfxType.startMusic:
    case SfxType.ghostsScared:
    case SfxType.endMusic:
    case SfxType.pacmanDeath:
    case SfxType.eatGhost:
      return 1 * volumeScalar;
    case SfxType.ghostsRoamingSiren:
      return 0;
  }
}

enum SfxType {
  waka,
  startMusic,
  ghostsScared,
  endMusic,
  eatGhost,
  pacmanDeath,
  ghostsRoamingSiren,
}
