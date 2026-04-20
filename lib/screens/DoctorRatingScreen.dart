import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DoctorRatingScreen extends StatefulWidget {
  const DoctorRatingScreen({super.key});

  @override
  State<DoctorRatingScreen> createState() => _DoctorRatingScreenState();
}

class _DoctorRatingScreenState extends State<DoctorRatingScreen> {

  final List<Map<String,String>> doctors = [
    {"name":"Dr. Ananya Sharma","spec":"Cardiologist"},
    {"name":"Dr. Pavithra","spec":"Surgeon"},
    {"name":"Dr. Sneha Iyer","spec":"Pediatrician"},
    {"name":"Dr. Aditya Rao","spec":"General Physician"},
    {"name":"Dr. Kavya Nair","spec":"Dermatologist"},
    {"name":"Dr. Arjun Patel","spec":"Orthopedic"},
    {"name":"Dr. Kausika","spec":"Gynecologist"},
  ];

  Map<String,dynamic>? selectedDoctor;

  Map<String,double> avgRatings = {};
  Map<String,int> ratingCounts = {};

  double comm=0,treat=0,wait=0,staff=0,clean=0,overall=0;

  @override
  void initState() {
    super.initState();
    loadRatings();
  }

  /// LOAD SAVED RATINGS
  Future<void> loadRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("doctor_ratings");

    if(data!=null){
      final decoded = jsonDecode(data);
      avgRatings = Map<String,double>.from(decoded["avg"]);
      ratingCounts = Map<String,int>.from(decoded["count"]);
      setState(() {});
    }
  }

  /// SAVE RATINGS
  Future<void> saveRatings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("doctor_ratings",
        jsonEncode({"avg":avgRatings,"count":ratingCounts}));
  }

  /// ⭐ SUBMIT RATING
  void submitRating(){
    final name = selectedDoctor!["name"];
    final newRating = (comm+treat+wait+staff+clean+overall)/6;

    final oldAvg = avgRatings[name] ?? 0;
    final oldCount = ratingCounts[name] ?? 0;

    final updatedAvg = ((oldAvg * oldCount) + newRating) / (oldCount + 1);

    avgRatings[name!] = updatedAvg;
    ratingCounts[name] = oldCount + 1;

    saveRatings();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Rating Submitted ⭐")));

    /// Reset stars & go back
    setState(() {
      selectedDoctor = null;
      comm=0;
      treat=0;
      wait=0;
      staff=0;
      clean=0;
      overall=0;
    });
  }

  /// ⭐ OPEN DOCTOR → ALWAYS RESET STARS
  void openDoctor(Map<String,String> doc){
    setState(() {
      selectedDoctor = doc;
      comm=0;
      treat=0;
      wait=0;
      staff=0;
      clean=0;
      overall=0;
    });
  }

  Widget stars(double value,Function(double) onTap){
    return Row(
      children: List.generate(5,(i)=>IconButton(
        icon:Icon(Icons.star,color:i<value?Colors.amber:Colors.grey),
        onPressed:()=>setState(()=>onTap(i+1.0)),
      )),
    );
  }

  Widget ratingCard(String title,double val,Function(double) setVal){
    return Card(
      child:Padding(
        padding:EdgeInsets.all(12),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text(title,style:TextStyle(fontWeight:FontWeight.bold)),
            stars(val,setVal)
          ],
        ),
      ),
    );
  }

  /// Doctor list with avg rating ⭐
  Widget doctorList(){
    return Column(
      children: doctors.map((doc){
        final rating = avgRatings[doc["name"]] ?? 0;

        return Card(
          child:ListTile(
            leading:CircleAvatar(child:Icon(Icons.person)),
            title:Text(doc["name"]!),
            subtitle:Text(doc["spec"]!),
            trailing:Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                Text(rating==0
                    ? "No ratings"
                    : "${rating.toStringAsFixed(1)} ⭐"),
                ElevatedButton(
                  onPressed:()=>openDoctor(doc),
                  child:Text("Rate"),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget ratingUI(){
    return Column(children:[
      Text(selectedDoctor!["name"]!,
          style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),

      ratingCard("Communication",comm,(v)=>comm=v),
      ratingCard("Treatment",treat,(v)=>treat=v),
      ratingCard("Waiting Time",wait,(v)=>wait=v),
      ratingCard("Staff",staff,(v)=>staff=v),
      ratingCard("Cleanliness",clean,(v)=>clean=v),
      ratingCard("Overall",overall,(v)=>overall=v),

      SizedBox(height:10),
      ElevatedButton(
        onPressed: submitRating,
        style:ElevatedButton.styleFrom(backgroundColor:Colors.teal),
        child:Text("Submit Rating"),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(title:Text("Doctor Ratings"),backgroundColor:Colors.teal),
      body:SingleChildScrollView(
        padding:EdgeInsets.all(16),
        child:selectedDoctor==null?doctorList():ratingUI(),
      ),
    );
  }
}
