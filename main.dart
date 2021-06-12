import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Fonction servant à récupérer le fichier Json
Future<List<CountryCode>> fetchCountryCode(http.Client client) async {
  final response = await client
      .get(Uri.parse('./../codesReseauxInternationaux.json'),
      headers: {"Content-Type": "application/json"});

  if(response.statusCode == 200){
    // On exécute la fonction parseCountryCode dans un Isolate séparé
    return compute(parseCountryCode, utf8.decode(response.bodyBytes));
  }else{
    throw Exception('Impossible de charger le fichier JSON.');
  }
}

// Fonction servant à convertir la réponse obtenue en parsant le Json en une liste.
List<CountryCode> parseCountryCode(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<CountryCode>((json) => CountryCode.fromJson(json)).toList();
}

// Fonction servant à récupérer le pays lié au MCC du numéro IMSI
List<CountryCode> getCountry(String IMSI, List<CountryCode> countryCode){
  int i = 3;
  List<CountryCode> temp;

  do{
    temp = countryCode.where((e) => e.MCC.toString() == IMSI.substring(0,i)).toList();
    i--;
  }while(temp.isEmpty && i>=2);

  if(temp.isEmpty){
    temp.add(CountryCode(MCC: 0, pays: "Inexistant"));
  }

  return temp;
}

// Fonction servant à connaître la couleur à afficher en fonction du résultat
Color getColor(List<CountryCode> list){
  if(list[0].pays == "Inexistant"){
    return Colors.red;
  }else return Colors.green;
}

// Classe définissant un code pays, comprenant un indicatif et un pays
class CountryCode {
  final int MCC;
  final String pays;

  CountryCode({required this.MCC, required this.pays});

  factory CountryCode.fromJson(Map<String, dynamic> json) {
    return CountryCode(
      MCC: json['MCC'] as int,
      pays: json['Pays'] as String,
    );
  }
}

// Fonction principale du programme
void main() => runApp(MyApp());

// Classe de départ pour afficher l'application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appTitle = "Pays d'un numéro IMSI";

    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: appTitle),
    );
  }
}

// Classe Stateful pour gérer la récupération et le parsing du fichier Json
class MyHomePage extends StatefulWidget{
  final String title;

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// Classe d'état pour gérer la récupération et le parsing du fichier Json
class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<CountryCode>>(
        future: fetchCountryCode(http.Client()),
        builder: (context, AsyncSnapshot snapshot) {
          if(snapshot.hasError){
            print(snapshot.error);
            return Container();
          }else if(snapshot.hasData){
            return CountryCodeList(countryCode: snapshot.data);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// Classe Stateful pour afficher l'application une fois le parsing du fichier Json réussi
class CountryCodeList extends StatefulWidget{
  final List<CountryCode> countryCode;

  CountryCodeList({Key? key, required this.countryCode}) : super(key: key);

  @override
  _CountryCodeListState createState() => _CountryCodeListState(countryCode: countryCode);
}

// Classe d'état pour afficher l'application une fois le parsing du fichier Json réussi
class _CountryCodeListState extends State<CountryCodeList> {
  final List<CountryCode> countryCode;

  _CountryCodeListState({Key? key, required this.countryCode}) : super();

  /// On définit les contrôleurs de texte et de formulaire
  final IMSIController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// On définit les expressions régulières
  static Pattern patternIMSI = r"^[2-7][0-9]{14}$";
  static RegExp regexIMSI = new RegExp(patternIMSI.toString());

  bool showResult = false; /// Booléen pour afficher le résultat ou non
  String IMSI = ""; /// Code IMSI entré
  String country = ""; /// Résultat à afficher
  List<CountryCode> result = [];

  /// On initialise l'état de l'application
  void initState(){
    super.initState();
  }

  /// Lorsqu'on clique sur le bouton effacer
  void _erase(){
    setState(() {
      showResult = false;
      IMSIController.text = "";
    });
  }

  /// Lorsqu'on clique sur le bouton valider
  void _validate(){
    if(_formKey.currentState!.validate()){
      setState(() {
        IMSI = IMSIController.text;
        result = getCountry(IMSI, countryCode);
        showResult = true;
      });
    }else{
      setState((){
        showResult = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("Entrez un numéro IMSI"),
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  keyboardType: TextInputType.number,
                  controller: IMSIController,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: "Numéro IMSI"
                  ),
                  validator: (value){
                    if(value != null) {
                      if (value.isEmpty) {
                        return "Entrez un numéro IMSI";
                      } else if (!regexIMSI.hasMatch(value)) {
                        return "Entrez un numéro IMSI au format valide";
                      }
                      return null;
                    }
                  },
                ),
                SizedBox(height: 5), /// On ajoute un espacement en hauteur
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: (){
                        _validate();
                      },
                      child: Text("Valider"),
                    ),
                    SizedBox(width: 5), /// On ajoute un espacement entre les 2 boutons
                    ElevatedButton(
                      onPressed: (){
                        _erase();
                      },
                      child: Text("Effacer"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          showResult ? DataTable( /// Si un résultat doit être affiché
            columns: <DataColumn>[
              DataColumn(
                label: Text(
                    "Numéro IMSI"
                ),
              ),
              DataColumn(
                label: Text(
                    "Pays"
                ),
              ),
            ],
            rows: <DataRow>[
              DataRow(
                cells: <DataCell>[
                  DataCell(Text(IMSI, style: TextStyle(color: getColor(result)))),
                  DataCell(Text(result[0].pays, style: TextStyle(color: getColor(result)))),
                ],
              ),
            ],
          ) : SizedBox(), /// Si aucun résultat ne doit être affiché
        ],
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
