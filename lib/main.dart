//i will change that app so that when user open app it will go to collection in firebase users doc phone then field faceJpg and save it in the local db
//then when user click button the identify button it will identify that image

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facerecognition_flutter/registeration/business_logic/auth_cubit/login_cubit.dart';
import 'package:facerecognition_flutter/registeration/presenation/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:facesdk_plugin/facesdk_plugin.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'about.dart';
import 'dash_board/presenation/dash_home_screen.dart';
import 'settings.dart';
import 'person.dart';
import 'personview.dart';
import 'facedetectionview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return   ScreenUtilInit(
        designSize: const Size(390, 845),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) =>MaterialApp(
      debugShowCheckedModeBanner: false,
          title: 'Face Recognition',
          theme: ThemeData(
            // Define the default brightness and colors.
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
         // app home
        // home: FirebaseAuth.instance.currentUser == null ?BlocProvider(create: (context) => LoginCubit(), child: SignInScreen(),): MyHomePage(title: 'Face Recognition')),
         //dash home
        home: UsersListScreen(),
    ),
    );
  }
}

// ignore: must_be_immutable
class MyHomePage extends StatefulWidget {
  final String title;
  var personList = <Person>[];

  MyHomePage({super.key, required this.title});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  String _warningState = "";
  bool _visibleWarning = false;

  final _facesdkPlugin = FacesdkPlugin();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    DateTime now = DateTime.now();
    String currentTime = DateFormat('HH:mm').format(now);
    int facepluginState = -1;
    String warningState = "";
    bool visibleWarning = false;

    try {
      if (Platform.isAndroid) {
        await _facesdkPlugin
            .setActivation(
            "CFO+UUpNLaDMlmdjoDlhBMbgCwT27CzQJ4xHpqe9rDOErwoEUeCGPRTfQkZEAFAFdO0+rTNRIwnQ"
                "wpqqGxBbfnLkfyFeViVS5bpWZFk15QXP3ZtTEuU1rK5zsFwcZrqRUxsG9dXImc+Vw5Ddc9zBp9GE"
                "UuDycHLqC9KgQGVb0TS2u9Kz67HQOSDw9hskjBpjRbqiG+F/h5DBLPzjgFh1Y6vzgg6I59FzTOcd"
                "rdEbX7kI15Nwgf1hvHGtSgON/a0Fmw+XNdnxH2pVY96mcTemHYZAtxh8lA/t1DtTyZXpHjW8N6nq"
                "4UN2YDlKLXSrDzLpLHJmBsdpH71AXb7dfAq94Q==")
            .then((value) => facepluginState = value ?? -1);
      } else {
        await _facesdkPlugin
            .setActivation(
            "nWsdDhTp12Ay5yAm4cHGqx2rfEv0U+Wyq/tDPopH2yz6RqyKmRU+eovPeDcAp3T3IJJYm2LbPSEz"
                "+e+YlQ4hz+1n8BNlh2gHo+UTVll40OEWkZ0VyxkhszsKN+3UIdNXGaQ6QL0lQunTwfamWuDNx7Ss"
                "efK/3IojqJAF0Bv7spdll3sfhE1IO/m7OyDcrbl5hkT9pFhFA/iCGARcCuCLk4A6r3mLkK57be4r"
                "T52DKtyutnu0PDTzPeaOVZRJdF0eifYXNvhE41CLGiAWwfjqOQOHfKdunXMDqF17s+LFLWwkeNAD"
                "PKMT+F/kRCjnTcC8WPX3bgNzyUBGsFw9fcneKA==")
            .then((value) => facepluginState = value ?? -1);
      }

      if (facepluginState == 0) {
        await _facesdkPlugin
            .init()
            .then((value) => facepluginState = value ?? -1);
      }
    } catch (e) {}

    // Fetch data from Firebase Firestore
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String name = data['name'];

        Uint8List faceJpg = base64Decode(data['faceJpg']);
        Uint8List templates = base64Decode(data['templates']);

        // Insert into the local database
        Person person = Person(name: name, faceJpg: faceJpg, templates: templates);
        await insertPerson(person);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error fetching data from Firebase: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }

    List<Person> personList = await loadAllPersons();
    await SettingsPageState.initSettings();

    final prefs = await SharedPreferences.getInstance();
    int? livenessLevel = prefs.getInt("liveness_level");

    try {
      await _facesdkPlugin
          .setParam({'check_liveness_level': livenessLevel ?? 0});
    } catch (e) {}

    if (!mounted) return;

    if (facepluginState == -1) {
      warningState = "Invalid license!";
      visibleWarning = true;
    } else if (facepluginState == -2) {
      warningState = "License expired!";
      visibleWarning = true;
    } else if (facepluginState == -3) {
      warningState = "Invalid license!";
      visibleWarning = true;
    } else if (facepluginState == -4) {
      warningState = "No activated!";
      visibleWarning = true;
    } else if (facepluginState == -5) {
      warningState = "Init error!";
      visibleWarning = true;
    }

    setState(() {
      _warningState = warningState;
      _visibleWarning = visibleWarning;
      widget.personList = personList;
    });
  }
  Future<Database> createDB() async {
    final database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'person.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE person(name text, faceJpg blob, templates blob)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );

    return database;
  }

  // A method that retrieves all the dogs from the dogs table.
  Future<List<Person>> loadAllPersons() async {
    // Get a reference to the database.
    final db = await createDB();

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('person');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return Person.fromMap(maps[i]);
    });
  }
  Future<void> insertPerson(Person person) async {
    // Get a reference to the database.
    final db = await createDB();

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'person',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    setState(() {
      widget.personList.add(person);
    });
  }
  Future<void> deleteAllPerson() async {
    final db = await createDB();
    await db.delete('person');

    setState(() {
      widget.personList.clear();
    });

    Fluttertoast.showToast(
        msg: "All person deleted!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }
  Future<void> deletePerson(index) async {
    // ignore: invalid_use_of_protected_member

    final db = await createDB();
    await db.delete('person',
        where: 'name=?', whereArgs: [widget.personList[index].name]);

    // ignore: invalid_use_of_protected_member
    setState(() {
      widget.personList.removeAt(index);
    });

    Fluttertoast.showToast(
        msg: "Person removed!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }
  Future<void> enrollPerson(String phoneNumber) async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      var rotatedImage = await FlutterExifRotation.rotateImage(path: image.path);
      final faces = await _facesdkPlugin.extractFaces(rotatedImage.path);

      if (faces.isEmpty) {
        Fluttertoast.showToast(
          msg: "No face detected!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      for (var face in faces) {
        num randomNumber = 10000 + Random().nextInt(10000); // Random ID
        // Convert faceJpg and templates to Uint8List or base64
        Uint8List faceJpg = face['faceJpg'];
        Uint8List templates = face['templates'];

        // Store to Firebase Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc('01154354391') // Use phone number as document ID
            .set({
          'faceJpg': base64Encode(faceJpg),  // Save faceJpg as base64 string
          'templates': base64Encode(templates),
          'name': 'Person$randomNumber',
        }, SetOptions(merge: true));  // Merge with existing data if needed
      }

      Fluttertoast.showToast(
        msg: "Person enrolled!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
  Future<void> enrollFingerprint(String phoneNumber) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      // Check if the device supports biometric authentication
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        Fluttertoast.showToast(
          msg: "Biometric authentication not available",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Authenticate using biometrics (fingerprint or face recognition)
      bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to enroll fingerprint',
        options: const AuthenticationOptions(
          stickyAuth: true, // Keeps auth dialog open
          biometricOnly: true, // Only allow biometrics
        ),
      );
      if (!authenticated) {
        Fluttertoast.showToast(
          msg: "Authentication failed",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Simulate the fingerprint data (since we can't access real fingerprint data)
      String simulatedFingerprintData = base64Encode(utf8.encode("fingerprint_data_${DateTime.now()}"));

      // Enroll the fingerprint in Firebase Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc('01154354391') // Use phone number as document ID
          .set({
        'fingerprint': simulatedFingerprintData,  // Save simulated fingerprint
      }, SetOptions(merge: true));  // Merge with existing data

      Fluttertoast.showToast(
        msg: "Fingerprint enrolled successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
//regigter new accont phone password login for admin
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face and finger Recognition'),
        toolbarHeight: 70,
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Column(
          children: <Widget>[
            const Card(
                color: Color.fromARGB(255, 0x49, 0x45, 0x4F),
                child: ListTile(
                  leading: Icon(Icons.tips_and_updates),
                  subtitle: Center(
                    child: Text(
                      'Ensure that your face is well-lit. Avoid strong backlighting or very dim environments',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                )),
            const SizedBox(
              height: 6,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                      label: const Text('Enroll'),
                      icon: const Icon(
                        Icons.person_add,
                        // color: Colors.white70,
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          // foregroundColor: Colors.white70,
                          backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(12.0)),
                          )),
                      onPressed: () {
                        enrollPerson("01154354391"); // Replace with the actual phone number or pass it dynamically
                      },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                      label: const Text('Identify'),
                      icon: const Icon(
                        Icons.person_search,
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(12.0)),
                          )),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(

                              builder: (context) => FaceRecognitionView(
                                personList: widget.personList,
                              )),
                        );
                      }),
                ),
              ],
            ),  const SizedBox(
              height: 6,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                      label: const Text('Enroll fingerprint'),
                      icon: const Icon(
                        Icons.fingerprint,
                        // color: Colors.white70,
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          // foregroundColor: Colors.white70,
                          backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(12.0)),
                          )),
                      onPressed: () {
                        markAttendance('01154354391');
                        // Replace with the actual phone number or pass it dynamically
                      },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                      label: const Text('Identify'),
                      icon: const Icon(
                        Icons.person_search,
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(12.0)),
                          )),
                      onPressed: () {
                        markAttendance('01154354391');
                      }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                      label: const Text('Settings'),
                      icon: const Icon(
                        Icons.settings,
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(12.0)),
                          )),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SettingsPage(
                                homePageState: this,
                              )),
                        );
                      }),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                      label: const Text('About'),
                      icon: const Icon(
                        Icons.info,
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(12.0)),
                          )),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutPage()),
                        );
                      }),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Container(
              height: 330,
              child:  IdentificationTimeView(),
            ),
            Expanded(
                child: Stack(
                  children: [
                    PersonView(
                      personList: widget.personList,
                      homePageState: this,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Visibility(
                            visible: _visibleWarning,
                            child: Container(
                              width: double.infinity,
                              height: 40,
                              color: Colors.redAccent,
                              child: Center(
                                child: Text(
                                  _warningState,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ))
                      ],
                    )
                  ],
                )),
            const SizedBox(
              height: 4,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(
                  image: AssetImage('assets/ic_kby.png'),
                  width: 48,
                ),
                SizedBox(width: 4),
                Text('dessouk Technology company',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 60, 60, 60),
                    ))
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class IdentificationTimeView extends StatefulWidget {
  const IdentificationTimeView({super.key});

  @override
  _IdentificationTimeViewState createState() => _IdentificationTimeViewState();
}

class _IdentificationTimeViewState extends State<IdentificationTimeView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _firestore.collection('users').doc('01154354391').collection('attendance').snapshots(), // Firebase stream for real-time updates
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            String name = doc['name'];
            String time = doc['time'];
            String dayMonthYear = doc['day_month_year'];
            int lateTime = doc['lateTime'] ?? 0; // Default to 0 if lateTime is null

            // Change background color based on lateTime
            bool isLate = lateTime > 0;
            Color backgroundColor = isLate ? Colors.red[100]! : Colors.green[100]!;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor, // Change background color based on lateness
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white, // Color of the circle background
                    child: Text(
                      (index + 1).toString().padLeft(2, '0'), // Display the item index
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    'Date: \n$dayMonthYear',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isLate ? Colors.red : Colors.green,
                    ),
                  ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLate ? '$lateTime mins late' : 'On time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isLate ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}


class IdentificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isUserAtCompanyLocation(
      Position userPosition, String companyId) async {
    DocumentSnapshot companySnapshot =
    await _firestore.collection('companies').doc(companyId).get();

    if (companySnapshot.exists) {
      // Fetch company location and start time
      Map<String, dynamic> companyData = companySnapshot.data() as Map<String, dynamic>;
      double companyLat = companyData['latitude'];
      double companyLng = companyData['longitude'];
      String startTime = companyData['startTime'];

      // Get the current time
      DateTime now = DateTime.now();
      String currentTime = DateFormat('HH:mm').format(DateTime.now());
      //Todo:handle 7war il time dh
      // Check if current time is after the company start time
      //if (true) {
      if (currentTime.compareTo(startTime) >= 0) {
        // Calculate distance between user and company location
        double distance = Geolocator.distanceBetween(
            userPosition.latitude, userPosition.longitude, companyLat, companyLng);

        if (distance <= 1000) {
          return true; // User is within the 1000m radius of the company location
        } else {
          print('User is outside the company radius');
          return false;
        }
      } else {
        print('Current time is before company start time');
        return false;
      }
    } else {
      print('Company not found');
      return false;
    }
  }
}

Future<void> markAttendance(String phoneNumber) async {
  String companyId = 'holla'; // Replace with actual companyId logic
  DateTime now = DateTime.now();
  String dayMonthYear = '${now.day}-${now.month}-${now.year}';

  // Initialize LocalAuthentication
  final LocalAuthentication auth = LocalAuthentication();

  // Check if the device supports biometric authentication
  bool canCheckBiometrics = await auth.canCheckBiometrics;

  if (!canCheckBiometrics) {
    print('Biometric authentication is not available.');
    return;
  }

  // Authenticate the user with their fingerprint
  bool authenticated = false;
  try {
    authenticated = await auth.authenticate(
      localizedReason: 'Please authenticate to mark your attendance',
      options: const AuthenticationOptions(
        biometricOnly: true, // Only use biometrics
      ),
    );
  } catch (e) {
    print('Error using biometric authentication: $e');
  }

  if (!authenticated) {
    print('Authentication failed.');
    return;
  }

  // If authentication is successful, proceed to mark attendance
  DocumentSnapshot companySnapshot = await FirebaseFirestore.instance.collection('companies').doc(companyId).get();
  if (companySnapshot.exists) {
    String companyStartTimeStr = companySnapshot['startTime']; // Should be "04:00"

    DateTime companyStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(companyStartTimeStr.split(":")[0]), // hour
        int.parse(companyStartTimeStr.split(":")[1])  // minute
    );

    // Calculate late time in minutes
    Duration lateDuration = now.difference(companyStartTime);
    int lateMinutes = lateDuration.inMinutes > 0 ? lateDuration.inMinutes : 0; // if not late, set to 0

    // Save attendance data to Firebase
    await FirebaseFirestore.instance
        .collection('users')
        .doc(phoneNumber)
        .collection('attendance')
        .doc(dayMonthYear)
        .set({
      'name': phoneNumber, // Replace with actual user name
      'companyId': companyId,
      'time': now.toString(),
      'lateTime': lateMinutes,
      'day_month_year': dayMonthYear,
    });

    print('Attendance marked successfully for user $phoneNumber. Late by $lateMinutes minutes.');
  } else {
    print('Company not found.');
  }
}

//i want to add fields to firebase 1 contain the company location
//and another one contain the start time of the company
//so that when user identify himself it will
//check if current time -start time of the company and
//check if user location in the company do that by add 1000 metre as square around the location of company
//to check if user is in the coorect place