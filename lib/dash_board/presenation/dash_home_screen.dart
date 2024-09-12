import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facerecognition_flutter/dash_board/presenation/user_attendence.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[800], // Dark background for AppBar
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Text color for title
          ),
        ),
        elevation: 4, // Adds a shadow for a nice effect
      ),
      body: Column(
        children: [
          // Course summary section with circular progress indicators
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800], // Darker background color for the container
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3), // Darker shadow for dark mode
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ateendence history',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Light text on dark background
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'An overview of employees history.',
                    style: TextStyle(fontSize: 14, color: Colors.grey), // Subtle grey text
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // First Circular Progress Indicator (Course Progress)
                      Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 60.0,
                            lineWidth: 10.0,
                            animation: true,
                            percent: 0.23, // 23% progress
                            center: const Text(
                              "23%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                                color: Colors.orange,
                              ),
                            ),
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: Colors.orange,
                            backgroundColor: Colors.grey[600]!, // Darker background for the indicator
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Today",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Light text on dark background
                            ),
                          ),
                        ],
                      ),
                      // Second Circular Progress Indicator (Course Grade)
                      Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 60.0,
                            lineWidth: 10.0,
                            animation: true,
                            percent: 0.93, // 93% grade
                            center: const Text(
                              "93%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                                color: Colors.blue,
                              ),
                            ),
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: Colors.blue,
                            backgroundColor: Colors.grey[600]!, // Darker background for the indicator
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "this month",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Light text on dark background
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // List of users from Firebase
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('users').snapshots(), // Stream for real-time updates
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
                    String email = doc['name']; // Corrected to use 'email'

                    // Background color options for dark mode
                    Color backgroundColor = index % 2 == 0
                        ? Colors.blueGrey[900]!
                        : Colors.deepPurple[900]!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Material(
                        color: Colors.transparent, // Keeps the background color of the container
                        child: Container(
                          decoration: BoxDecoration(
                            color: backgroundColor, // Dark mode colors
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[700], // Neutral color for avatars
                              child: Text(
                                name[0], // Display the first letter of the user's name
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Light text on dark background
                              ),
                            ),
                            subtitle: Text(
                              email, // Display user's email
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[300], // Soft grey for subtle info
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              color: Colors.white, // White arrow icon
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailsScreen(userId: doc.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

