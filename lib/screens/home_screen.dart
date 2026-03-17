import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';
import 'contact_screen.dart';
import '../models/contact_model.dart';
import '../models/sos_history_model.dart';
import 'history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  StreamSubscription? _sensorSub;
  double lastX = 0, lastY = 0, lastZ = 0;

  bool isCountingDown = false;
  int countdown = 5;
  Timer? countdownTimer;

  late stt.SpeechToText speech;

bool isListening = false;

String helpCommand = "help";
String smsCommand = "sms";
String callCommand = "call";

  bool showSettings = false;
  bool isTapCountdownEnabled = true;
  bool isShakeCountdownEnabled = false;
  bool isShakeSmsMode = true; 

  List<SOSHistory> sosHistoryList = [];


 List<EmergencyContact> emergencyContacts = [
  EmergencyContact(number: "8754932144", isPrimary: true),
];
Future<void> loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    isShakeSmsMode =
        prefs.getBool("isShakeSmsMode") ?? true;

    isTapCountdownEnabled =
        prefs.getBool("isTapCountdownEnabled") ?? true;

    isShakeCountdownEnabled =
        prefs.getBool("isShakeCountdownEnabled") ?? false;
  });
print("Loaded Tap Countdown: $isTapCountdownEnabled");
}
Future<void> saveSettings() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(
      "isShakeSmsMode", isShakeSmsMode);

  await prefs.setBool(
      "isTapCountdownEnabled",
      isTapCountdownEnabled);

  await prefs.setBool(
      "isShakeCountdownEnabled",
      isShakeCountdownEnabled);
print("Saved Tap Countdown: $isTapCountdownEnabled");
}
Future<void> saveContacts() async {
  final prefs = await SharedPreferences.getInstance();

  List<String> contactList = emergencyContacts.map((c) {
    return "${c.number}|${c.isPrimary}";
  }).toList();

  await prefs.setStringList("contacts", contactList);
}
Future<void> saveHistory() async {
  final prefs = await SharedPreferences.getInstance();

  List<String> historyList = sosHistoryList.map((h) {
    return "${h.action}|${h.location}|${h.time.toIso8601String()}";
  }).toList();

  await prefs.setStringList("sos_history", historyList);
}
Future<void> loadHistory() async {
  final prefs = await SharedPreferences.getInstance();

  List<String>? savedHistory = prefs.getStringList("sos_history");

  if (savedHistory != null) {
    sosHistoryList = savedHistory.map((h) {
      List<String> parts = h.split("|");

      return SOSHistory(
        action: parts[0],
        location: parts[1],
        time: DateTime.parse(parts[2]),
      );
    }).toList();
  }
}
Future<void> loadContacts() async {
  final prefs = await SharedPreferences.getInstance();

  List<String>? savedContacts = prefs.getStringList("contacts");

  if (savedContacts != null) {
    emergencyContacts = savedContacts.map((c) {
      List<String> parts = c.split("|");

      return EmergencyContact(
        number: parts[0],
        isPrimary: parts[1] == "true",
      );
    }).toList();
  }
}
@override
void initState() {
  super.initState();
  speech = stt.SpeechToText();
loadSettings();
loadContacts();
 loadHistory();
  _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  _sensorSub = accelerometerEvents.listen((event) {
    double delta = sqrt(
      pow(event.x - lastX, 2) +
      pow(event.y - lastY, 2) +
      pow(event.z - lastZ, 2),
    );
if (delta > 15) {
  if (isShakeCountdownEnabled) {
    startCountdown();
  } else {
    if (isShakeSmsMode) {
      sendSmsToAll();
    } else {
      callPrimary();
    }
  }
}

    lastX = event.x;
    lastY = event.y;
    lastZ = event.z;
  });
}

  @override
  void dispose() {
    _controller.dispose();
    _sensorSub?.cancel();
    super.dispose();
  }

  void startCountdown() {
    if (isCountingDown) return;

    setState(() {
      isCountingDown = true;
      countdown = 5;
    });

    countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });

  if (countdown == 0) {
  timer.cancel();
  setState(() {
    isCountingDown = false;
  });

  if (isShakeSmsMode) {
    sendSmsToAll();
  } else {
    callPrimary();
  }
}
    });
  }

Future<void> makePhoneCall(String phone) async {
  final Uri callUri = Uri(
    scheme: 'tel',
    path: phone,
  );

  await launchUrl(
    callUri,
    mode: LaunchMode.externalApplication,
  );
}
Future<void> sendSmsToAll() async {
   ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("🎤 Emergency audio recording started"),
      duration: Duration(seconds: 2),
    ),
  );
String? audioPath = await AudioService.startAudioRecording();

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("✅ Emergency audio saved"),
    duration: Duration(seconds: 2),
  ),
);
  if (emergencyContacts.isEmpty) return;

  LocationPermission permission =
      await Geolocator.requestPermission();

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) return;

  Position pos = await Geolocator.getCurrentPosition();

  String mapLink =
      "https://www.google.com/maps?q=${pos.latitude},${pos.longitude}";

  String msg =
      "🚨 SOS! I need help!\nLocation: $mapLink";

  String numbers =
      emergencyContacts.map((e) => e.number).join(',');

  final Uri smsUri = Uri(
    scheme: 'sms',
    path: numbers,
    queryParameters: {'body': msg},
  );

  await launchUrl(
    smsUri,
    mode: LaunchMode.externalApplication,
  );
  sosHistoryList.add(
  SOSHistory(
    action: "SMS",
    location: mapLink,
    time: DateTime.now(),
  ),
);
saveHistory();
}
Future<void> callPrimary() async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("🎤 Emergency audio recording started"),
      duration: Duration(seconds: 2),
    ),
  );
  String? audioPath =  await AudioService.startAudioRecording();
   if (audioPath != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Emergency audio saved"),
        duration: Duration(seconds: 2),
      ),
    );
  }
 if (emergencyContacts.isEmpty) return;

  EmergencyContact primary =
      emergencyContacts.firstWhere((e) => e.isPrimary);

  String location = "Call Triggered";

  sosHistoryList.add(
    SOSHistory(
      action: "CALL",
      location: location,
      time: DateTime.now(),
    ),
  );

  saveHistory();

  final Uri callUri = Uri(
    scheme: 'tel',
    path: primary.number,
  );

  await launchUrl(
    callUri,
    mode: LaunchMode.externalApplication,
  );
}

void startVoiceListening() async {

  bool available = await speech.initialize();

  if (available) {

    setState(() {
      isListening = true;
    });

    speech.listen(
      listenFor: const Duration(seconds: 5),

      onResult: (result) {

        String words = result.recognizedWords.toLowerCase();

        if (words.contains(helpCommand)) {
          sendSmsToAll();
          callPrimary();
        }

        else if (words.contains(smsCommand)) {
          sendSmsToAll();
        }

        else if (words.contains(callCommand)) {
          callPrimary();
        }

      },
    );
    Future.delayed(const Duration(seconds: 5), () {
  speech.stop();
  setState(() {
    isListening = false;
  });
});

  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBEE),
appBar: AppBar(
  title: const Text("Women Safety SOS"),
  backgroundColor: Colors.pink,
  actions: [
    IconButton(
      icon: const Icon(Icons.contact_phone),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContactScreen(
              contacts: emergencyContacts,
              saveContacts: saveContacts,
)
          ),
        );
      },
    ),
  ],
),
      body: Stack(
        children: [

          Center(
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.1)
                  .animate(_controller),
              child: GestureDetector(
                onTap: () {
                  if (isTapCountdownEnabled) {
                    startCountdown();
                  } else {
                    if (isShakeSmsMode) {
                      callPrimary();
                    } else {
                      sendSmsToAll();
                    }
                  }
                },
               
            child: Container(
              width: 220,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text(
                  "EMERGENCY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
              ),
            ),
          ),
          // 🎤 Voice Command Button
Positioned(
  bottom: 160,
  right: 20,
  child: FloatingActionButton(
    backgroundColor: Colors.orange,
    onPressed: startVoiceListening,
    child: Icon(
  isListening ? Icons.mic : Icons.mic_none,
),
  ),
),

          if (isCountingDown)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Sending SOS in $countdown",
                          style:
                              const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            countdownTimer?.cancel();
                            setState(() {
                              isCountingDown = false;
                            });
                          },
                          child: const Text("Cancel"),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.pink,
              onPressed: () {
                setState(() {
                  showSettings = true;
                });
              },
              child: const Icon(Icons.settings),
            ),
          ),

        if (showSettings)
  Container(
    color: Colors.black54,
    child: Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

  // 🔹 MAIN TITLE
  const Text(
    "Safety Settings",
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 20),
const SizedBox(height: 20),

// =============================
// 🔹 TIMER SETTINGS SECTION
// =============================

const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Timer Settings",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    ),
  ),
),

const SizedBox(height: 10),

Card(
  child: CheckboxListTile(
    title: const Text("Enable Countdown for Tap"),
    subtitle: const Text("Delay action when SOS button is tapped"),
    value: isTapCountdownEnabled,
    onChanged: (value) {
      setState(() {
        isTapCountdownEnabled = value!;
      });
      saveSettings();
    },
  ),
),

Card(
  child: CheckboxListTile(
    title: const Text("Enable Countdown for Shake"),
    subtitle: const Text("Delay action when device is shaken"),
    value: isShakeCountdownEnabled,
    onChanged: (value) {
      setState(() {
        isShakeCountdownEnabled = value!;
      });
      saveSettings();
    },
  ),
),
  // =============================
  // 🔹 TRIGGER MODE SECTION
  // =============================

  const Align(
    alignment: Alignment.centerLeft,
    child: Text(
      "Trigger Mode",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    ),
  ),

  const SizedBox(height: 10),

  Card(
    child: RadioListTile<bool>(
      title: const Text("Mode A"),
      subtitle: const Text("Shake → SMS | Tap → Call"),
      value: true,
      groupValue: isShakeSmsMode,
      onChanged: (value) {
        setState(() {
          isShakeSmsMode = value!;
        });
      },
    ),
  ),

  Card(
    child: RadioListTile<bool>(
      title: const Text("Mode B"),
      subtitle: const Text("Shake → Call | Tap → SMS"),
      value: false,
      groupValue: isShakeSmsMode,
     onChanged: (value) {
  setState(() {
    isShakeSmsMode = value!;
  });
  saveSettings();
},
    ),
  ),

 // Action Settings checkbox here...
const SizedBox(height: 20),

// =============================
// 🔹 MIC SETTINGS SECTION
// =============================

const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Mic Settings",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    ),
  ),
),

const SizedBox(height: 10),

Card(
  child: Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [

        TextField(
          decoration: const InputDecoration(
            labelText: "Help Command",
          ),
          controller: TextEditingController(text: helpCommand),
          onChanged: (value) {
            helpCommand = value.toLowerCase();
          },
        ),

        const SizedBox(height: 10),

        TextField(
          decoration: const InputDecoration(
            labelText: "SMS Command",
          ),
          controller: TextEditingController(text: smsCommand),
          onChanged: (value) {
            smsCommand = value.toLowerCase();
          },
        ),

        const SizedBox(height: 10),

        TextField(
          decoration: const InputDecoration(
            labelText: "Call Command",
          ),
          controller: TextEditingController(text: callCommand),
          onChanged: (value) {
            callCommand = value.toLowerCase();
          },
        ),

        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset Commands",
            onPressed: () {
              setState(() {
                helpCommand = "help";
                smsCommand = "sms";
                callCommand = "call";
              });
            },
          ),
        ),
      ],
    ),
  ),
),

// =============================
// 🔹 APP DATA SECTION
// =============================

const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "App Data",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    ),
  ),
),

const SizedBox(height: 10),

Card(
  child: ListTile(
    leading: const Icon(Icons.history, color: Colors.pink),
    title: const Text("SOS History"),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {
      setState(() {
        showSettings = false;
      });

     Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => HistoryScreen(
      historyList: sosHistoryList,
      saveHistory: saveHistory,
    ),
  ),
);
    },
  ),
),

// Close Button
ElevatedButton(
  onPressed: () {
    setState(() {
      showSettings = false;
    });
  },
  child: const Text("Close"),
),
           ],
            ),
          ),
        ),
      ),
    ),
  ),

        ],
      ),
    );
  }
}