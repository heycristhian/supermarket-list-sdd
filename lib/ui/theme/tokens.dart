/// Medidas e durações da interface. Telas e widgets não usam números
/// literais (Constituição VI): tudo vem daqui ou do `ThemeData`.
abstract final class Tokens {
  // Espaçamentos.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double spaceXxl = 32;

  // Raios.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;

  // Tamanhos.
  static const double minTouchTarget = 48;
  static const double itemRowMinHeight = 64;
  static const double activeAccentWidth = 4;
  static const double accentLineThickness = 1;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 64;
  static const double splashLogoWidth = 240;

  /// Escala inicial do logo na splash (cresce até 1).
  static const double splashLogoStartScale = 0.92;

  /// Fração da animação da splash em que a linha começa a se desenhar.
  static const double splashLineStart = 0.4;

  // Elevações.
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMid = 3;

  // Durações.
  static const durationFast = Duration(milliseconds: 150);
  static const durationMedium = Duration(milliseconds: 250);
  static const durationSlow = Duration(milliseconds: 600);
  static const undoSnackBarDuration = Duration(seconds: 5);
  static const splashMaxDuration = Duration(milliseconds: 1500);
}
