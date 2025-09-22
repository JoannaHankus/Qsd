import 'package:flutter/material.dart';
import 'bottom_bar.dart';
import 'top_bar.dart';
import 'world_map_screen.dart';
import 'under_construction.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/services.dart';

enum PomodoroPhase { idle, session, shortBreak, longBreak }

class PomodoroSettings {
  final int session;     // min
  final int shortBreak;  // min
  final int longBreak;   // min
  final int longEvery;   // co ile sesji długa przerwa
  const PomodoroSettings({
    required this.session,
    required this.shortBreak,
    required this.longBreak,
    required this.longEvery,
  });
}

class PomodoroScreen extends StatefulWidget  {
  const PomodoroScreen({super.key});

@override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  PomodoroSettings _settings = const PomodoroSettings(session: 50, shortBreak: 5, longBreak: 30, longEvery: 3);
  PomodoroPhase _phase = PomodoroPhase.idle; 
  int _sessionIndex = 1; // 1,2,3... 
  int _breakIndex = 0; // 1,2,3... 
  Duration _remaining = Duration.zero; 
  Duration _currentTotal = Duration.zero; // pełny czas bieżącej fazy 
  Timer? _ticker; 
  bool _isPaused = false;

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
  void _buzz() {
    HapticFeedback.mediumImpact(); // lub lightImpact/heavyImpact/selectionClick
  }
  

  // ===== Pomodoro: public getters do dialogu =====
  bool get isRunning => _phase != PomodoroPhase.idle;
  bool get isPaused => _isPaused;
  PomodoroSettings get settings => _settings;
  Duration get remaining => _remaining;
  Duration get currentTotal => _currentTotal;

  String get phaseLabel => switch (_phase) {
    PomodoroPhase.session     => 'Session $_sessionIndex',
    PomodoroPhase.shortBreak  => 'Break $_breakIndex',
    PomodoroPhase.longBreak   => 'Long break',
    PomodoroPhase.idle        => 'Idle',
  };

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ===== API wywoływane z dialogu =====
  void startWithSettings(PomodoroSettings s) {
    setState(() {
      _settings = s;
      _sessionIndex = 1;
      _breakIndex = 0;
    });
    _startSession();
  }

  void togglePauseTimer() {
    if (_phase == PomodoroPhase.idle) return;
    setState(() => _isPaused = !_isPaused);
  }

  void skipPhase() {
    _ticker?.cancel();
    _onPhaseComplete();
  }

  // ===== Sekwencja =====
  void _startSession() {
    _startPhase(PomodoroPhase.session, Duration(minutes: _settings.session));
  }

  void _startShortBreak() {
    _breakIndex++;
    _startPhase(PomodoroPhase.shortBreak, Duration(minutes: _settings.shortBreak));
  }

  void _startLongBreak() {
    _breakIndex++;
    _startPhase(PomodoroPhase.longBreak, Duration(minutes: _settings.longBreak));
  }

  void _startPhase(PomodoroPhase p, Duration d) {
    _ticker?.cancel();
    setState(() {
      _phase = p;
      _remaining = d;
      _currentTotal = d;
      _isPaused = false;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_isPaused) return;
      if (_remaining.inSeconds > 0) {
        setState(() => _remaining -= const Duration(seconds: 1));
      } else {
        t.cancel();
        _onPhaseComplete();
      }
    });
  }

  void _onPhaseComplete() {
    _buzz();
    if (_phase == PomodoroPhase.session) {
      if (_sessionIndex % _settings.longEvery == 0) {
        _startLongBreak();
      } else {
        _startShortBreak();
      }
    } else {
      _sessionIndex++;
      _startSession();
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
                        barrierDismissible: true,
                        builder: (_) => PomodoroTimerDialog(
                          // widok/odliczanie czytany z ekranu
                          titleLabel: 'Timer',
                          getIsRunning: () => isRunning,
                          getPhaseLabel: () => phaseLabel,
                          getRemaining: () => remaining,
                          getCurrentTotal: () => currentTotal,
                          getIsPaused: () => isPaused,

                          // sterowanie z ekranu
                          onPauseResume: togglePauseTimer,
                          onSkip: skipPhase,

                          // ustawienia startowe + start sekwencji
                          initial: settings,
                          onStart: startWithSettings,
                        ),
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
class PomodoroTimerDialog extends StatefulWidget {
  // wejścia do dialogu
  final String titleLabel;

  // GETTERY: dialog czyta stan z ekranu
  final bool Function() getIsRunning;
  final String Function() getPhaseLabel;
  final Duration Function() getRemaining;
  final Duration Function() getCurrentTotal;
  final bool Function() getIsPaused;

  // AKCJE: delegowane do ekranu
  final VoidCallback onPauseResume;
  final VoidCallback onSkip;

  // SETUP: wstępne wartości i start sekwencji
  final PomodoroSettings initial;
  final void Function(PomodoroSettings) onStart;

  const PomodoroTimerDialog({
    super.key,
    required this.titleLabel,
    required this.getIsRunning,
    required this.getPhaseLabel,
    required this.getRemaining,
    required this.getCurrentTotal,
    required this.getIsPaused,
    required this.onPauseResume,
    required this.onSkip,
    required this.initial,
    required this.onStart,
  });

  @override
  State<PomodoroTimerDialog> createState() => _PomodoroTimerDialogState();
}

class _PomodoroTimerDialogState extends State<PomodoroTimerDialog> {
  // lokalne kopie dla SETUP
  late int _session   = widget.initial.session;
  late int _shortBr   = widget.initial.shortBreak;
  late int _longBr    = widget.initial.longBreak;
  late int _longEvery = widget.initial.longEvery;

  // aby przełączyć się na RUNNING natychmiast po Start (bez czekania na rebuild)
  bool _forceRunning = false;
  Timer? _raf; // timer odświeżający UI

  @override
  void initState() {
    super.initState();
    // co sekundę odśwież UI, aby licznik i progress się zmieniały
    _raf = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _raf?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _forceRunning || widget.getIsRunning();
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
            child: running ? _buildRunning(context) : _buildSetup(context),
          ),
        ],
      ),
    );
  }

  // ---------- SETUP ----------
  Widget _buildSetup(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset('assets/icons/arrow.png', width: 28, height: 28),
            ),
            const SizedBox(width: 8),
            Text(widget.titleLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Idle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),

        _TimerRow(
          label: 'Session',
          value: _session,
          unit: 'minutes',
          onDec: () => setState(() => _session   = (_session - 1).clamp(1, 999)),
          onInc: () => setState(() => _session   = (_session + 1).clamp(1, 999)),
        ),
        _TimerRow(
          label: 'Break',
          value: _shortBr,
          unit: 'minutes',
          onDec: () => setState(() => _shortBr   = (_shortBr - 1).clamp(1, 999)),
          onInc: () => setState(() => _shortBr   = (_shortBr + 1).clamp(1, 999)),
        ),
        _TimerRow(
          label: 'Long break',
          value: _longBr,
          unit: 'minutes',
          onDec: () => setState(() => _longBr    = (_longBr - 1).clamp(1, 999)),
          onInc: () => setState(() => _longBr    = (_longBr + 1).clamp(1, 999)),
        ),
        _TimerRow(
          label: 'Long break every',
          value: _longEvery,
          unit: 'sessions',
          onDec: () => setState(() => _longEvery = (_longEvery - 1).clamp(1, 99)),
          onInc: () => setState(() => _longEvery = (_longEvery + 1).clamp(1, 99)),
        ),
        const SizedBox(height: 12),

        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              widget.onStart(
                PomodoroSettings(
                  session: _session,
                  shortBreak: _shortBr,
                  longBreak: _longBr,
                  longEvery: _longEvery,
                ),
              );
              // zamiast zamykać dialog, natychmiast przełącz widok na RUNNING
              setState(() => _forceRunning = true);
            },
            child: Image.asset('assets/icons/pomodoro_start.png', height: 48, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  // ---------- RUNNING ----------
  Widget _buildRunning(BuildContext context) {
    final label = widget.getPhaseLabel();
    final rem   = widget.getRemaining();
    final total = widget.getCurrentTotal();
    final paused= widget.getIsPaused();
    final prog  = total.inMilliseconds == 0
        ? 0.0
        : 1 - rem.inMilliseconds / total.inMilliseconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset('assets/icons/arrow.png', width: 28, height: 28),
            ),
            const SizedBox(width: 8),
            Text(widget.titleLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),

        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: _RingPainter(progress: prog),
              child: Center(
                child: Text(
                  _format(rem),
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: widget.onPauseResume,
              child: SizedBox(
                width: 56, height: 56,
                child: Image.asset(paused
                    ? 'assets/icons/pomodoro_play.png'
                    : 'assets/icons/pomodoro_pause.png'),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onSkip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBD2A8).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Text('Skip session'),
                    const SizedBox(width: 6),
                    Image.asset('assets/icons/chevron_left.png',
                        width: 16, height: 16, fit: BoxFit.contain),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
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

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final track = Paint()
      ..color = const Color(0xFFCFBDA2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF3E2D20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    final start = -90 * (3.1415926 / 180);          // od góry
    final sweep = 2 * 3.1415926 * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, start, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
