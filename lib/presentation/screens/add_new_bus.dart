import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddNewBus extends StatefulWidget {
  const AddNewBus({super.key});

  @override
  State<AddNewBus> createState() => _AddNewBusState();
}

class _AddNewBusState extends State<AddNewBus> {
  bool validate = false;
  TextEditingController stateController = TextEditingController();
  TextEditingController districtController = TextEditingController();
  TextEditingController privateOrGovtController = TextEditingController();
  TextEditingController busName_and_busNoController = TextEditingController();
  TextEditingController vehicleNumberController = TextEditingController();
  TextEditingController pick_up_stopController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController pickup_timeController = TextEditingController();
  TextEditingController reach_destination_timeController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Title'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        child: Padding(
          padding: EdgeInsets.all(35),
          child: ListView(
            children: [
              SizedBox(height: 15),
              TextField(
                controller: stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  hintText: 'Enter the State you are in',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: districtController,
                decoration: InputDecoration(
                  labelText: 'District',
                  hintText: 'Enter the district you are in',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: privateOrGovtController,
                decoration: InputDecoration(
                  labelText: 'Private/Govt Bus',
                  hintText: 'Enter Private/Govt',
                  prefixIcon: Icon(Icons.directions_bus_rounded),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: busName_and_busNoController,
                decoration: InputDecoration(
                  labelText: 'Bus Name / No',
                  hintText: 'Eg:Amman - 106',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: vehicleNumberController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Number',
                  hintText: 'Eg:TN 45 W 7654',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: pick_up_stopController,
                decoration: InputDecoration(
                  labelText: 'Pick Up Stop',
                  hintText: 'Enter your pick up stop',
                  prefixIcon: Icon(Icons.stop_rounded),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText: 'Enter your destination',
                  prefixIcon: Icon(Icons.stop_circle),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: pickup_timeController,
                decoration: InputDecoration(
                  labelText: 'Pick up stop time',
                  hintText: 'Enter your pick up time',
                  prefixIcon: Icon(Icons.time_to_leave_rounded),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: reach_destination_timeController,
                decoration: InputDecoration(
                  labelText: 'Pick Up Stop',
                  hintText: 'Enter your reaching time',
                  prefixIcon: Icon(Icons.time_to_leave_rounded),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: addBusDetails,
                label: Text('Add Bus Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> addBusDetails() async {
    final state = stateController.text;
    final district = districtController.text;
    final privateOrGovt = privateOrGovtController.text;
    final busNameOrNo = busName_and_busNoController.text;
    final vehicleNum = vehicleNumberController.text;
    final pickUpStop = pick_up_stopController.text;
    final destination = destinationController.text;
    final pickUpTime = pickup_timeController.text;
    final reachTime = reach_destination_timeController.text;

    final body = {
      "state": state,
      "district": district,
      "privateOrGovt": privateOrGovt,
      "busName_and_busNo": busNameOrNo,
      "vehicle_no": vehicleNum,
      "pick_up_stop": pickUpStop,
      "destination": destination,
      "pickup_time": pickUpTime,
      "reach_destination_time": reachTime,
    };

    final url = 'https://bustimetracker.irahalan.in/api/addingBusDetail';
    final uri = Uri.parse(url);
    final response = await http.post(
      uri,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      stateController.text = '';
      districtController.text = '';
      privateOrGovtController.text = '';
      busName_and_busNoController.text = '';
      pick_up_stopController.text = '';
      destinationController.text = '';
      pick_up_stopController.text = '';
      reach_destination_timeController.text = '';
      showSuccessMessage('Successfully added the new bus details');
    } else {
      showErrorMessage('error in adding the bus details');
    }
  }

  void showSuccessMessage(String message) {
    final snackbar = SnackBar(
      content: Text(message, style: TextStyle(color: Colors.blueAccent)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  void showErrorMessage(String message) {
    final snackbar = SnackBar(
      content: Text(message, style: TextStyle(color: Colors.redAccent)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }
}


      // "state": "tamil Nadu",
      // "district": "Tiruchirappalli",
      // "privateOrGovt": "private",
      // "busName_and_busNo": "Amman - 105",
      // "vehicle_no": "Tn-45 w7645",
      // "pick_up_stop": "BHEL",
      // "destination": "Chathiram",
      // "pickup_time": "9:20 AM",
      // "reach_destination_time": "10:05 AM",