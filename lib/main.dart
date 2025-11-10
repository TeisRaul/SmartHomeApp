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

// ------------------- PAGINA PRINCIPALĂ (MODIFICATĂ PENTRU CONECTARE BLUETOOTH) -------------------
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // --- Variabile noi pentru a gestiona starea conexiunii ---
  BluetoothDevice? connectedDevice;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;
  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;

  @override
  void dispose() {
    // Anulează abonamentul și deconectează-te la părăsirea paginii
    connectionSubscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  // --- Funcție nouă pentru a gestiona erorile de conectare ---
  void _handleConnectionError(dynamic e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la conectare: $e'), backgroundColor: Colors.red)
    );
    _disconnectFromDevice(); // Resetează interfața
  }

  // --- Funcție nouă pentru a te CONECTA la un dispozitiv ---
// În interiorul clasei _MyHomePageState

// --- Funcția ta _connectToDevice, rescrisă ---
  void _connectToDevice(BluetoothDevice device) async { // <-- PASUL 1: Am adăugat 'async'
    // Oprește scanarea
    FlutterBluePlus.stopScan();

    // Setează starea imediat pentru a afișa UI-ul de "conectare..."
    setState(() {
      connectedDevice = device;
      connectionState = BluetoothConnectionState.connecting;
    });

    // Abonează-te la schimbările de stare ale conexiunii
    connectionSubscription = device.connectionState.listen((state) {
      setState(() {
        connectionState = state;
      });
      if (state == BluetoothConnectionState.disconnected) {
        // Dispozitivul s-a deconectat singur
        _disconnectFromDevice(); // Curăță starea
      }
    }, onError: (e) {
      _handleConnectionError(e);
    });

    // --- PASUL 2: Aici este blocul de cod rescris ---
    // Am înlocuit .catchError() cu un bloc try/catch
    try {
      // Încearcă să te conectezi (cu un timeout de 15 secunde)
      await device.connect(timeout: const Duration(seconds: 15));
    } catch (e) {
      // Dacă apare orice eroare în timpul conectării, o prindem
      _handleConnectionError(e);
    }
  }

  // --- Funcție nouă pentru a te DECONECTA de la un dispozitiv ---
  void _disconnectFromDevice() {
    connectionSubscription?.cancel();
    connectionSubscription = null;
    connectedDevice?.disconnect();
    setState(() {
      connectedDevice = null;
      connectionState = BluetoothConnectionState.disconnected;
    });
  }

  // --- Funcție nouă pentru a ÎNCEPE scanarea ---
  void scanDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  // --- Funcție nouă pentru a OPRI scanarea ---
  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // --- Widget nou: Interfața pentru când Bluetooth este OPRIT ---
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
            'Te rog pornește Bluetooth-ul și Locația\npentru a scana după dispozitive.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Widget nou: Interfața pentru a SCANA dispozitive ---
  Widget _buildScanUI() {
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
                    // --- MODIFICARE AICI: Apelează funcția de conectare la apăsare ---
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

  // --- Widget nou: Interfața pentru dispozitivul CONECTAT ---
  Widget _buildConnectedDeviceUI() {
    String deviceName = connectedDevice!.platformName.isNotEmpty
        ? connectedDevice!.platformName
        : 'Dispozitiv Necunoscut';

    bool isConnected = (connectionState == BluetoothConnectionState.connected);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(isConnected ? 'Conectat la:' : 'Se conectează la:',
                style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(deviceName,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            // Arată un indicator de progres doar în timpul conectării
            if (connectionState == BluetoothConnectionState.connecting)
              const CircularProgressIndicator(),

            // Arată un mesaj de succes la conectare
            if (isConnected)
              const Text('Dispozitiv conectat cu succes!',
                  style: TextStyle(fontSize: 18, color: Colors.green)),

            const SizedBox(height: 32),

            // Butonul de deconectare
            ElevatedButton(
              onPressed: _disconnectFromDevice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Deconectare', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget nou: Butonul de scanare (separat) ---
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
              // Verifică dacă e conectat și se deconectează înainte de logout
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

      // --- MODIFICARE AICI: Corpul paginii se schimbă în funcție de stare ---
      body: StreamBuilder<BluetoothAdapterState>(
        stream: FlutterBluePlus.adapterState,
        initialData: BluetoothAdapterState.unknown,
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state != BluetoothAdapterState.on) {
            // 1. Dacă Bluetooth e OPRIT, arată ecranul de eroare
            return _buildBluetoothOffUI();
          }
          if (connectedDevice != null) {
            // 2. Dacă un dispozitiv e selectat/conectat, arată ecranul de conectare
            return _buildConnectedDeviceUI();
          }
          // 3. Altfel, arată ecranul de scanare
          return _buildScanUI();
        },
      ),

      // --- MODIFICARE AICI: Arată butonul de scanare doar dacă nu ești conectat ---
      floatingActionButton: StreamBuilder<BluetoothAdapterState>(
        stream: FlutterBluePlus.adapterState,
        initialData: BluetoothAdapterState.unknown,
        builder: (context, snapshot) {
          if (snapshot.data == BluetoothAdapterState.on && connectedDevice == null) {
            // Arată butonul doar dacă BT e pornit ȘI nu suntem conectați
            return _buildScanButton();
          }
          return Container(); // Nu arăta niciun buton altfel
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