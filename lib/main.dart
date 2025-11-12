import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Importurile Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // Fișierul generat de 'flutterfire configure'

// Importul pentru Bluetooth
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';

// Import necesar pentru StreamSubscription
import 'dart:async';

// Import pentru permisiuni
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform; // Pentru a verifica dacă e Android


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

// ------------------- PAGINA PRINCIPALĂ (CU TOATE CORECȚIILE) -------------------
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
  StreamSubscription? _characteristicSubscription; // Pentru a asculta date
  final Guid serviceUuid = Guid("0000ffe0-0000-1000-8000-00805f9b34fb");
  final Guid characteristicUuid = Guid("0000ffe1-0000-1000-8000-00805f9b34fb");

  // --- Variabile de Stare (Becul ȘI Modul) ---
  bool _esteBeculAprins = false;
  bool _esteModulAuto = false;

  // --- Variabilă pentru a ști dacă permisiunile sunt gata ---
  bool _permissionsGranted = false;


  // --- Funcție care rulează la început ---
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // --- Funcție care cere permisiunile ---
  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      var bluetoothScanStatus = await Permission.bluetoothScan.request();
      var bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      var locationStatus = await Permission.location.request();

      if (bluetoothScanStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          locationStatus.isGranted) {
        setState(() {
          _permissionsGranted = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisiunile de Bluetooth și Locație sunt necesare pentru a scana.'),
              backgroundColor: Colors.red,
            )
        );
      }
    } else {
      // Pentru iOS, presupunem că sunt ok deocamdată
      setState(() {
        _permissionsGranted = true;
      });
    }
  }


  @override
  void dispose() {
    // Anulăm abonamentele și ne deconectăm
    _characteristicSubscription?.cancel();
    connectionSubscription?.cancel();
    connectedDevice?.disconnect(); // Trimitem comanda de deconectare
    super.dispose();
  }

  void _handleConnectionError(dynamic e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la conectare: $e'), backgroundColor: Colors.red)
    );
    _cleanupConnectionState(); // Curățăm starea
  }

  // --- Funcția de trimitere comenzi (CU CORECȚIA PENTRU EROARE) ---
  Future<void> _sendCommand(String command) async {
    if (writeCharacteristic == null) {
      print('Caracteristica de scris nu e gata.');
      return;
    }
    try {
      List<int> bytes = (command + '\n').codeUnits;

      // --- CORECȚIE AICI ---
      // Am scos ", withoutResponse: true"
      await writeCharacteristic!.write(bytes);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la trimiterea comenzii: $e'), backgroundColor: Colors.red)
      );
    }
  }

  // --- Funcție care procesează datele primite de la Arduino ---
  void _handleArduinoData(String data) {
    if (data.isEmpty) return;

    print("Primit de la Arduino: $data"); // PENTRU DEBUG

    // Uneori Arduino poate trimite mai multe mesaje odată (ex: "STATUS,BEC,1\nSTATUS,MOD,0")
    List<String> messages = data.split(RegExp(r'[\r\n]+'));

    // Folosim un 'for' în caz că vin mesaje lipite
    for (var msg in messages) {
      if (msg.isEmpty) continue;

      if (msg.startsWith("STATUS,BEC,")) {
        String val = msg.substring(11); // Ia ce e după "STATUS,BEC,"
        setState(() { _esteBeculAprins = (val == "1"); });
      }
      else if (msg.startsWith("STATUS,MOD,")) {
        String val = msg.substring(11); // Ia ce e după "STATUS,MOD,"
        setState(() { _esteModulAuto = (val == "1"); });
      }
    }
  }

  // --- Funcția de descoperire servicii ---
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      // Căutăm serviciul nostru specific (FFE0)
      BluetoothService? targetService;
      for (var service in services) {
        if (service.uuid == serviceUuid) {
          targetService = service;
          break;
        }
      }
      if (targetService == null) throw 'Serviciul BLE (FFE0) nu a fost găsit.';

      // Căutăm caracteristica noastră specifică (FFE1)
      BluetoothCharacteristic? targetCharacteristic;
      for (var char in targetService.characteristics) {
        if (char.uuid == characteristicUuid) {
          targetCharacteristic = char;
          break;
        }
      }
      if (targetCharacteristic == null) throw 'Caracteristica BLE (FFE1) nu a fost găsită.';

      setState(() {
        writeCharacteristic = targetCharacteristic;
      });

      // Abonează-te la notificări
      final canNotify = targetCharacteristic.properties.notify;
      if (canNotify) {
        await targetCharacteristic.setNotifyValue(true);

        _characteristicSubscription?.cancel(); // Anulează orice ascultare veche

        _characteristicSubscription = targetCharacteristic.lastValueStream.listen((value) {
          String dataDeLaArduino = String.fromCharCodes(value);
          _handleArduinoData(dataDeLaArduino.trim());
        }, onError: (e) {
          print("Eroare la ascultare: $e");
          _handleConnectionError("Eroare la ascultarea datelor BLE.");
        });
      }

    } catch (e) {
      _handleConnectionError(e);
    }
  }

  // --- Funcție separată pentru curățarea stării ---
  void _cleanupConnectionState() {
    _characteristicSubscription?.cancel();
    connectionSubscription?.cancel();
    _characteristicSubscription = null;
    connectionSubscription = null;
    setState(() {
      connectedDevice = null;
      connectionState = BluetoothConnectionState.disconnected;
      writeCharacteristic = null;
      _esteBeculAprins = false;
      _esteModulAuto = false;
    });
  }

  // --- Funcția de CONECTARE ---
  void _connectToDevice(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();
    setState(() {
      connectedDevice = device;
      connectionState = BluetoothConnectionState.connecting;
      writeCharacteristic = null;
    });

    connectionSubscription = device.connectionState.listen((state) {
      setState(() { connectionState = state; });
      if (state == BluetoothConnectionState.disconnected) {
        _cleanupConnectionState();
      }
    }, onError: (e) {
      _handleConnectionError(e);
    });

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      await Future.delayed(const Duration(milliseconds: 500)); // Pauză de stabilizare

      if (connectionState == BluetoothConnectionState.connected) {
        await _discoverServices(device);
      }
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  // --- Funcția de DECONECTARE ---
  void _disconnectFromDevice() {
    connectedDevice?.disconnect();
    _cleanupConnectionState();
  }

  // --- Funcțiile de Scanare ---
  void scanDevices() {
    if (!_permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acordă permisiunile de Locație și Bluetooth mai întâi.'),
            backgroundColor: Colors.red,
          )
      );
      _checkPermissions(); // Cere-le din nou
      return;
    }
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }
  void stopScan() { FlutterBluePlus.stopScan(); }

  // --- Widget-ul: Interfața Bluetooth OPRIT ---
  Widget _buildBluetoothOffUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          const Text('Bluetooth este Oprit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Te rog pornește Bluetooth-ul.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Widget-ul: Interfața de SCANARE ---
  Widget _buildScanUI() {
    if (!_permissionsGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              const Text('Permisiuni Necsare', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Aplicația are nevoie de permisiuni de "Locație" și "Dispozitive din apropiere" pentru a scana după module BLE.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _checkPermissions,
                  child: const Text('Acordă Permisiunile')
              )
            ],
          ),
        ),
      );
    }

    // Altfel, arată interfața de scanare normală
    return Column(
      children: [
        StreamBuilder<bool>(
          stream: FlutterBluePlus.isScanning,
          initialData: false,
          builder: (c, snapshot) {
            final isScanning = snapshot.data ?? false;
            return isScanning ? const LinearProgressIndicator() : Container();
          },
        ),
        Expanded(
          child: StreamBuilder<List<ScanResult>>(
            stream: FlutterBluePlus.scanResults,
            initialData: const [],
            builder: (c, snapshot) {
              final results = snapshot.data ?? [];
              if (results.isEmpty) {
                return const Center(
                  child: Text('Niciun dispozitiv BLE găsit. Apasă butonul pentru a scana.'),
                );
              }
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  ScanResult r = results[index];
                  String deviceName = r.device.platformName.isNotEmpty
                      ? r.device.platformName
                      : 'Dispozitiv Necunoscut';

                  return ListTile(
                    title: Text(deviceName),
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

  // --- Widget-ul: Interfața pentru dispozitivul CONECTAT ---
  Widget _buildConnectedDeviceUI() {
    String deviceName = connectedDevice!.platformName.isNotEmpty
        ? connectedDevice!.platformName
        : 'Dispozitiv Necunoscut';

    bool isConnecting = (connectionState == BluetoothConnectionState.connecting);
    bool isReady = (connectionState == BluetoothConnectionState.connected) && (writeCharacteristic != null);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(isReady ? 'Conectat la:' : (isConnecting ? 'Se conectează la:' : 'Eroare la conectare'),
                style: const TextStyle(fontSize: 22), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(deviceName,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 24),

            if (isConnecting)
              const Center(child: CircularProgressIndicator()),

            if (connectionState == BluetoothConnectionState.connected && writeCharacteristic == null && !isConnecting)
              const Center(
                child: Text('Conectat, dar nu am putut găsi serviciul de control (FFE1).',
                    style: TextStyle(fontSize: 16, color: Colors.red), textAlign: TextAlign.center),
              ),

            // ----- AICI ESTE PANOU DE CONTROL -----
            if (isReady)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Panou de Control:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  // --- Controlul Modului Auto ---
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _esteModulAuto ? Colors.blue.shade100 : Colors.grey.shade200,
                    ),
                    child: SwitchListTile(
                      title: Text(
                        _esteModulAuto ? 'Mod Auto Activat' : 'Mod Auto Oprit',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Controlat de senzor/butonul fizic'),
                      value: _esteModulAuto,

                      // --- CORECȚIE AICI (Fără setState) ---
                      onChanged: (newValue) {
                        if (newValue) {
                          _sendCommand("MOD,AUTO,ON");
                        } else {
                          _sendCommand("MOD,AUTO,OFF");
                        }
                        // AM ȘTERS setState de aici
                      },

                      secondary: Icon(
                        _esteModulAuto ? Icons.sensors : Icons.sensors_off,
                        size: 40,
                        color: _esteModulAuto ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Controlul Manual ---
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _esteBeculAprins ? Colors.yellow.shade100 : Colors.grey.shade200,
                      border: Border.all(
                          color: _esteModulAuto ? Colors.grey.shade400 : Colors.transparent,
                          width: 1
                      ),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        _esteBeculAprins ? 'Becul este Aprins' : 'Becul este Stins',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _esteModulAuto ? Colors.grey.shade600 : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        _esteModulAuto ? 'Dezactivați Modul Auto pentru control' : 'Control manual',
                        style: TextStyle(
                          color: _esteModulAuto ? Colors.grey.shade600 : Colors.black54,
                        ),
                      ),
                      value: _esteBeculAprins,

                      // --- CORECȚIE AICI (Fără setState) ---
                      onChanged: _esteModulAuto ? null : (newValue) {
                        if (newValue) {
                          _sendCommand("BEC,ON");
                        } else {
                          _sendCommand("BEC,OFF");
                        }
                        // AM ȘTERS setState de aici
                      },

                      secondary: Icon(
                        _esteBeculAprins ? Icons.lightbulb : Icons.lightbulb_outline,
                        size: 40,
                        color: _esteBeculAprins ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 48),

            // Butonul de deconectare
            ElevatedButton(
              onPressed: _disconnectFromDevice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Deconectare', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget-ul: Butonul de scanare ---
  Widget _buildScanButton() {
    return StreamBuilder<bool>(
      stream: FlutterBluePlus.isScanning,
      initialData: false,
      builder: (c, snapshot) {
        final isScanning = snapshot.data ?? false;
        if (isScanning) {
          return FloatingActionButton(
            onPressed: stopScan,
            tooltip: 'Stop Scan',
            backgroundColor: Colors.red,
            child: const Icon(Icons.stop),
          );
        } else {
          return FloatingActionButton(
            onPressed: scanDevices,
            tooltip: 'Start Scan',
            child: const Icon(Icons.search),
          );
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              if (connectedDevice != null) {
                _disconnectFromDevice();
              }
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          )
        ],
      ),

      // --- Corpul paginii ---
      body: StreamBuilder<BluetoothAdapterState>(
        stream: FlutterBluePlus.adapterState,
        initialData: BluetoothAdapterState.unknown,
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state != BluetoothAdapterState.on) {
            return _buildBluetoothOffUI();
          }
          if (connectedDevice != null) {
            return _buildConnectedDeviceUI();
          }
          return _buildScanUI();
        },
      ),

      // --- Butonul de scanare ---
      floatingActionButton: StreamBuilder<BluetoothAdapterState>(
        stream: FlutterBluePlus.adapterState,
        initialData: BluetoothAdapterState.unknown,
        builder: (context, snapshot) {
          if (snapshot.data == BluetoothAdapterState.on && connectedDevice == null) {
            return _buildScanButton();
          }
          return Container();
        },
      ),
    );
  }
}

// ------------------- PAGINA RESET PASSWORD (Pentru Deep Link) -------------------
class ResetPasswordPage extends StatefulWidget {
  final String oobCode;
  const ResetPasswordPage({super.key, required this.oobCode});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _confirmReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      // Confirmă noua parolă folosind codul din link
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: _newPasswordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parola a fost schimbată! Te poți loga acum.'),
          backgroundColor: Colors.green,
        ),
      );

      // Trimite utilizatorul la pagina de login și șterge istoricul
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );

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
        title: const Text('Setează Parola Nouă'),
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
                'Introdu noua ta parolă. Aceasta trebuie să aibă cel puțin 6 caractere.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Parolă Nouă',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Te rog introdu o parolă';
                  if (value.length < 6) return 'Parola trebuie să aibă minim 6 caractere';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmă Parola Nouă',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Te rog confirmă parola';
                  if (value != _newPasswordController.text) return 'Parolele nu se potrivesc';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmReset,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvează Parola'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}