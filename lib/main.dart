import 'package:age/age.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:date_range_picker/date_range_picker.dart' as DateRagePicker;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Residency Obligation ',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Calculate remaining days'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ResidentDuration> durations;

  DateTime selectedDate;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    durations = List();
    selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: buildBodyView(size),
    );
  }

  Padding buildBodyView(Size size) {
    return Padding(
      padding: EdgeInsets.only(left: size.width * .05, right: size.width * .05),
      child: ListView(
        children: <Widget>[
          buildDurationsListView(size),
          buildDatePickGesture(),
          buildCalculateButton(), //
        ],
      ),
    );
  }

  Padding buildCalculateButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: RaisedButton(
        onPressed: () => calculate(),
        child: Text('Calculate'),
      ),
    );
  }

  calculate() {
    List<ResidentDuration> copy = getSorted();
    int days = 0;
    int first = 0;
    for (int i = 0; i < copy.length; i++) {
      ResidentDuration current = copy[i];
      if (Age.dateDifference(
                  fromDate: copy[first]._arrivalDate,
                  toDate: current._leaveDate)
              .years >
          4) {
        days -= getNumOfDaysBetween(copy[first]);
        i--;
        first++;
        continue;
      }

      days += getNumOfDaysBetween(current);
      if (days >= 730) {
        var data = 'Accepted';
        showAlertDialog(data);
        return;
      }
    }
   showAlertDialog('Rejected');
  }

  Future showAlertDialog(String data) {
    return showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
                title: Text(data),
              );
          });
  }

  List<ResidentDuration> getSorted() {
    List<ResidentDuration> copy = durations.toList();
    copy.sort((a, b) {
      return a._arrivalDate.compareTo(b._arrivalDate);
    });
    return copy;
  }

  int getNumOfDaysBetween(ResidentDuration current) {
    return current._arrivalDate.difference(current._leaveDate).abs().inDays;
  }

  GestureDetector buildDatePickGesture() {
    return GestureDetector(
      onTap: () => showRangeDatePicker(),
      child: Row(
        children: <Widget>[
          Icon(Icons.calendar_today),
          Text(
            DateFormat.yMMMd().format(selectedDate),
          ),
        ],
      ),
    );
  }

  SizedBox buildDurationsListView(Size size) {
    return SizedBox(
      height: size.height * .6,
      width: size.width * 0.9,
      child: ListView.builder(
        itemBuilder: (context, index) => buildDurationViewRow(index),
        itemCount: durations.length,
      ),
    );
  }

  Row buildDurationViewRow(int index) {
    return Row(
      children: <Widget>[
        Expanded(
            child: Text(
                DateFormat.yMMMEd().format(durations[index]._arrivalDate))),
        Text(DateFormat.yMMMEd().format(durations[index]._leaveDate))
      ],
    );
  }

  showRangeDatePicker() async {
    final List<DateTime> picked = await DateRagePicker.showDatePicker(
        context: context,
        initialFirstDate: new DateTime.now(),
        initialLastDate: (new DateTime.now()).add(new Duration(days: 7)),
        firstDate: new DateTime(1990),
        lastDate: new DateTime(2100));
    checkAndAddDuration(picked);
  }

  void checkAndAddDuration(List<DateTime> picked) {
    if (picked != null && picked.length == 2) {
      bool isViolatedDuration = false;
      durations.forEach((element) {
        if (element._arrivalDate.isBefore(picked[1]) &&
            element._leaveDate.isAfter(picked[0])) isViolatedDuration = true;
      });
      if (!isViolatedDuration)
        setState(() {
          durations.add(ResidentDuration(picked[0], picked[1]));
        });
      else
        buildErrorDialog();
    }
  }

  Future buildErrorDialog() {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text('can\'t add duration'),
            content: Text(
                'this duration is partly or fully included with previous duration')));
  }
}

class ResidentDuration {
  DateTime _arrivalDate;
  DateTime _leaveDate;

  ResidentDuration(this._arrivalDate, this._leaveDate);
}
