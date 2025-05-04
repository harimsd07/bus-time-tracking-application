import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'State',
            hintText: 'Enter the State you are in',
            prefixIcon: Icon(Icons.location_city),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: 'District',
            hintText: 'Enter the district you are in',
            prefixIcon: Icon(Icons.location_city),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: 'Private/Govt Bus',
            hintText: 'Enter Private/Govt',
            prefixIcon: Icon(Icons.directions_bus_rounded),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: 'Bus Name / No',
            hintText: 'Eg:Amman - 106',
            prefixIcon: Icon(Icons.numbers),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: 'Pick Up Stop',
            hintText: 'Enter your pick up stop',
            prefixIcon: Icon(Icons.stop_rounded),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: 'Destination',
            hintText: 'Enter your destination',
            prefixIcon: Icon(Icons.stop_circle),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: 'Pick Up Stop',
            hintText: 'Enter your pick up time',
            prefixIcon: Icon(Icons.time_to_leave_rounded),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: 'Pick Up Stop',
            hintText: 'Enter your reaching time',
            prefixIcon: Icon(Icons.time_to_leave_rounded),
          ),
        ),
      ],
    );
  }
}
