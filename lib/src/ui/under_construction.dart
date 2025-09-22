// under_construction_screen.dart
import 'package:flutter/material.dart';
import 'bottom_bar.dart';
import 'top_bar.dart';
import 'world_map_screen.dart';
import 'map_screen.dart';

class UnderConstructionScreen extends StatelessWidget {
  const UnderConstructionScreen({super.key});

  // te same „pokrętła” co w głównym widoku
  static const double kTopBarIconSize = 70.0; // jeśli w twoim _TopBar jest inna wartość, podmień
  static const double kTopBarTopPad   = 6.0;
  static const double kTopBarBottomGap= 8.0;
  static const double kGoBackGapBelowTopBar = 8.0;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    // Pozycja ikony powrotu: tuż pod top-barem
    final double goBackTop = safeTop
        + kTopBarTopPad
        + kTopBarIconSize
        + kTopBarBottomGap
        + kGoBackGapBelowTopBar;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Tło
          Positioned.fill(
            child: Image.asset(
              'assets/images/under_construction.png',
              fit: BoxFit.cover,
            ),
          ),

          // Górny pasek – TEN SAM co w MapScreen (importuj i użyj tej samej klasy)
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: kTopBarTopPad),
                TopBar(
                  icons: const [
                    'assets/icons/top_-05.png',
                    'assets/icons/top_-06.png',
                    'assets/icons/top_-07.png',
                    'assets/icons/top_-08.png',
                  ],
                  onTap: (i) {
                    // już jesteśmy na „pod budową” – nic nie rób albo otwieraj kolejne UC
                  },
                  // jeśli Twój _TopBar ma parametr na rozmiar ikon — przekaż kTopBarIconSize
                ),
                const SizedBox(height: kTopBarBottomGap),
              ],
            ),
          ),

          // Ikona powrotu – UWAGA: bezpośrednio w Stack, NIE w SafeArea
          Positioned(
            top: goBackTop,
            //left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset(
                'assets/icons/go_back.png',
                //width: 48,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Dolny pasek – overlay poza SafeArea (jak na innych ekranach)
          BottomBarOverlay(
            bottomOffset: 24,
            icons: [
              // Scroll -> wróć do głównego ekranu
              BottomIconSpec('assets/icons/bottom_scroll.png', () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }),
              // Placeholdery
              BottomIconSpec('assets/icons/bottom_quill.png', () { debugPrint('Quill'); }),
              BottomIconSpec('assets/icons/bottom_sun.png',   () { debugPrint('Sun'); }),
              BottomIconSpec('assets/icons/bottom_fire.png',  () { debugPrint('Fire'); }),
              // Star -> world map
              BottomIconSpec('assets/icons/bottom_star.png', () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorldMapScreen()),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
