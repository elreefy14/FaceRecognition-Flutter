import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;

  const UserDetailsScreen({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[800],
        title: const Text('Attendance Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder(
          stream: _firestore.collection('users').doc(userId).collection('attendance').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('No attendance records found.'));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var doc = docs[index];
                String dayMonthYear = doc['day_month_year'];
                int lateTime = doc['lateTime'] ?? 0; // Default to 0 if lateTime is null

                // Determine background color based on lateTime
                bool isAbsent = lateTime == -1;
                bool isLate = lateTime > 0;
                Color backgroundColor;
                String lateTimeText;

                if (isAbsent) {
                  backgroundColor = Colors.grey[700]!; // Grey background for absence
                  lateTimeText = 'Absent';
                } else if (isLate) {
                  backgroundColor = Colors.red[100]!; // Red background for lateness
                  lateTimeText = '$lateTime mins late';
                } else {
                  backgroundColor = Colors.green[100]!; // Green background for on-time
                  lateTimeText = 'On time';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Text(
                          (index + 1).toString().padLeft(2, '0'),
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
                              color: isAbsent ? Colors.grey : isLate ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lateTimeText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isAbsent ? Colors.grey : isLate ? Colors.red : Colors.green,
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
        ),
      ),
    );
  }
}
