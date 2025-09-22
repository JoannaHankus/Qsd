// world_map_screen.dart
import 'package:flutter/material.dart';
import 'bottom_bar.dart';
import 'under_construction.dart';
import 'top_bar.dart';
import 'map_screen.dart';
import 'pomodoro_screen.dart';

class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  static const double fireXpx = 5 * 60.0; // ≈ 5/6 szerokości – wyregulujesz liczbą
  static const double fireYpx = 1 * 220.0; // ≈ 2/3 wysokości – wyregulujesz liczbą
  static const double fireSize = 72;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Pełnoekranowa mapa
          Positioned.fill(
            child: Image.asset(
              'assets/images/map.png',
              fit: BoxFit.cover, // WYPEŁNIA cały ekran
            ),
          ),

          // 2) Górny pasek (jak w widoku głównym)
          SafeArea(
          bottom: false, // dół zostawiamy dla dolnego paska
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6), // TYLE SAMO co w MapScreen
              TopBar(
                icons: const [
                  'assets/icons/top_-05.png',
                  'assets/icons/top_-06.png',
                  'assets/icons/top_-07.png',
                  'assets/icons/top_-08.png',
                ],
                onTap: (i) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UnderConstructionScreen()),
                  );
                },
              ),
              const SizedBox(height: 8), // opcjonalnie, jeśli w głównym też jest
            ],
          ),
        ),
        Positioned(
            left: fireXpx,
            top: fireYpx,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PomodoroScreen()),
                );
              },
              child: Image.asset(
                'assets/icons/world_map_fireplace.png',
                width: fireSize,
                height: fireSize,
              ),
            ),
          ),

          // 3) Dolny pasek jako OVERLAY w Stacku
          BottomBarOverlay(
            bottomOffset: 24,
            icons: [
              // "scroll" wraca do widoku głównego
              BottomIconSpec('assets/icons/bottom_scroll.png', () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                  (route) => false,
                );
              }),
              BottomIconSpec('assets/icons/bottom_quill.png', () {}),
              BottomIconSpec('assets/icons/bottom_sun.png', () {}),
              BottomIconSpec('assets/icons/bottom_fire.png', () {}),
              BottomIconSpec('assets/icons/bottom_star.png', () {}),
            ],
          ),
        ],
      ),
    );
  }
}
