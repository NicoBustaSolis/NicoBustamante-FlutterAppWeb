import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:webviewx/webviewx.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_network/image_network.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';

class CafeteriasUI extends StatefulWidget {
  const CafeteriasUI({super.key});

  @override
  _CafeteriasUIState createState() => _CafeteriasUIState();
}

class _CafeteriasUIState extends State<CafeteriasUI> {
  var colorScaffold = Color(0xffffebdcac);
  var colorNaranja = Color.fromARGB(255, 255, 79, 52);
  var colorMorado = Color.fromARGB(0xff, 0x52, 0x01, 0x9b);
  //Modulo VisionAI
  var mostrarControl = false;
  var mostrarControl2 = false;
  var mostrarData = false;
  var mostrarData2 = false;
  var mostrarDataStudio = false;
  var mostrarNombre = false;
  var mostrarNombre2 = false;
  var uidCamara = "";
  var pantalla = 0.0;

  var dispositivo = '';

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  //Obtengo toda la informacion de la coleccion cafeterias
  CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('cafeterias');

  Future<List<Map<String, dynamic>>> getCafeteriasData() async {
    QuerySnapshot cafeteriasQuerySnapshot = await _collectionRef.get();
    List<Map<String, dynamic>> cafeteriasDataList = [];
    for (var doc in cafeteriasQuerySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      cafeteriasDataList.add(data);
    }
    return cafeteriasDataList;
  }

  final CarouselController _controller = CarouselController();

  String nombreCafeteriaActual = "Mic Cafe";

  Future<void> _openMapsModal(String ubicacion) async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$ubicacion";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      throw "Could not launch $googleMapsUrl";
    }
  }

  Widget sliderImagenes() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getCafeteriasData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox();
        }

        List<Map<String, dynamic>> cafeteriasDataList = snapshot.data!;

        return Align(
          child: SingleChildScrollView(
            child: Column(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    viewportFraction: 0.7,
                    aspectRatio: 16 / 9,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                    autoPlay: false,
                    height: MediaQuery.of(context).size.height,
                    onPageChanged: (index, reason) => {
                      setState(() {
                        nombreCafeteriaActual =
                            cafeteriasDataList[index]["nombre"];
                      })
                    },
                  ),
                  carouselController: _controller,
                  items: cafeteriasDataList.asMap().entries.map((entry) {
                    int index = entry.key;
                    String nombre = entry.value["nombre"];
                    String urlImagen = entry.value["imagen"];
                    String ubicacion = entry.value["ubicacion"];
                    double calificacion = entry.value["calificacion"];
                    String web = entry.value["web"];

                    return Container(
                      child: Column(
                        children: [
                          Container(
                            width: dispositivo == "PC"
                                ? 600
                                : MediaQuery.of(context).size.width,
                            margin: EdgeInsets.only(left: 0, top: 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (dispositivo == "MOVIL")
                                  Text(
                                    nombre,
                                    style: TextStyle(
                                      color: colorNaranja,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30)),
                                        backgroundColor: colorMorado,
                                        foregroundColor: colorNaranja,
                                      ),
                                      onPressed: () async {
                                        await _openMapsModal(ubicacion);
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            ubicacion,
                                            style: TextStyle(
                                              fontSize: dispositivo == "PC"
                                                  ? 16.0
                                                  : 13,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            maxLines: null,
                                          ),
                                          Icon(
                                            Icons.location_on,
                                            color: colorNaranja,
                                            size: dispositivo == "PC" ? 30 : 20,
                                          )
                                        ],
                                      ),
                                    ),

/*                                     Text(
                                      ubicacion,
                                      style: TextStyle(
                                        color: colorNaranja,
                                        fontSize: dispositivo == "PC" ? 24 : 15,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.left,
                                    ), */
/*                                     Icon(
                                      Icons.location_on,
                                      color: colorMorado,
                                      size: dispositivo == "PC" ? 30 : 25,
                                    ) */
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ImageNetwork(
                            image: urlImagen,
                            width: dispositivo == "PC"
                                ? 600
                                : MediaQuery.of(context).size.width,
                            height: dispositivo == "PC"
                                ? MediaQuery.of(context).size.height - 450
                                : MediaQuery.of(context).size.height - 600,
                            fitAndroidIos: BoxFit.fitWidth,
                            fitWeb: BoxFitWeb.fill,
                          ),
                          RatingBar.builder(
                            initialRating: calificacion,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                            itemBuilder: (context, _) => Icon(
                              Icons.coffee_rounded,
                              color: colorMorado,
                            ),
                            onRatingUpdate: (rating) {
                              print(rating);
                            },
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorMorado,
                              foregroundColor: colorNaranja,
                            ),
                            onPressed: () async {
                              final Uri uri = Uri.parse(web);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                throw "Could not launch $uri";
                              }
                              // Acción que se realiza cuando se presiona el botón
                            },
                            child: Text(
                              "Visitar web",
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget vistaCoffeeStudio() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        mostrarDataStudio = true;
      });
    });
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height - 300,
        child: sliderImagenes());
  }

  Widget vistaWeb() {
    return (Dialog(
      backgroundColor: Color.fromARGB(0, 0, 0, 0),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutBack,
        height: MediaQuery.of(context).size.height - 120,
        width: 1280,
        decoration: BoxDecoration(
            color: colorScaffold,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ]),
        child: Container(
            margin: EdgeInsets.only(
                top: 50,
                left: dispositivo == 'PC' ? 50 : 0,
                right: dispositivo == 'PC' ? 50 : 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                    width: MediaQuery.of(context).size.width,
                    height: 70,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: colorNaranja,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ]),
                    child: Stack(
                      children: [
                        Center(
                            child: Text(
                          'Cafeterías',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOutBack,
                            width: mostrarData ? 250 : 80,
                            height: 70,
                            decoration: BoxDecoration(
                                color: colorMorado,
                                borderRadius: BorderRadius.circular(40)),
                            child: GestureDetector(
                              onTap: (() {
                                setState(() {
                                  mostrarData = !mostrarData;
                                  mostrarControl2 = false;
                                });
                                Future.delayed(
                                    Duration(
                                        milliseconds: mostrarData2 ? 50 : 550),
                                    () {
                                  setState(() {
                                    mostrarData2 = !mostrarData2;
                                    mostrarControl = false;
                                  });
                                });
                              }),
                              child: mostrarData2
                                  ? Center(
                                      child: Text(
                                        'Cafeterías',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.coffee_maker_rounded,
                                      color: colorNaranja,
                                      size: 60,
                                    ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOutBack,
                            width: 250,
                            height: 70,
                            decoration: BoxDecoration(
                                color: colorMorado,
                                borderRadius: BorderRadius.circular(40)),
                            child: GestureDetector(
                                child: Center(
                              child: Text(
                                nombreCafeteriaActual,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )),
                          ),
                        ),
                      ],
                    )),
                Container(
                    margin: EdgeInsets.only(top: 40),
                    child: vistaCoffeeStudio()),
              ],
            )),
      ),
    ));
  }

  Widget vistaMobile() {
    return (AnimatedContainer(
      duration: Duration(milliseconds: 500),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(color: colorScaffold),
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: colorMorado,
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  'Cafeterías',
                  style: TextStyle(
                      color: colorNaranja, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              alignment: Alignment.topCenter,
              margin: EdgeInsets.all(20),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: sliderImagenes(),
            ),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ancho_pantalla = MediaQuery.of(context).size.width;
    setState(() {
      pantalla = ancho_pantalla;
    });
    print(pantalla);
    setState(() {
      if (ancho_pantalla > 1130) {
        dispositivo = 'PC';
      } else {
        dispositivo = 'MOVIL';
      }
    });
    return (dispositivo == 'PC') ? vistaWeb() : vistaMobile();
  }

  @override
  void initState() {
    super.initState();
  }
}
