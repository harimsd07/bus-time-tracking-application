import 'package:bus_time_track/presentation/screens/add_new_bus.dart';
import 'package:bus_time_track/presentation/screens/get_bus_time.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Home Page for Bus Time Track App'),
        centerTitle: true,
      ),
      drawer: Drawer(backgroundColor: Colors.blueAccent),
      body: SafeArea(
        top: true,
        minimum: EdgeInsets.fromLTRB(0, 170, 0, 0),
        child: Column(
          children: [
            Center(child: Text("Home Page")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddNewBus()),
                );
              },
              child: Text('Add new Bus Time'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GetBusTime()),
                );
              },
              child: Text('Get Bus Time'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
