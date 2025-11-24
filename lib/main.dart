import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Importurile Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // Fișierul generat de 'flutterfire configure'
import 'package:shared_preferences/shared_preferences.dart';

// Importul pentru Bluetooth
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';

// Import necesar pentru StreamSubscription
import 'dart:async';

// Import pentru permisiuni
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform; // Pentru a verifica dacă e Android

// --- IMPORT NOU PENTRU ROATA DE CULORI ---
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


void main() async {
  // Asigură inițializarea înainte de a rula Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inițializează Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

// ------------------- ROOT WIDGET -------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartHome App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ------------------- PAGINA SIGN UP -------------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _submitSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      // Pasul 1: Creează utilizatorul în Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Pasul 2: Salvează informațiile suplimentare în Firestore
      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'dateOfBirth': _dobController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contul pentru ${_usernameController.text} a fost creat!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'A apărut o eroare la înregistrare.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('A apărut o eroare la scrierea în Firestore: $e'); // Pentru debug
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A apărut o eroare neașteptată la scrierea datelor.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() { _isLoading = false; });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your first name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your last name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please select your date of birth';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a username';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitSignUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------- PAGINA FORGOT PASSWORD -------------------
class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim()
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link-ul de resetare a fost trimis pe email!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'A apărut o eroare.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A apărut o eroare neașteptată.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 16),
              const Text(
                'Introdu adresa de email asociată contului tău pentru a primi un link de resetare.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!value.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendResetLink,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Reset Link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- PAGINA DE LOGIN -------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadUserCredentials();
  }

  // Funcție care verifică dacă există un user salvat
  void _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _usernameController.text = prefs.getString('saved_username') ?? '';
      }
    });
  }


  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      // Pasul 1: Caută în Firestore username-ul
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _usernameController.text.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      // Pasul 2: Extrage email-ul
      final userDoc = query.docs.first;
      final String email = userDoc.data()['email'];

      // Pasul 3: Loghează-te cu email și parolă
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_username', _usernameController.text.trim());
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('saved_username');
      }

      // Pasul 4: Navigare
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'SmartHome Dashboard'),
        ),
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Username sau parolă incorectă.';
      if (e.code == 'user-not-found') {
        errorMessage = 'Utilizatorul nu a fost găsit.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Parolă incorectă.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A apărut o eroare neașteptată.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() { _isLoading = false; });
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgetPasswordPage()),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center( // Centrează formularul
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'SmartHome',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pacifico(
                        fontSize: 56.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 48.0),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a username';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a password';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                        ),
                        const Text('Remember Me'),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: <Widget>[
                          const Expanded(child: Divider(thickness: 1.0)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('or', style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            ),
                          ),
                          const Expanded(child: Divider(thickness: 1.0)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _navigateToSignUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Sign Up'),
                    ),
                    const SizedBox(height: 16.0),
                    TextButton(
                      onPressed: _navigateToForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        textStyle: const TextStyle(fontSize: 16),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------- PAGINA PRINCIPALĂ (CU LOGICĂ DE BUFFER) -------------------
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // --- Variabilele de conexiune ---
  BluetoothDevice? connectedDevice;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;
  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;

  // --- Variabile pentru controlul BLE ---
  BluetoothCharacteristic? writeCharacteristic;
  StreamSubscription? _characteristicSubscription;
  final Guid serviceUuid = Guid("0000ffe0-0000-1000-8000-00805f9b34fb");
  final Guid characteristicUuid = Guid("0000ffe1-0000-1000-8000-00805f9b34fb");

  // --- Variabile de Stare (NOI) ---
  bool _esteBeculAprins = false;
  bool _esteModMiscare = false; // NOU: Senzor Ultrasonic
  bool _esteModLumina = true;   // NOU: Senzor LDR (Adaptiv)
  bool _esteModAlarma = false;

  // --- Variabilă pentru permisiuni ---
  bool _permissionsGranted = false;

  // --- Variabile pentru senzori ---
  String _currentTemperature = "--";
  String _currentHumidity = "--";

  // --- Buffer pentru datele primite ---
  String _bleDataBuffer = "";

  // Variabile pentru setarea temperaturii
  double _targetHeatTemp = 20.0;
  double _targetCoolTemp = 26.0;

  final TextEditingController _heatController = TextEditingController();
  final TextEditingController _coolController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadTempSettings();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      var bluetoothScanStatus = await Permission.bluetoothScan.request();
      var bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      var locationStatus = await Permission.location.request();

      if (bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted && locationStatus.isGranted) {
        setState(() => _permissionsGranted = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permisiuni necesare!'), backgroundColor: Colors.red));
      }
    } else {
      setState(() => _permissionsGranted = true);
    }
  }

  Future<void> _loadTempSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _targetHeatTemp = prefs.getDouble('saved_heat_temp') ?? 20.0;
        _targetCoolTemp = prefs.getDouble('saved_cool_temp') ?? 26.0;
        _heatController.text = _targetHeatTemp.toString();
        _coolController.text = _targetCoolTemp.toString();
      });
    }
  }

  @override
  void dispose() {
    _characteristicSubscription?.cancel();
    connectionSubscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  void _handleConnectionError(dynamic e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red));
    _cleanupConnectionState();
  }

  Future<void> _sendCommand(String command) async {
    if (writeCharacteristic == null) return;
    try {
      List<int> bytes = (command + '\n').codeUnits;
      await writeCharacteristic!.write(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare comanda: $e'), backgroundColor: Colors.red));
    }
  }

  void _onDataReceived(String data) {
    _bleDataBuffer += data;
    while (_bleDataBuffer.contains('\n')) {
      int newlineIndex = _bleDataBuffer.indexOf('\n');
      String completeMessage = _bleDataBuffer.substring(0, newlineIndex);
      _bleDataBuffer = _bleDataBuffer.substring(newlineIndex + 1);
      completeMessage = completeMessage.trim();

      if (completeMessage.isNotEmpty) {
        if (kDebugMode) print("RX: '$completeMessage'");
        _handleCompleteLine(completeMessage);
      }
    }
  }

  // --- PARSER ACTUALIZAT PENTRU 2 MODURI ---
  void _handleCompleteLine(String msg) {

    // 1. Senzori
    if (msg.startsWith("DATA,T=")) {
      try {
        int indexT = msg.indexOf("T=");
        int indexH = msg.indexOf(",H=");
        if (indexT != -1 && indexH != -1) {
          String tempPart = msg.substring(indexT + 2, indexH);
          String humidPart = msg.substring(indexH + 3);

          if (mounted) {
            setState(() {
              _currentTemperature = tempPart;
              _currentHumidity = humidPart;
            });

            // Logica automată termostat (Rulează în app)
            double? currentTempVal = double.tryParse(tempPart);
            if (currentTempVal != null) {
              // Poți adăuga aici logica de termostat dacă vrei să fie controlată de telefon
              // De exemplu: if (currentTempVal < _targetHeatTemp) _sendCommand("HEAT,ON");
            }
          }
        }
      } catch (e) {
        print("Eroare parsare DATA: $e");
      }
    }

    // 2. Status Bec Manual
    else if (msg.startsWith("STATUS,BEC,")) {
      String val = msg.substring(11);
      if (mounted) setState(() => _esteBeculAprins = (val == "1"));
    }

    // 3. Status Moduri -> STATUS,MODS,miscare,lumina,alarma
    else if (msg.startsWith("STATUS,MODS,")) {
      try {
        List<String> parts = msg.split(',');
        // parts[0]="STATUS", parts[1]="MODS", parts[2]="miscare", parts[3]="lumina", parts[4]="alarma"

        if (parts.length >= 5) {
          if (mounted) {
            setState(() {
              // Folosim .trim() pentru a elimina spațiile sau caracterele ascunse (\r)
              _esteModMiscare = (parts[2].trim() == "1");
              _esteModLumina = (parts[3].trim() == "1");
              _esteModAlarma = (parts[4].trim() == "1"); // Aici era problema probabil
            });
            print("Status Actualizat: Alarma este ${_esteModAlarma ? 'ON' : 'OFF'}");
          }
        }
      } catch (e) {
        print("Eroare parsare MODS: $e");
      }
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      // Mărim MTU pentru stabilitate
      try { await device.requestMtu(512); } catch (e) { print("MTU err: $e"); }

      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? bestCharacteristic;

      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.notify) bestCharacteristic = char;
          if (char.uuid.toString().contains("ffe1")) bestCharacteristic = char;
        }
      }

      if (bestCharacteristic == null) throw 'No Notify Characteristic found.';

      setState(() => writeCharacteristic = bestCharacteristic);

      await bestCharacteristic!.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 500));

      await _characteristicSubscription?.cancel();
      _characteristicSubscription = bestCharacteristic.lastValueStream.listen((value) {
        _onDataReceived(String.fromCharCodes(value));
      }, onError: (e) => print("Stream error: $e"));

    } catch (e) {
      _handleConnectionError(e);
    }
  }

  void _cleanupConnectionState() {
    _characteristicSubscription?.cancel();
    connectionSubscription?.cancel();
    _characteristicSubscription = null;
    connectionSubscription = null;
    _bleDataBuffer = "";

    setState(() {
      connectedDevice = null;
      connectionState = BluetoothConnectionState.disconnected;
      writeCharacteristic = null;
      _esteBeculAprins = false;
      _esteModMiscare = false;
      _esteModLumina = true;
      _currentTemperature = "--";
      _currentHumidity = "--";
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();
    setState(() {
      connectedDevice = device;
      connectionState = BluetoothConnectionState.connecting;
    });

    connectionSubscription = device.connectionState.listen((state) {
      setState(() => connectionState = state);
      if (state == BluetoothConnectionState.disconnected) _cleanupConnectionState();
    });

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      if (connectionState == BluetoothConnectionState.connected) {
        await _discoverServices(device);
      }
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  void _disconnectFromDevice() {
    connectedDevice?.disconnect();
    _cleanupConnectionState();
  }

  void scanDevices() {
    if (!_permissionsGranted) {
      _checkPermissions();
      return;
    }
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // --- UI BUILDERS ---

  Widget _buildBluetoothOffUI() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey), Text('Bluetooth Oprit', style: TextStyle(fontSize: 20))]));
  }

  Widget _buildScanUI() {
    return Column(
      children: [
        StreamBuilder<bool>(
          stream: FlutterBluePlus.isScanning,
          initialData: false,
          builder: (c, snapshot) => (snapshot.data ?? false) ? const LinearProgressIndicator() : Container(),
        ),
        Expanded(
          child: StreamBuilder<List<ScanResult>>(
            stream: FlutterBluePlus.scanResults,
            initialData: const [],
            builder: (c, snapshot) {
              final results = snapshot.data ?? [];
              if (results.isEmpty) return const Center(child: Text('Niciun dispozitiv găsit.'));
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  ScanResult r = results[index];
                  String name = r.device.platformName.isNotEmpty ? r.device.platformName : 'Necunoscut';
                  return ListTile(
                    title: Text(name),
                    subtitle: Text(r.device.remoteId.toString()),
                    leading: const Icon(Icons.bluetooth),
                    trailing: Text('${r.rssi} dBm'),
                    onTap: () => _connectToDevice(r.device),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDeviceUI() {
    String deviceName = connectedDevice!.platformName.isNotEmpty ? connectedDevice!.platformName : 'Dispozitiv';
    bool isReady = (connectionState == BluetoothConnectionState.connected) && (writeCharacteristic != null);

    if (!isReady) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Conectat la: $deviceName', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // --- SENZORI ---
            Row(
              children: [
                Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [const Icon(Icons.thermostat, color: Colors.red), Text('$_currentTemperature °C', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))])))),
                const SizedBox(width: 16),
                Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [const Icon(Icons.water_drop, color: Colors.blue), Text('$_currentHumidity %', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))])))),
              ],
            ),

            const SizedBox(height: 16),

            // --- CARD SETĂRI TERMOSTAT ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Setări Termostat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _heatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minim Încălzire (°C)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_fire_department, color: Colors.red)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _coolController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Maxim Răcire (°C)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.ac_unit, color: Colors.blue)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        double? h = double.tryParse(_heatController.text);
                        double? c = double.tryParse(_coolController.text);
                        if (h != null && c != null) {
                          setState(() { _targetHeatTemp = h; _targetCoolTemp = c; });
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setDouble('saved_heat_temp', h);
                          prefs.setDouble('saved_cool_temp', c);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvat!'), backgroundColor: Colors.green));
                          FocusScope.of(context).unfocus();
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Salvează'),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16),

            // --- NOU: SECȚIUNE AUTOMATIZĂRI (2 Moduri) ---
            const Text('Automatizări Casă', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),

            // 1. SWITCH SENZOR MIȘCARE
            Card(
              elevation: 3,
              color: _esteModMiscare ? Colors.green.shade50 : Colors.white,
              child: SwitchListTile(
                title: const Text('Senzor Mișcare (PIR)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Aprinde becul automat la prezență'),
                value: _esteModMiscare,
                activeColor: Colors.green,
                secondary: Icon(Icons.motion_photos_on, color: _esteModMiscare ? Colors.green : Colors.grey),
                onChanged: (val) {
                  // Trimitem comanda
                  _sendCommand(val ? "MOD,MISCARE,ON" : "MOD,MISCARE,OFF");
                  // Updatam UI optimist
                  setState(() => _esteModMiscare = val);
                },
              ),
            ),

            const SizedBox(height: 8),

            // 2. SWITCH ILUMINAT ADAPTIV
            Card(
              elevation: 3,
              color: _esteModLumina ? Colors.blue.shade50 : Colors.white,
              child: SwitchListTile(
                title: const Text('Iluminat Adaptiv (LDR)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Reglează intensitatea în funcție de lumina din cameră'),
                value: _esteModLumina,
                activeColor: Colors.blue,
                secondary: Icon(Icons.brightness_auto, color: _esteModLumina ? Colors.blue : Colors.grey),
                onChanged: (val) {
                  _sendCommand(val ? "MOD,LUMINA,ON" : "MOD,LUMINA,OFF");
                  setState(() => _esteModLumina = val);
                },
              ),
            ),

            const SizedBox(height: 24),

            // 3. SWITCH ALARMĂ (NOU)
            Card(
              elevation: 3,
              // O facem roșiatică dacă e armată, ca să iasă în evidență
              color: _esteModAlarma ? Colors.red.shade50 : Colors.white,
              child: SwitchListTile(
                title: const Text('Sistem Alarmă', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Monitorizare intruși (Ultrasonic)'),
                value: _esteModAlarma,
                activeColor: Colors.red,
                secondary: Icon(Icons.security, color: _esteModAlarma ? Colors.red : Colors.grey),
                onChanged: (val) {
                  // Trimitem comanda specifică pentru Alarmă
                  _sendCommand(val ? "ALARMA,ARM" : "ALARMA,DISARM");
                  setState(() => _esteModAlarma = val);
                },
              ),
            ),

            const SizedBox(height: 24),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Securitate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(), // Folosim controller temporar sau declară unul sus
                            decoration: const InputDecoration(
                              labelText: 'Parolă nouă',
                              hintText: 'ex: 1234',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (val) {
                              if(val.isNotEmpty) {
                                _sendCommand("PASS,$val");
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parolă actualizată!')));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: () {
                            // Notă: Pentru un cod complet curat, declară un controller sus în clasă:
                            // final _passController = TextEditingController();
                            // și folosește-l aici.
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scrie parola și apasă Enter pe tastatură')));
                          },
                        )
                      ],
                    ),
                    const Text('Tastează codul + # pe tastatura fizică pentru a arma/dezarma.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- CONTROL MANUAL ---
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _esteModMiscare ? Colors.grey.shade200 : (_esteBeculAprins ? Colors.yellow.shade100 : Colors.white),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: SwitchListTile(
                title: Text(_esteBeculAprins ? 'Bec APRINS' : 'Bec STINS', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_esteModMiscare ? 'Dezactivat de Senzorul de Mișcare' : 'Control Manual'),
                value: _esteBeculAprins,
                // Dezactivăm butonul dacă Senzorul de Mișcare e pornit (pentru a evita conflictul)
                onChanged: _esteModMiscare ? null : (val) {
                  _sendCommand(val ? "BEC,ON" : "BEC,OFF");
                  setState(() => _esteBeculAprins = val);
                },
                secondary: Icon(Icons.lightbulb, color: _esteBeculAprins ? Colors.orange : Colors.grey),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1.0),

            // --- BUTON RGB ---
            ElevatedButton.icon(
              icon: const Icon(Icons.palette),
              label: const Text('Control LED RGB'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RgbControlPage(sendCommand: _sendCommand))),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: _disconnectFromDevice,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Deconectare')
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _disconnectFromDevice();
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginPage()));
            },
          )
        ],
      ),
      body: StreamBuilder<BluetoothAdapterState>(
        stream: FlutterBluePlus.adapterState,
        initialData: BluetoothAdapterState.unknown,
        builder: (c, snapshot) {
          if (snapshot.data != BluetoothAdapterState.on) return _buildBluetoothOffUI();
          if (connectedDevice != null) return _buildConnectedDeviceUI();
          return _buildScanUI();
        },
      ),
      floatingActionButton: StreamBuilder<BluetoothAdapterState>(
        stream: FlutterBluePlus.adapterState,
        initialData: BluetoothAdapterState.unknown,
        builder: (c, snapshot) => (snapshot.data == BluetoothAdapterState.on && connectedDevice == null)
            ? FloatingActionButton(onPressed: () { if(FlutterBluePlus.isScanningNow) stopScan(); else scanDevices(); }, child: Icon(FlutterBluePlus.isScanningNow ? Icons.stop : Icons.search))
            : Container(),
      ),
    );
  }
}

// ------------------- PAGINA LED RGB -------------------
class RgbControlPage extends StatefulWidget {
  final Function(String) sendCommand;
  const RgbControlPage({super.key, required this.sendCommand});

  @override
  State<RgbControlPage> createState() => _RgbControlPageState();
}

class _RgbControlPageState extends State<RgbControlPage> {
  Color _currentColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control LED RGB')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColorPicker(
                pickerColor: _currentColor,
                onColorChanged: (c) => setState(() => _currentColor = c),
                pickerAreaHeightPercent: 0.8,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => widget.sendCommand("RGB,SET,${_currentColor.red},${_currentColor.green},${_currentColor.blue}"),
                child: const Text('Setează Culoarea'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const Text('Presetări', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  ElevatedButton(onPressed: () => widget.sendCommand("RGB,PRESET,ZI"), child: const Text('Zi')),
                  ElevatedButton(onPressed: () => widget.sendCommand("RGB,PRESET,CALD"), child: const Text('Cald')),
                  ElevatedButton(onPressed: () => widget.sendCommand("RGB,PRESET,RECE"), child: const Text('Rece')),
                  ElevatedButton(onPressed: () => widget.sendCommand("RGB,PRESET,CINEMA"), child: const Text('Cinema')),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => widget.sendCommand("RGB,OFF"),
                child: const Text('Stinge LED RGB'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- PAGINA RESET PASSWORD -------------------
class ResetPasswordPage extends StatefulWidget {
  final String oobCode;
  const ResetPasswordPage({super.key, required this.oobCode});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _loading = false;

  void _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.confirmPasswordReset(code: widget.oobCode, newPassword: _passCtrl.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parolă schimbată!')));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setează Parola Nouă')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Noua Parolă')),
            TextFormField(controller: _confCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmă')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _confirm, child: const Text('Salvează')),
          ]),
        ),
      ),
    );
  }
}