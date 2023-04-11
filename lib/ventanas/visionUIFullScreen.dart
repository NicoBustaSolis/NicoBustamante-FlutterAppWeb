import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';

class VisionUIFullScreen extends StatefulWidget {
  const VisionUIFullScreen({super.key});

  @override
  _VisionUIFullScreenState createState() => _VisionUIFullScreenState();
}

class _VisionUIFullScreenState extends State<VisionUIFullScreen> {
  Widget dataStudio() {
    return Html(
      data:
          '<iframe src="https://lookerstudio.google.com/embed/reporting/32e7bee6-09fc-4ebd-a389-52fc9cfcbbfb/page/zf4CD" frameborder="0" style="border:0; width: 100%; height: 100%;" allowfullscreen></iframe>',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vision UI'),
      ),
      body: Center(
        child: Column(
          children: [
            Text('Vision UI'),
            dataStudio(),
          ],
        ),
      ),
    );
  }
}
