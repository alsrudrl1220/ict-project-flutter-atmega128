import 'package:flutter/material.dart';
import './style.dart' as style;

class DoctorInfo extends StatefulWidget {
  const DoctorInfo({Key? key}) : super(key: key);

  @override
  State<DoctorInfo> createState() => _DoctorInfoState();
}

class _DoctorInfoState extends State<DoctorInfo> {

  int currentInfo = 0;

  List<List<String>> healthInfo = [        //건강에 관한 정보들
    ['8자 걸음', '요통과 허리디스크를 유발합니다\n8자 걸음\n길게길게 적어요'],
    ['O다리 걸음', '무릎과 인대가 손상됩니다'],
    ['안짱 걸음', '고관절염이 걸릴 수 있어요'],
    ['일자 걸음','관절이 변형될 수 있으니 조심해요'],
  ];

  var boxdesign = BoxDecoration(
    borderRadius: BorderRadius.circular(20), //모서리를 둥글게
    color: Color.fromRGBO(255, 255, 255, 1.0),
  ); //테두리

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: style.commonbackground,
      appBar: AppBar(
        title: Text('의학 정보'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              padding : EdgeInsets.all(10),
              width: double.infinity,
              decoration: boxdesign,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(healthInfo[currentInfo][0], style: TextStyle(fontSize: 25)),
                    Padding(padding: EdgeInsets.all(5)),
                    Text(healthInfo[currentInfo][1], style: style.commontext,),
                  ],
                ),
              )

          ),
          Container(),
        ],
      ),
      endDrawer: Drawer(       //보고 싶은 정보 선택 할 수 있도록
        child: ListView.builder(
            itemCount: healthInfo.length,
            itemBuilder: (c,i) {
              return ListTile(
                leading: Icon(Icons.home),
                title: Text(healthInfo[i][0]),
                onTap: () {
                  setState(() => currentInfo = i);
                  Navigator.pop(context);
                },
              );
            }
        ),
      ),
    );
  }
}
