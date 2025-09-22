import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final List<String> icons;           // np. ['assets/icons/top_1.png', ...]
  final void Function(int) onTap;     // callback
  const TopBar({required this.icons, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,   // 👈 równe rozmieszczenie
        children: List.generate(icons.length, (i) {
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(                          // „hit area”, ale bez tła
              width: 80,                              // dopasuj do swoich PNG
              height: 80,
              child: Center(
                child: Image.asset(
                  icons[i],
                  width: 118,                          // rozmiar samej ikony
                  height: 117,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}