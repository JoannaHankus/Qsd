import 'package:flutter/material.dart';
import 'bottom_bar.dart';
import 'top_bar.dart';
import 'world_map_screen.dart';
import 'under_construction.dart';
import 'package:audioplayers/audioplayers.dart';

class PomodoroScreen extends StatefulWidget  {
  const PomodoroScreen({super.key});

@override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool _isNight = false;
  void _toggleDayNight() => setState(() => _isNight = !_isNight);

    @override
    void dispose() {
      _player.dispose();
      super.dispose();
    }

    void togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(AssetSource('audio/sound.mp3'));
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // tło całego ekranu
          Positioned.fill(
            child: Image.asset(_isNight
                  ? 'assets/images/pomodoro_night_bg.png'
                  : 'assets/images/pomodoro_day_bg.png',
              fit: BoxFit.cover,),
          ),

          // górne menu (działa jak wcześniej: przenosi do "under construction")
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
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
                const SizedBox(height: 8),
              ],
            ),
          ),

          // 2 przyciski pod top barem: sound + timer
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 90), // odstęp pod górnym menu
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CircleIconButton(
                      asset: 'assets/icons/pomodoro_sound.png',
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => PomodoroVolumeDialog(isPlaying: _isPlaying,
                    onToggle: togglePlayPause,),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // SUN / MOON (przełącznik tła)
                    _CircleIconButton(
                      asset: _isNight
                          ? 'assets/icons/pomodoro_moon.png'
                          : 'assets/icons/pomodoro_sun.png',
                      onTap: _toggleDayNight,
                      scale: 1.05, // opcjonalnie lekko mniejszy
                    ),
                    const SizedBox(width: 16),
                    _CircleIconButton(
                      asset: 'assets/icons/pomodoro_timer.png',
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const _PomodoroTimerDialog(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // dolne menu: scroll -> główny; star -> mapa
          BottomBarOverlay(
            bottomOffset: 24,
            icons: [
              BottomIconSpec('assets/icons/bottom_scroll.png', () {
                Navigator.of(context).popUntil((r) => r.isFirst); // do ekranu głównego
              }),
              BottomIconSpec('assets/icons/bottom_quill.png',  () {}),
              BottomIconSpec('assets/icons/bottom_sun.png',    () {}),
              BottomIconSpec('assets/icons/bottom_fire.png',   () {}),
              BottomIconSpec('assets/icons/bottom_star.png',   () {
                Navigator.of(context).pushReplacement(
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

// ——— POPUP: Volume / Playlist ———
class PomodoroVolumeDialog  extends StatelessWidget  {
 final bool isPlaying;
 final VoidCallback onToggle;

  const PomodoroVolumeDialog({
    super.key,
    required this.isPlaying,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // tło
            SizedBox(
              width: double.infinity,
              child: Image.asset('assets/images/pomodoro_sound_bg.png', fit: BoxFit.fill),
            ),

            // zawartość
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + kb),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // wiersz tytułu + ikona zamknięcia (arrow po lewej)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset('assets/icons/arrow.png', width: 28, height: 28),
                      ),
                      const SizedBox(width: 8),
                      const Text('Playlist', style: TextStyle(fontSize: 18)),
                      const Spacer(),
                      // prawy górny róg – placeholdery (sound, settings)
                      Row(
                        children: [
                          _TinyIcon('assets/icons/pomodoro_sound_volume.png'),
                          const SizedBox(width: 8),
                          _TinyIcon('assets/icons/pomodoro_sound_settings.png'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // sterowanie 
                  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundSmallBtn('assets/icons/pomodoro_backward.png', onTap: () {}),
                    const SizedBox(width: 18),

                    // 👇 przycisk zmienia się między play/pause
                    GestureDetector(
                      onTap: onToggle,
                      child: Image.asset(
                        isPlaying
                            ? 'assets/icons/pomodoro_pause.png'
                            : 'assets/icons/pomodoro_play.png',
                        width: 58,
                        height: 58,
                      ),
                    ),

                    const SizedBox(width: 18),
                    _RoundSmallBtn('assets/icons/pomodoro_forward.png', onTap: () {}),
                  ],
                ),
                  const SizedBox(height: 20),

                  // suwak "utworu" (placeholder)
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: 0.3,
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Celtic Pan pipes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ——— POPUP: Timer ———
class _PomodoroTimerDialog extends StatefulWidget {
  const _PomodoroTimerDialog();

  @override
  State<_PomodoroTimerDialog> createState() => _PomodoroTimerDialogState();
}

class _PomodoroTimerDialogState extends State<_PomodoroTimerDialog> {
  int session = 50, brk = 5, longBreak = 30, every = 3;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            child: Image.asset('assets/images/pomodoro_timer_bg.png', fit: BoxFit.fill),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // nagłówek
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset('assets/icons/arrow.png', width: 28, height: 28),
                    ),
                    const SizedBox(width: 8),
                    const Text('Timer', style: TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 16),

                _TimerRow(label: 'Session', value: session, unit: 'minutes',
                  onDec: () => setState(() => session = (session - 1).clamp(1, 999)),
                  onInc: () => setState(() => session = (session + 1).clamp(1, 999)),
                ),
                _TimerRow(label: 'Break', value: brk, unit: 'minutes',
                  onDec: () => setState(() => brk = (brk - 1).clamp(1, 999)),
                  onInc: () => setState(() => brk = (brk + 1).clamp(1, 999)),
                ),
                _TimerRow(label: 'Long break', value: longBreak, unit: 'minutes',
                  onDec: () => setState(() => longBreak = (longBreak - 1).clamp(1, 999)),
                  onInc: () => setState(() => longBreak = (longBreak + 1).clamp(1, 999)),
                ),
                _TimerRow(label: 'Long break every', value: every, unit: 'sessions',
                  onDec: () => setState(() => every = (every - 1).clamp(1, 99)),
                  onInc: () => setState(() => every = (every + 1).clamp(1, 99)),
                ),
                const SizedBox(height: 12),

                // Start (placeholder)
                GestureDetector(
                  onTap: () {/* start timer */},
                  child: Image.asset('assets/icons/pomodoro_start.png', height: 48, fit: BoxFit.contain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRow extends StatelessWidget {
  final String label, unit;
  final int value;
  final VoidCallback onDec, onInc;
  const _TimerRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.onDec,
    required this.onInc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              _Chevron(onTap: onDec),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$value', style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold,)),
              ),
              _Chevron(right: true, onTap: onInc),
            ],
          ),
          Text(unit),
        ],
      ),
    );
  }
}

// ——— drobne helpery UI ———
class _CircleIconButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  final double scale;
  const _CircleIconButton({required this.asset, required this.onTap, this.scale = 1.0,});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 50,
        height: 40,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  const _RoundBtn(this.asset, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 58, height: 58, child: Image.asset(asset, fit: BoxFit.contain)),
    );
  }
}

class _RoundSmallBtn extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  const _RoundSmallBtn(this.asset, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 32, height: 32, child: Image.asset(asset, fit: BoxFit.contain)),
    );
  }
}

class _TinyIcon extends StatelessWidget {
  final String asset;
  const _TinyIcon(this.asset);
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 24, height: 24, child: Image.asset(asset, fit: BoxFit.contain));
}

class _Chevron extends StatelessWidget {
  final bool right;
  final VoidCallback onTap;
  const _Chevron({this.right = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateY(right ? 3.1416 : 0), // obrót w poziomie dla prawego
          child: Image.asset(
            'assets/icons/chevron_left.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ten sam top-bar co na innych ekranach
// class _TopBar extends StatelessWidget {
//   final List<String> icons;
//   final void Function(int) onTap;
//   const _TopBar({required this.icons, required this.onTap, super.key});

//   @override
//   Widget build(BuildContext context) => Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           for (int i = 0; i < icons.length; i++)
//             GestureDetector(
//               onTap: () => onTap(i),
//               child: SizedBox(
//                 width: 40,
//                 height: 40,
//                 child: Image.asset(icons[i], fit: BoxFit.contain),
//               ),
//             ),
//         ],
//       );
// }
