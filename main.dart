import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hexcolor/hexcolor.dart';
import 'dart:convert';
import 'package:flutter_spinbox/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main(List<String> args) {
  runApp(myapp());
}

class myapp extends StatefulWidget {
  @override
  _myappstate createState() => _myappstate();
}

class _myappstate extends State<myapp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: homepage(),
    );
  }
}

class homepage extends StatefulWidget {
  @override
  homescreen createState() => homescreen();
}

class homescreen extends State<homepage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: val ? ThemeData.dark() : ThemeData.light(),
        debugShowCheckedModeBanner: false,
        home: MainCards());
  }
}

class MainCards extends StatefulWidget {
  const MainCards({super.key});
  @override
  _MainCards createState() => _MainCards();
}

//you need these to be global variables to use for both
//the main cards and the queue
File? _image;
File? edge;

class _MainCards extends State<MainCards> {
  String first = '';
  double droneTotal = 100;
  String dropdownvalue = 'Feet';

  TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {
      if (home == false) {
        home = true;
        settings = false;
        queue = false;
        simulation = false;
      }
    });
  }

  //these are for the text entry box's in the coordinate settings
  final distanceController = TextEditingController();
  final apertureController = TextEditingController();
  final upperController = TextEditingController();
  final lowerController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: val ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: val ? darkBackground : lightBackground,
        appBar: AppBar(
          iconTheme: IconThemeData(color: val ? Colors.white : Colors.black),
          backgroundColor: val ? Colors.transparent : Colors.blue,
          shadowColor: Colors.transparent,
          title: Text(
            "Knight Light",
            style: TextStyle(color: val ? Colors.white : Colors.black),
          ),
          actions: <Widget>[
            IconButton(
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              icon: const Icon(Icons.question_mark_rounded),
              tooltip: 'Tips',
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Home Page Tips'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: const <Widget>[
                        Text('Make sure you get the coordinates of the'),
                        Text('image before you send it to the queue.'),
                        Text(''),
                        Text('Also, update the coordinate settings'),
                        Text('after you select a new image.'),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'ok'),
                      child: const Text('Ok'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        drawer: null,
        body: drawerSide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //dont remove the side bar from the sized box
                  Flexible(child: Holder()),
                  SizedBox(width: 200, child: SideBart()),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //dont remove the side bar from the sized box
                  SizedBox(width: 200, child: SideBart()),
                  Flexible(child: Holder())
                ],
              ),
      ),
    );
  }

  //this combines all three of the cards for the home page
  Widget Holder() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            //Image picker and the resulting image
            Expanded(child: picker()),
            Expanded(child: placement()),
          ],
        ),
        Expanded(child: progess())
      ],
    );
  }

  //Image picker
  Widget picker() {
    return Card(
      color: val ? greyBackground : Colors.white,
      child: Column(
        children: [
          Row(children: [
            const Expanded(child: Divider()),
            Text(
              "Base Image",
              style: TextStyle(color: val ? Colors.white : Colors.black),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(
            height: 20,
          ),
          _image != null
              ? Image.file(_image!)
              : Image.network(
                  'https://www.russorizio.com/wp-content/uploads/2016/07/ef3-placeholder-image-300x203.jpg',
                  height: 193,
                ),
          const SizedBox(
            height: 30,
          ),
          Container(
            width: 280,
            child: ElevatedButton(
              onPressed: () async {
                {
                  //this is the pop up for the image picker
                  final FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'png']);
                  //if nothing is picked then nothing happens
                  if (result == null) return;
                  PlatformFile file = result.files.single;
                  final image_temporary = File(file.path.toString());
                  //sending the image to the backend
                  final call = await http.post(
                      Uri.parse('http://127.0.0.1:5000/'),
                      body: json.encode({'first': file.name}));
                  //receiving the new image to the backend
                  final response =
                      await http.get(Uri.parse('http://127.0.0.1:5000/'));
                  final decoded = json.decode(response.body);
                  //updating  image information
                  setState(() {
                    edge = File(decoded['second']);
                    _image = image_temporary;
                    first = file.name;
                  });
                }
              },
              child: Row(
                children: const [
                  Icon(CupertinoIcons.camera_circle),
                  Text(
                    'Pick an Image',
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  //Resulting image
  Widget placement() {
    return Card(
      color: val ? greyBackground : Colors.white,
      child: Column(
        children: [
          Row(children: [
            const Expanded(child: Divider()),
            Text(
              "Image Results",
              style: TextStyle(color: val ? Colors.white : Colors.black),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(
            height: 20,
          ),
          edge != null
              ? Image.file(edge!)
              : Image.network(
                  'https://www.russorizio.com/wp-content/uploads/2016/07/ef3-placeholder-image-300x203.jpg',
                  height: 193,
                ),
          const SizedBox(
            height: 30,
          ),
          Container(
            width: 280,
            child: ElevatedButton(
              onPressed: _image != null
                  ? () async {
                      {
                        //we need to use the get request to get the name
                        //of the image because if we don't then the name
                        //of the image won't display if we need to
                        //reenter an image to the queue
                        final response =
                            await http.get(Uri.parse('http://127.0.0.1:5000/'));
                        final decoded = json.decode(response.body);
                        imageLocationList.add(edge!);
                        imageNameList.add(decoded['first']);
                        imageDroneList.add(droneTotal.round());
                        imageDistanceList
                            .add(distanceController.text.toString());
                        imageApertureList
                            .add(apertureController.text.toString());
                        imageUThresholdList.add(upperController.toString());
                        imageLThresholdList.add(lowerController.toString());
                      }
                    }
                  : null,
              child: Row(
                children: const [
                  Icon(Icons.queue_rounded),
                  Text(
                    ' Add to Queue',
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  //Coordinate settings
  Widget progess() {
    // List of items in our dropdown menu
    var items = [
      'Feet',
      'Meters',
    ];

    return Card(
      color: val ? greyBackground : Colors.white,
      child: Column(
        children: <Widget>[
          Row(children: [
            const Flexible(child: Divider()),
            Text(
              "Coordinate Settings",
              style: TextStyle(color: val ? Colors.white : Colors.black),
            ),
            const Flexible(child: Divider()),
          ]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //total drones
                  Row(
                    children: <Widget>[
                      Text(
                        "Total Drones: ",
                        style: TextStyle(
                          color: val ? Colors.white : Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      SizedBox(
                        width: 200,
                        child: SpinBox(
                          min: 1,
                          max: 1000,
                          value: droneTotal,
                          onChanged: (value) => droneTotal = value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  //this is for the minimum distance between drones
                  Row(
                    children: <Widget>[
                      Text(
                        "Min Distance: ",
                        style: TextStyle(
                          color: val ? Colors.white : Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: distanceController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      DropdownButton(
                        // Initial Value
                        value: dropdownvalue,

                        // Down Arrow Icon
                        icon: const Icon(Icons.keyboard_arrow_down),

                        // Array list of items
                        items: items.map((String items) {
                          return DropdownMenuItem(
                            value: items,
                            child: Text(items),
                          );
                        }).toList(),
                        // After selecting the desired option,it will
                        // change button value to selected value
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownvalue = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  //this is for figuring out where to send the coordiantes
                  Row(
                    children: <Widget>[
                      Text(
                        "Aperture: ",
                        style: TextStyle(
                          color: val ? Colors.white : Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(
                        width: 36,
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: apertureController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              //upper limit
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //this is for the minimum distance between drones
                  Row(
                    children: <Widget>[
                      Text(
                        "U. Threshold: ",
                        style: TextStyle(
                          color: val ? Colors.white : Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: upperController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  //this is for figuring out where to send the coordiantes
                  Row(
                    children: <Widget>[
                      Text(
                        "L. Threshold: ",
                        style: TextStyle(
                          color: val ? Colors.white : Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: lowerController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    width: 280,
                    child: ElevatedButton(
                      onPressed: _image != null
                          ? () async {
                              {
                                try {
                                  final response = await http
                                      .get(Uri.parse('http://127.0.0.1:5000/'));
                                  final decoded = json.decode(response.body);
                                  final numbers = await http.post(
                                      Uri.parse('http://127.0.0.1:5000/'),
                                      body: json
                                          .encode({'droneTotal': droneTotal}));
                                  final space = await http.post(
                                      Uri.parse('http://127.0.0.1:5000/'),
                                      body: json.encode({
                                        'distance':
                                            int.parse(distanceController.text)
                                      }));
                                  final higher = await http.post(
                                      Uri.parse('http://127.0.0.1:5000/'),
                                      body: json.encode({
                                        'upper': int.parse(upperController.text)
                                      }));
                                  final downer = await http.post(
                                      Uri.parse('http://127.0.0.1:5000/'),
                                      body: json.encode({
                                        'lower': int.parse(lowerController.text)
                                      }));
                                  final lighter = await http.post(
                                      Uri.parse('http://127.0.0.1:5000/'),
                                      body: json.encode({
                                        'aperture':
                                            int.parse(apertureController.text)
                                      }));
                                } catch (e) {
                                  showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      title: const Text('Coordinate Problems'),
                                      content: SingleChildScrollView(
                                        child: ListBody(
                                          children: const <Widget>[
                                            Text('Fill in All The Variables'),
                                            Text(''),
                                            Text('Also, Make Sure The '),
                                            Text('Variables Are All Ints.'),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, 'ok'),
                                          child: const Text('Ok'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      child: Row(
                        children: const [
                          Icon(Icons.grid_4x4_rounded),
                          Text(
                            'Get Coordinates',
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//these are the list's that store the info for the queue
final imageLocationList = <File>[];
final imageNameList = <String>[];
final imageDroneList = <int>[];
final imageDistanceList = <String>[];
final imageApertureList = <String>[];
final imageUThresholdList = <String>[];
final imageLThresholdList = <String>[];

class Queue extends StatefulWidget {
  @override
  _Queue createState() => _Queue();
}

class _Queue extends State<Queue> {
  final ScrollController scrollControl = ScrollController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: val ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: val ? darkBackground : lightBackground,
        appBar: AppBar(
          iconTheme: IconThemeData(color: val ? Colors.white : Colors.black),
          backgroundColor: val ? Colors.transparent : Colors.blue,
          shadowColor: Colors.transparent,
          title: Text(
            "Knight Light",
            style: TextStyle(color: val ? Colors.white : Colors.black),
          ),
          actions: <Widget>[
            IconButton(
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              icon: const Icon(Icons.question_mark_rounded),
              tooltip: 'Tips',
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Queue Tips'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: const <Widget>[
                        Text(
                            'If you want to change the order of the list, use '),
                        Text(
                            'the two lines on the side of the image list bars'),
                        Text(''),
                        Text('If you want to delete items from the list,'),
                        Text('use the three dots next to the lines.'),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'ok'),
                      child: const Text('Ok'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        drawer: null,
        body: Scaffold(
          backgroundColor: val ? darkBackground : lightBackground,
          drawer: null,
          body: drawerSide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //dont remove the side bar from the sized box
                    Expanded(child: QueueCard()),
                    SizedBox(width: 200, child: SideBart()),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //dont remove the side bar from the sized box

                    SizedBox(width: 200, child: SideBart()),
                    Expanded(child: QueueCard()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget QueueCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        //Image picker and the resulting image
        Expanded(child: nextOne()),
        Expanded(child: List()),
      ],
    );
  }

  Widget nextOne() {
    return Column(
      children: [
        Card(
          color: val ? greyBackground : Colors.white,
          child: Column(
            children: [
              Row(children: [
                const Expanded(child: Divider()),
                Text(
                  "Next Image",
                  style: TextStyle(color: val ? Colors.white : Colors.black),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(
                height: 20,
              ),
              imageLocationList.isEmpty
                  ? Image.network(
                      'https://www.russorizio.com/wp-content/uploads/2016/07/ef3-placeholder-image-300x203.jpg',
                      height: 193,
                    )
                  : Image.file(imageLocationList[0]),
              const SizedBox(
                height: 60,
              ),
            ],
          ),
        ),
        Card(
          color: val ? greyBackground : Colors.white,
          child: Column(
            children: [
              Row(children: [
                const Expanded(child: Divider()),
                Text(
                  "Image Information",
                  style: TextStyle(color: val ? Colors.white : Colors.black),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Text(
                    "Image Name: ",
                    style: TextStyle(
                      color: val ? Colors.white : Colors.black,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    imageNameList.isNotEmpty ? imageNameList[0] : 'none',
                    style: TextStyle(
                      color: val ? Colors.white : Colors.black,
                      fontSize: 20,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Text(
                    "Total Drones: ",
                    style: TextStyle(
                      color: val ? Colors.white : Colors.black,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    imageDroneList.isNotEmpty
                        ? imageDroneList[0].toString()
                        : 'none',
                    style: TextStyle(
                      color: val ? Colors.white : Colors.black,
                      fontSize: 20,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Text(
                    "Min Distance: ",
                    style: TextStyle(
                      color: val ? Colors.white : Colors.black,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    imageDistanceList.isNotEmpty
                        ? imageDistanceList[0]
                        : 'none',
                    style: TextStyle(
                      color: val ? Colors.white : Colors.black,
                      fontSize: 20,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget List() {
    return Column(
      children: [
        Card(
          color: val ? greyBackground : Colors.white,
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Text(
                "Image List",
                style: TextStyle(color: val ? Colors.white : Colors.black),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
        Expanded(
          // this is the list that holds all the next images
          //it needs to be a reorderable list to change the index of images
          child: ReorderableListView(
              shrinkWrap: true,
              children: <Widget>[
                for (int index = 0; index < imageNameList.length; index += 1)
                  Card(
                    color: val ? greyBackground : Colors.white,
                    key: Key('$index'),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      title: Text(imageNameList[index]),
                      trailing: IconButton(
                        tooltip: 'Delete',
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Would You Like to Delete This?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context, 'No'),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, 'Yes');
                                  setState(() {
                                    imageNameList.remove(imageNameList[index]);
                                    imageLocationList
                                        .remove(imageLocationList[index]);
                                    imageDroneList
                                        .remove(imageDroneList[index]);
                                    imageDistanceList
                                        .remove(imageDistanceList[index]);
                                  });
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final String item = imageNameList.removeAt(oldIndex);
                  final File flop = imageLocationList.removeAt(oldIndex);
                  final int sparky = imageDroneList.removeAt(oldIndex);
                  final String dis = imageDistanceList.removeAt(oldIndex);
                  imageNameList.insert(newIndex, item);
                  imageLocationList.insert(newIndex, flop);
                  imageDroneList.insert(newIndex, sparky.round());
                  imageDistanceList.insert(newIndex, dis);
                });
              }),
        ),
      ],
    );
  }
}

class SideBart extends StatefulWidget {
  @override
  _SideBar createState() => _SideBar();
}

class _SideBar extends State<SideBart> {
  TextEditingController editingController = TextEditingController();
  final duplicateItems = <String>[
    'Coordinate Settings',
    'Dark Mode',
    'General Settings',
    'Simulation Settings'
  ];
  var items = <String>[];
  @override
  void initState() {
    items = duplicateItems;
    super.initState();
  }

  void filterSearchResults(String query) {
    setState(() {
      items = duplicateItems
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: val ? ThemeData.dark() : ThemeData.light(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: sidePanel()));
  }

  Widget sidePanel() {
    return Scaffold(
      backgroundColor: val ? darkBackground : lightBackground,
      body: Container(
        width: 200,
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(
              height: 10,
            ),
            ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.search),
                title: const Text('Search'),
                onTap: () {
                  showSearch(
                      context: context,
                      // delegate to customize the search bar
                      delegate: CustomSearchDelegate());
                }),
            const Divider(),
            ListTile(
                selected: home,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.home_rounded),
                title: const Text('Home'),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          MainCards(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                  setState(() {
                    if (home == false) {
                      home = true;
                      settings = false;
                      queue = false;
                      simulation = false;
                    }
                  });
                }),
            ListTile(
                selected: queue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.queue_rounded),
                title: const Text('Queue'),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => Queue(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                  setState(() {
                    if (queue == false) {
                      home = false;
                      settings = false;
                      queue = true;
                      simulation = false;
                    }
                  });
                }),
            ListTile(
                selected: simulation,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.video_settings_rounded),
                title: const Text('Simulation'),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          Simulation(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                  setState(() {
                    if (simulation == false) {
                      queue = false;
                      home = false;
                      settings = false;
                      simulation = true;
                    }
                  });
                }),
            const Divider(),
            ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('Help'),
                onTap: () {}),
            ListTile(
              selected: settings,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.settings),
              title: const Text('App Settings'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        AppSettings(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
                setState(() {
                  if (settings == false) {
                    queue = false;
                    home = false;
                    settings = true;
                    simulation = false;
                  }
                });
              },
            ),
            const Divider(),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.exit_to_app_rounded),
              title: const Text('Exit App'),
              onTap: () {
                exit(0);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Simulation extends StatefulWidget {
  @override
  _simulation createState() => _simulation();
}

class _simulation extends State<Simulation> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: val ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: val ? darkBackground : lightBackground,
        appBar: AppBar(
          iconTheme: IconThemeData(color: val ? Colors.white : Colors.black),
          backgroundColor: val ? Colors.transparent : Colors.blue,
          shadowColor: Colors.transparent,
          title: Text(
            "Knight Light",
            style: TextStyle(color: val ? Colors.white : Colors.black),
          ),
        ),
        drawer: null,
        body: Scaffold(
          backgroundColor: val ? darkBackground : lightBackground,
          drawer: null,
          body: drawerSide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //dont remove the side bar from the sized box
                    Flexible(child: simulationCard()),
                    SizedBox(width: 200, child: SideBart()),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //dont remove the side bar from the sized box

                    SizedBox(width: 200, child: SideBart()),
                    Flexible(child: simulationCard()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget simulationCard() {
    return Scaffold(
      backgroundColor: val ? darkBackground : lightBackground,
      body: Card(
        color: val ? greyBackground : Colors.white,
        child: Column(
          children: [
            Container(
              child: SfCartesianChart(
                // Initialize category axis
                primaryXAxis:
                    NumericAxis(visibleMinimum: 20, visibleMaximum: 51),
                primaryYAxis: NumericAxis(),
                series: <ChartSeries>[
                  // Initialize line series
                  ScatterSeries<ChartData, int>(
                      dataSource: [
                        // Bind data source
                        ChartData(25, 35),
                        ChartData(30, 28),
                        ChartData(35, 34),
                        ChartData(40, 32),
                        ChartData(50, 40)
                      ],
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y)
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FloatingActionButton.extended(
              onPressed: () {
                // Add your onPressed code here!
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Backward'),
              backgroundColor: buttonColor,
            ),
            FloatingActionButton.extended(
              onPressed: () {
                // Add your onPressed code here!
              },
              label: const Text('Forward'),
              icon: const Icon(Icons.arrow_forward_rounded),
              backgroundColor: buttonColor,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double? y;
}

class AppSettings extends StatefulWidget {
  @override
  _AppSettings createState() => _AppSettings();
}

class _AppSettings extends State<AppSettings> {
  @override
  void initState() {
    super.initState();
    setState(() {
      if (settings == false) {
        queue = false;
        home = false;
        settings = true;
        simulation = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: val ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: val ? darkBackground : lightBackground,
        appBar: AppBar(
          iconTheme: IconThemeData(color: val ? Colors.white : Colors.black),
          backgroundColor: val ? Colors.transparent : Colors.blue,
          shadowColor: Colors.transparent,
          title: Text(
            "Knight Light",
            style: TextStyle(color: val ? Colors.white : Colors.black),
          ),
        ),
        drawer: null,
        body: Scaffold(
          backgroundColor: val ? darkBackground : lightBackground,
          drawer: null,
          body: drawerSide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //dont remove the side bar from the sized box
                    Expanded(child: SettingCard()),
                    SizedBox(width: 200, child: SideBart()),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //dont remove the side bar from the sized box

                    SizedBox(width: 200, child: SideBart()),
                    Expanded(child: SettingCard()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget SettingCard() {
    return Column(
      children: [
        Expanded(
          child: Card(
            color: val ? greyBackground : Colors.white,
            child: Column(
              children: [
                Row(children: <Widget>[
                  const Expanded(child: Divider()),
                  Text(
                    "General Settings",
                    style: TextStyle(color: val ? Colors.white : Colors.black),
                  ),
                  const Expanded(child: Divider()),
                ]),
                SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(color: val ? Colors.white : Colors.black),
                  ),
                  value: val,
                  onChanged: (value) {
                    setState(() {
                      val = !val;
                    });
                  },
                  secondary: val
                      ? Icon(
                          Icons.dark_mode,
                          color: val ? Colors.white : null,
                        )
                      : Icon(
                          Icons.light_mode,
                          color: val ? Colors.white : null,
                        ),
                ),
                SwitchListTile(
                  title: Text(
                    'Flip Drawer side',
                    style: TextStyle(color: val ? Colors.white : Colors.black),
                  ),
                  value: drawerSide,
                  onChanged: (value) {
                    setState(() {
                      drawerSide = !drawerSide;
                    });
                  },
                  secondary: drawerSide
                      ? Icon(
                          Icons.arrow_forward_rounded,
                          color: val ? Colors.white : null,
                        )
                      : Icon(
                          Icons.arrow_back_rounded,
                          color: val ? Colors.white : null,
                        ),
                ),
                SwitchListTile(
                  title: Text(
                    'Weather Info',
                    style: TextStyle(color: val ? Colors.white : Colors.black),
                  ),
                  value: weather,
                  onChanged: (value) {
                    setState(() {
                      weather = !weather;
                    });
                  },
                  secondary: weather
                      ? Icon(
                          Icons.cloud_queue_rounded,
                          color: val ? Colors.white : null,
                        )
                      : Icon(
                          Icons.cloud_off_rounded,
                          color: val ? Colors.white : null,
                        ),
                ),
                SwitchListTile(
                  title: Text(
                    'Show Time',
                    style: TextStyle(color: val ? Colors.white : Colors.black),
                  ),
                  value: time,
                  onChanged: (value) {
                    setState(() {
                      time = !time;
                    });
                  },
                  secondary: time
                      ? Icon(
                          Icons.timer_outlined,
                          color: val ? Colors.white : null,
                        )
                      : Icon(
                          Icons.timer_off_outlined,
                          color: val ? Colors.white : null,
                        ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Card(
            color: val ? greyBackground : Colors.white,
            child: Column(
              children: [
                Row(children: <Widget>[
                  const Expanded(child: Divider()),
                  Text(
                    "Simulation Settings",
                    style: TextStyle(color: val ? Colors.white : Colors.black),
                  ),
                  const Expanded(child: Divider()),
                ]),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.access_time_rounded,
                      color: val ? Colors.white : null,
                    ),
                    Text(
                      'Simulation Speed:',
                      style:
                          TextStyle(color: val ? Colors.white : Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//search bar
class CustomSearchDelegate extends SearchDelegate {
  // Demo list to show querying
  List<String> searchTerms = [
    "Dark Mode",
    "Coordinate Settings",
    "Simulation Settings",
    "General Settings",
  ];

  // first overwrite to
  // clear the search text
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

  // second overwrite to pop out of search menu
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  // third overwrite to show query result
  @override
  Widget buildResults(BuildContext context) {
    List<String> matchQuery = [];
    for (var fruit in searchTerms) {
      if (fruit.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(fruit);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(result),
        );
      },
    );
  }

  // last overwrite to show the
  // querying process at the runtime
  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var fruit in searchTerms) {
      if (fruit.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(fruit);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        var result = matchQuery[index];
        return ListTile(
          title: Text(result),
          onTap: () {
            if (result == "Coordinate Settings") {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) => MainCards(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      AppSettings(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
        );
      },
    );
  }
}

//val changes the dark mode
bool val = true;

//this changes what side the drawer is on
bool drawerSide = false;

//this is for displaying weather info
bool weather = false;

//this sis for displaying time
bool time = false;

// these are for highlighting what tab you are on
bool home = true;
bool settings = false;
bool queue = false;
bool simulation = false;

//color stuff
const greyBackground = Color(0xFF424242);
const darkBackground = Color(0xFF303030);
const lightBackground = Color(0xFFbbbcc7);
const lightForeGround = Color(0xFFd0d1db);
const buttonColor = Color(0xFF18bec7);
