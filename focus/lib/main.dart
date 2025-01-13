import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Set window properties
  WindowOptions windowOptions = const WindowOptions(
    size: Size(420,710),
    center: true,
    titleBarStyle: TitleBarStyle.hidden, // Hide the title bar
  );

  // Wait for the window to be ready
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show(); // Show the window
    await windowManager.focus(); // Focus the window
  });

  doWhenWindowReady(() {
      final win = appWindow;
      const initialSize =Size(420, 710);
      win.minSize = initialSize;
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.show();
    });
  runApp(const FocusKeeperApp());
  
}

class FocusKeeperApp extends StatelessWidget {
  const FocusKeeperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus Keeper',
      theme: ThemeData(
        fontFamily: 'Arial',
        primaryColor: Colors.redAccent,
      ),
      home: const FocusKeeperHomePage(),
    );
  }
}

class FocusKeeperHomePage extends StatefulWidget {
  const FocusKeeperHomePage({Key? key}) : super(key: key);

  @override
  _FocusKeeperHomePageState createState() => _FocusKeeperHomePageState();
}

class _FocusKeeperHomePageState extends State<FocusKeeperHomePage> {
  String focusTime = '1:00';
  String shortBreakTime = '1:00';
  String longBreakTime = '1:00';
  String currentTimer = '1:00'; // This will reflect the current timer value
  String currentPhase = 'Focus'; // Tracks the current phase (Focus, Short Break, Long Break)

  bool isEditingFocus = false;
  bool isEditingShortBreak = false;
  bool isEditingLongBreak = false;

  final TextEditingController _focusTimeController = TextEditingController();
  final TextEditingController _shortBreakTimeController = TextEditingController();
  final TextEditingController _longBreakTimeController = TextEditingController();

  bool isTimerRunning = false;
  int focusCyclesCompleted = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    currentTimer = focusTime;
    _focusTimeController.text = focusTime;
    _shortBreakTimeController.text = shortBreakTime;
    _longBreakTimeController.text = longBreakTime;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer(String newTime, String timerType) {
    setState(() {
      if (timerType == 'Focus') {
        focusTime = newTime;
        if (currentPhase == 'Focus') {
          currentTimer = newTime; // Update the top Focus Timer
        }
        _focusTimeController.text = newTime;
        isEditingFocus = false;
      } else if (timerType == 'Short Break') {
        shortBreakTime = newTime;
        if (currentPhase == 'Short Break') {
          currentTimer = newTime; // Update the top Short Break Timer
        }
        _shortBreakTimeController.text = newTime;
        isEditingShortBreak = false;
      } else if (timerType == 'Long Break') {
        longBreakTime = newTime;
        if (currentPhase == 'Long Break') {
          currentTimer = newTime; // Update the top Long Break Timer
        }
        _longBreakTimeController.text = newTime;
        isEditingLongBreak = false;
      }
    });
  }

  bool _validateTimeFormat(String time) {
    // Validate time format (MMM:SS)
    final RegExp timeRegex = RegExp(r'^\d{1,3}:\d{2}$');
    return timeRegex.hasMatch(time);
  }

  String _formatTime(String time) {
    // Automatically convert "M:SS" to "MM:SS" or "MMM:SS"
    final parts = time.split(':');
    if (parts.length == 2) {
      // Format minutes and seconds
      final minutes = parts[0].padLeft(1, '0'); // Allow 1-3 digits for minutes
      final seconds = parts[1].padLeft(2, '0'); // Always 2 digits for seconds

      // Cap minutes at 999
      final minutesInt = int.tryParse(minutes) ?? 0;
      final cappedMinutes = minutesInt > 999 ? '999' : minutesInt.toString();

      return '$cappedMinutes:$seconds';
    }
    return time; // Return as-is if invalid
  }

  void _toggleTimer() {
    if (isTimerRunning) {
      // Stop the timer and reset to focus time
      _stopTimer();
      _resetTimer();
    } else {
      // Start the timer
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      isTimerRunning = true;
    });

    _runTimer();
  }

  void _runTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final parts = currentTimer.split(':');
        int minutes = int.parse(parts[0]);
        int seconds = int.parse(parts[1]);

        if (seconds > 0) {
          seconds--;
        } else {
          if (minutes > 0) {
            minutes--;
            seconds = 59;
          } else {
            // Timer ended, switch to the next phase
            _switchPhase();
            return;
          }
        }

        currentTimer = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  void _switchPhase() {
    _stopTimer(); // Stop the current timer before switching phases

    if (currentPhase == 'Focus') {
      if (focusCyclesCompleted < 3) {
        // Move to Short Break
        setState(() {
          currentPhase = 'Short Break';
          currentTimer = shortBreakTime;
          focusCyclesCompleted++;
        });
      } else {
        // Move to Long Break
        setState(() {
          currentPhase = 'Long Break';
          currentTimer = longBreakTime;
          focusCyclesCompleted = 0;
        });
      }
    } else if (currentPhase == 'Short Break') {
      // Move back to Focus Time
      setState(() {
        currentPhase = 'Focus';
        currentTimer = focusTime;
      });
    } else if (currentPhase == 'Long Break') {
      // Move back to Focus Time after Long Break
      setState(() {
        currentPhase = 'Focus';
        currentTimer = focusTime;
      });
    }

    // Restart the timer for the new phase
    _startTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer(); // Ensure the timer is stopped before resetting
    setState(() {
      currentPhase = 'Focus'; // Reset phase to Focus
      currentTimer = focusTime; // Reset timer to focus time
      focusCyclesCompleted = 0; // Reset focus cycles
    });
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6), // Light beige background
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header
                    Container(
                      color: Color(0xFFFDF5E6), // Set the background color here
                      height: 50, // Title bar height
                      child: Row(
                        children: [
                          Expanded(
                            child: MoveWindow(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                child: Text(
                                  'FOCUS KEEPER',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          WindowButtons(),
                        ],
                      ),
                    ),

                    // Timer Display
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$currentPhase Timer', // Display the current phase
                          style: const TextStyle(fontSize: 20, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentTimer, // Display the current timer value
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    // Timer Options
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimerCard(
                              title: 'Focus',
                              time: focusTime,
                              color: Colors.redAccent,
                              isEditing: isEditingFocus,
                              onTap: () {
                                setState(() {
                                  isEditingFocus = true;
                                  isEditingShortBreak = false;
                                  isEditingLongBreak = false;
                                });
                              },
                              onSubmitted: (value) {
                                final formattedTime = _formatTime(value);
                                if (_validateTimeFormat(formattedTime)) {
                                  _updateTimer(formattedTime, 'Focus');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid time format. Use MMM:SS.'),
                                    ),
                                  );
                                }
                              },
                              controller: _focusTimeController,
                            ),
                            const SizedBox(width: 8),
                            TimerCard(
                              title: 'Short Break',
                              time: shortBreakTime,
                              color: Colors.blueAccent,
                              isEditing: isEditingShortBreak,
                              onTap: () {
                                setState(() {
                                  isEditingShortBreak = true;
                                  isEditingFocus = false;
                                  isEditingLongBreak = false;
                                });
                              },
                              onSubmitted: (value) {
                                final formattedTime = _formatTime(value);
                                if (_validateTimeFormat(formattedTime)) {
                                  _updateTimer(formattedTime, 'Short Break');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid time format. Use MMM:SS.'),
                                    ),
                                  );
                                }
                              },
                              controller: _shortBreakTimeController,
                            ),
                            const SizedBox(width: 8),
                            TimerCard(
                              title: 'Long Break',
                              time: longBreakTime,
                              color: Colors.greenAccent,
                              isEditing: isEditingLongBreak,
                              onTap: () {
                                setState(() {
                                  isEditingLongBreak = true;
                                  isEditingFocus = false;
                                  isEditingShortBreak = false;
                                });
                              },
                              onSubmitted: (value) {
                                final formattedTime = _formatTime(value);
                                if (_validateTimeFormat(formattedTime)) {
                                  _updateTimer(formattedTime, 'Long Break');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid time format. Use MMM:SS.'),
                                    ),
                                  );
                                }
                              },
                              controller: _longBreakTimeController,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Start/Close Button
                    ElevatedButton(
                      onPressed: _toggleTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTimerRunning ? Colors.redAccent : Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                      ),
                      child: Text(
                        isTimerRunning ? 'CLOSE' : 'START',
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Settings Icon in the bottom left corner
            Positioned(
              left: 16,
              bottom: 16,
              child: IconButton(
                icon: Icon(Icons.settings, color: Colors.grey[700], size: 30),
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => SettingsDialog(
                      pomodoroTime: int.parse(focusTime.split(':')[0]),
                      shortBreakTime: int.parse(shortBreakTime.split(':')[0]),
                      longBreakTime: int.parse(longBreakTime.split(':')[0]),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      focusTime = '${result['pomodoroTime']}:00';
                      shortBreakTime = '${result['shortBreakTime']}:00';
                      longBreakTime = '${result['longBreakTime']}:00';
                      currentTimer = focusTime;
                      // Update longBreakInterval if needed
                    });
                  }
                },
              )
            ),
          ],
        ),
      ),
    );
  }
}


// Define Button Colors
final buttonColors = WindowButtonColors(
  iconNormal: Colors.black,
  mouseOver: Colors.blue[200]!,
  mouseDown: Colors.blue[300]!,
  iconMouseOver: Colors.white,
  iconMouseDown: Colors.white,
);

final closeButtonColors = WindowButtonColors(
  mouseOver: Colors.red[300]!,
  mouseDown: Colors.red[400]!,
  iconNormal: Colors.black,
  iconMouseOver: Colors.white,
);

// Window Buttons Widget
class WindowButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

class TimerCard extends StatefulWidget {
  final String title;
  final String time;
  final Color color;
  final bool isEditing;
  final VoidCallback onTap;
  final Function(String) onSubmitted;
  final TextEditingController controller;

  const TimerCard({
    Key? key,
    required this.title,
    required this.time,
    required this.color,
    required this.isEditing,
    required this.onTap,
    required this.onSubmitted,
    required this.controller,
  }) : super(key: key);

  @override
  _TimerCardState createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  bool _isHovered = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      // When the TextFormField loses focus, call the onSubmitted callback
      widget.onSubmitted(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          widget.onTap(); // Call the onTap callback
          _focusNode.requestFocus(); // Request focus for the TextFormField
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 120, // Increased width to accommodate MMM:SS
          height: 90, // Increased height to accommodate the TextFormField
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.color),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
             
              Text(
                      '${widget.time} min', // Always display "min" suffix
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 14,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsDialog extends StatefulWidget {
  final int pomodoroTime;
  final int shortBreakTime;
  final int longBreakTime;

  const SettingsDialog({
    Key? key,
    required this.pomodoroTime,
    required this.shortBreakTime,
    required this.longBreakTime,
  }) : super(key: key);

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late int _pomodoroTime;
  late int _shortBreakTime;
  late int _longBreakTime;

  @override
  void initState() {
    super.initState();
    _pomodoroTime = widget.pomodoroTime;
    _shortBreakTime = widget.shortBreakTime;
    _longBreakTime = widget.longBreakTime;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFFFDF5E6),
      title: const Text(
        'SETTINGS',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeField('Pomodoro', _pomodoroTime, Icons.timer, (value) {
              setState(() {
                _pomodoroTime = value;
              });
            }),
            const SizedBox(height: 16),
            _buildTimeField('Short Break', _shortBreakTime, Icons.coffee, (value) {
              setState(() {
                _shortBreakTime = value;
              });
            }),
            const SizedBox(height: 16),
            _buildTimeField('Long Break', _longBreakTime, Icons.self_improvement, (value) {
              setState(() {
                _longBreakTime = value;
              });
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'pomodoroTime': _pomodoroTime,
              'shortBreakTime': _shortBreakTime,
              'longBreakTime': _longBreakTime,
            });
          },
          child: const Text(
            'Save',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, int value, IconData icon, Function(int) onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      onChanged: (text) {
        final newValue = int.tryParse(text) ?? value;
        onChanged(newValue);
      },
    );
  }
}