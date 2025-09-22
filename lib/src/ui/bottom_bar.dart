// bottom_bar.dart
import 'package:flutter/material.dart';

class BottomIconSpec {
  final String asset;
  final VoidCallback onTap;
  const BottomIconSpec(this.asset, this.onTap);
}

class BottomBarOverlay extends StatelessWidget {
  final List<BottomIconSpec> icons;       // 5 ikon
  final double bottomOffset;               // jak wysoko nad dołem
  const BottomBarOverlay({super.key, required this.icons, this.bottomOffset = 24});

  @override
  Widget build(BuildContext context) {
    assert(icons.length == 5);
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset + bottomOffset,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: icons.map((i) => _BottomIconButton(i.asset, i.onTap)).toList(),
      ),
    );
  }
}

class _BottomIconButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  const _BottomIconButton(this.asset, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}
