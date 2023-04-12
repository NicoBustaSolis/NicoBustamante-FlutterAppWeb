import 'dart:convert';
import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_network/image_network.dart';
import 'package:prueba/sliderImagenesHeader/index.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:webviewx/webviewx.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(GetMaterialApp(
    home: PruebaTransbankUI(),
  ));
}

class PruebaTransbankUI extends StatefulWidget {
  const PruebaTransbankUI({super.key});

  @override
  _PruebaTransbankUIState createState() => _PruebaTransbankUIState();
}

class CartController extends GetxController {
  final cartItems = [].obs;
  int get count => cartItems.length;

  void addToCart(item) {
    cartItems.add(item);
  }

  void removeFromCart(item) {
    cartItems.remove(item);
  }
}

class _PruebaTransbankUIState extends State<PruebaTransbankUI> {
  //Colores
  var colorScaffold = Color(0xffffebdcac);
  var colorNaranja = Color.fromARGB(255, 255, 79, 52);
  var colorMorado = Color.fromARGB(0xff, 0x52, 0x01, 0x9b);

  //Modulo VisionAI
  var activeCamera = false;
  var mostrarControl = false;
  var mostrarControl2 = false;
  var mostrarData = false;
  var mostrarData2 = false;
  var mostrarDataStudio = false;
  var mostrarGridImagenes = true;
  var mostrarGridImagenes2 = false;
  var mostrarFormulario = false;
  var mostrarFormulario2 = false;
  var uidCamara = "";
  var pantalla = 0.0;
  late VideoPlayerController _controller;
  final videoUrl = 'https://www.visionsinc.xyz/hls/test.m3u8';
  final cartItems = [].obs;
  final cartController = CartController();

  void initState() {
    super.initState();

    try {
      _controller = VideoPlayerController.network(
        videoUrl,
      )..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {});
        });
      _controller.setVolume(0.0);
    } catch (e) {
      print(e);
    }
  }

  var dispositivo = '';

  //-----------FORMULARIO------//

  bool autoValidate = true;
  bool readOnly = false;
  bool showSegmentedControl = true;
  final _formKey = GlobalKey<FormBuilderState>();
  bool _ageHasError = false;
  bool _genderHasError = false;

  var genderOptions = ['Male', 'Female', 'Other'];

  void _onChanged(dynamic val) => debugPrint(val.toString());

  //------FIREBASE----------//

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  //Obtengo toda la informacion de la coleccion eventos
  CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('eventos');

  Future<List<Map<String, dynamic>>> geteventosData() async {
    QuerySnapshot eventosQuerySnapshot = await _collectionRef.get();
    List<Map<String, dynamic>> eventosDataList = [];
    for (var doc in eventosQuerySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      eventosDataList.add(data);
    }
    return eventosDataList;
  }

  late InAppWebViewController webView;

  var nombreEvento = "";

  /* Almacenamos la información del evento seleccionado para utilizarlo en el formualario */
  Map<String, dynamic>? _eventoSeleccionado;

  Widget entradaFormulario() {
    //Dividimos la cadena de fechas en dos fechas separadas
    String fechasDisponibles = _eventoSeleccionado!["fecha"];
    List<String> fechas = fechasDisponibles.split(" - ");
    String fechaInicio = fechas[0];
    String fechaFin = fechas[1];

    //Convertimos a DateTime para poder iterar sobre estas
    DateTime fechaInicioDateTime = DateFormat("dd/MM/yy").parse(fechaInicio);

    DateTime fechaFinDateTime = DateFormat("dd/MM/yy").parse(fechaFin);

    //Creamos una lista de todas las fechas en el rango con for y add
    List<DateTime> todasLasFechas = [];

    //Lista donde se almacenarán las fechas seleccionadas
    List<DateTime> fechasSeleccionadas =
        []; // Agrega esta variable para almacenar las fechas seleccionadas
    for (var i = fechaInicioDateTime;
        i.isBefore(fechaFinDateTime) || i.isAtSameMomentAs(fechaFinDateTime);
        i = i.add(Duration(days: 1))) {
      todasLasFechas.add(i);
    }
    List<DropdownMenuItem<DateTime>> opciones = todasLasFechas.map((fecha) {
      String fechaString = DateFormat('dd/MMM/yyyy').format(fecha);
      return DropdownMenuItem<DateTime>(
        value: fecha,
        child: Text(fechaString),
      );
    }).toList();
    return Scaffold(
      backgroundColor: colorScaffold,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormBuilder(
                key: _formKey,
                autovalidateMode: autoValidate
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: Container(
                  width: dispositivo == "PC"
                      ? 600
                      : MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FormBuilderDropdown(
                        name: 'fecha',
                        decoration: InputDecoration(
                          labelText: 'Fecha del evento',
                        ),
                        items: opciones,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: "Este campo es obligatorio"),
                        ]),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      FormBuilderDropdown(
                        name: 'cantidad',
                        decoration: InputDecoration(
                          labelText: 'Seleccione la cantidad de entradas',
                        ),
                        items: [
                          DropdownMenuItem(value: '1', child: Text('1')),
                          DropdownMenuItem(value: '2', child: Text('2')),
                          DropdownMenuItem(value: '3', child: Text('3')),
                          DropdownMenuItem(value: '4', child: Text('4')),
                        ],
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: "Este campo es obligatorio"),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorMorado,
                    foregroundColor: colorNaranja,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.saveAndValidate()) {
                      var formData = _formKey.currentState!.value;
                      var fecha = formData['fecha'];
                      var cantidad = formData['cantidad'];

                      // Aquí puedes hacer lo que quieras con los valores de fecha y cantidad

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Tu entrada ha sido agregada al carrito'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Enviar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorMorado,
                    foregroundColor: colorNaranja,
                  ),
                  onPressed: () {
                    setState(() {
                      mostrarGridImagenes = true;
                    });
                  },
                  child: Text(
                    'Volver',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget gridImagenes() {
    int contador = 0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: geteventosData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox();
        }

        List<Map<String, dynamic>> cafeteriasDataList = snapshot.data!;

        return Align(
          child: SingleChildScrollView(
            child: Column(
              children: cafeteriasDataList.asMap().entries.map((entry) {
                int index = entry.key;
                String nombre = entry.value["nombre"];
                String urlImagen = entry.value["imagen"][0];
                String lugar = entry.value["lugar"];
                String descripcion = entry.value["descripcion"];
                String fecha = entry.value["fecha"];

                return Container(
                  width: dispositivo == "PC"
                      ? 600
                      : MediaQuery.of(context).size.width,
                  margin: EdgeInsets.only(left: 0, top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ImageNetwork(
                        borderRadius: BorderRadius.circular(10),
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
                      Text(
                        nombre,
                        style: TextStyle(
                          color: colorNaranja,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        lugar,
                        style: TextStyle(
                          color: colorNaranja,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        descripcion,
                        style: TextStyle(
                          color: colorNaranja,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        fecha,
                        style: TextStyle(
                          color: colorNaranja,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorMorado,
                              foregroundColor: colorNaranja,
                            ),
                            onPressed: () {
                              setState(() {
                                mostrarGridImagenes = false;
                                _eventoSeleccionado = entry.value;
                              });
                            },
                            child: Text(
                              "¡Asistir!",
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorMorado,
                              foregroundColor: colorNaranja,
                            ),
                            onPressed: () {},
                            child: Text(
                              "Más información",
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

/*   Widget formularioEventos(){
    return 
  }; */

  Widget vistaTransbankStudio() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        mostrarFormulario = true;
      });
    });
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height - 300,
        child: mostrarGridImagenes
            ? gridImagenes()
            : (mostrarFormulario ? entradaFormulario() : Container()));
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
            margin: EdgeInsets.only(top: 50, left: 50, right: 50),
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
                          mostrarGridImagenes
                              ? 'Eventos'
                              : _eventoSeleccionado!["nombre"],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOutBack,
                            width: mostrarControl ? 250 : 80,
                            decoration: BoxDecoration(
                              color: colorMorado,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: SingleChildScrollView(
                              child: Container(
                                height:
                                    70, // Ajustar a la altura inicial del contenedor
                                child: GestureDetector(
                                  onTap: (() {
                                    setState(() {
                                      mostrarControl = !mostrarControl;
                                      mostrarData2 = false;
                                    });
                                    Future.delayed(
                                        Duration(
                                            milliseconds: mostrarControl2
                                                ? 50
                                                : 550), () {
                                      setState(() {
                                        mostrarControl2 = !mostrarControl2;
                                        mostrarData = false;
                                      });
                                    });
                                  }),
                                  child: mostrarControl2
                                      ? Center(
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Text(
                                                'Resumen de tu compra',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(
                                                  height:
                                                      2), // Ajustar espacio entre elementos
                                              SizedBox(
                                                  height:
                                                      2), // Ajustar espacio entre elementos
                                              Container(
                                                width: 246.3,
                                                decoration: BoxDecoration(
                                                  color: colorMorado,
                                                ),
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      width: 248,
                                                      height: 30,
                                                      color: colorMorado,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 200,
                                                          color: colorMorado,
                                                          child: Text(
                                                            'nombre evento',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 46,
                                                          color: colorMorado,
                                                          child: Text(
                                                            '500',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: 20,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 200,
                                                          color: colorMorado,
                                                          child: Text(
                                                            'nombre evento',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 46,
                                                          color: colorMorado,
                                                          child: Text(
                                                            '500',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: colorMorado,
                                                          ),
                                                          width: 200,
                                                          child: Text(
                                                            'Total',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: colorMorado,
                                                          ),
                                                          width: 46,
                                                          child: Text(
                                                            '1000',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(40),
                                                          color: colorMorado,
                                                        ),
                                                        width: 246.3,
                                                        child: ElevatedButton(
                                                            onPressed: () {},
                                                            child: Text(
                                                                "Ir al carrito"))),
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                    Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(40),
                                                          color: colorMorado,
                                                        ),
                                                        width: 246.3,
                                                        child: ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  colorNaranja,
                                                              foregroundColor:
                                                                  colorMorado,
                                                            ),
                                                            onPressed: () {},
                                                            child: Text(
                                                                "Pagar directamente"))),
                                                  ],
                                                ),
                                              ),

                                              // Añadir más elementos aquí
                                            ],
                                          ),
                                        )
                                      : Icon(
                                          Icons.shopping_cart_sharp,
                                          color: colorNaranja,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        mostrarGridImagenes == false
                            ? Align(
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
                                              milliseconds:
                                                  mostrarData2 ? 50 : 550), () {
                                        setState(() {
                                          mostrarData2 = !mostrarData2;
                                          mostrarControl = false;
                                        });
                                      });
                                    }),
                                    child: mostrarData2
                                        ? Center(
                                            child: Text(
                                              'Eventos',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.confirmation_num_rounded,
                                            color: colorNaranja,
                                            size: 60,
                                          ),
                                  ),
                                ),
                              )
                            : SizedBox()
                      ],
                    )),
                Container(
                  child: vistaTransbankStudio(),
                  margin: EdgeInsets.only(top: 40),
                )
              ],
            )),
      ),
    ));
  }

  Widget vistaMobile() {
    return (Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height - 50,
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
                  'Entradas',
                  style: TextStyle(
                      color: colorNaranja, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(20),
              height: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: vistaTransbankStudio(),
            ),
/*             (pantalla < 882)
                ? Container(
                    height: MediaQuery.of(context).size.height - 600,
                    child: columnaControlCamara(),
                    //decoration: BoxDecoration(color: Colors.black),
                  )
                : filaControlCamara(), */
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
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
