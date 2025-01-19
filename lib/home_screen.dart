import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import './style.dart' as style;
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({Key? key, this.targetCharacteristicR, this.targetCharacteristicW,
    this.targetdevice, this.deviceState, this.con, this.disconnect, this.connectLoding, this.blueconnect, this.decodeValue}) : super(key: key);

  final decodeValue;
  final targetCharacteristicR;
  final targetCharacteristicW;
  final targetdevice;
  final deviceState;
  final con;
  final disconnect;
  final connectLoding;
  final blueconnect;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  bool alarm = true;
  int presentState = 0;   //3,2,1 팔자 0 정상 -1,-2,-3 안짱
  final List<double> nullwalkData = [1,0,0,0,0];      //데이터가 올바르지 않을 때 표현해줄 데이터
  boxdesign(con) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20), //모서리를 둥글게
      color: con ? Color.fromRGBO(255, 255, 255, 1.0) : Color.fromRGBO(
          245, 245, 245, 1),
    ); //테두리
  }


  //내장 데이터 관련 코드


  String today = DateFormat('yyyyMMdd').format(DateTime.now()).toString();

  Map <String, List<double>> value = { //매일매일의 데이터를 꺼내 담아두는 변수

  };

  printData(date) async {   //내장 데이터에서 value 변수에 필요한 날짜의 데이터를 이동
    var storage = await SharedPreferences.getInstance();
    var result = storage.getString('daily') ?? 'xxx';
    if (result == 'xxx') {
      return;
    } else {
      if(jsonDecode(result)[date] == null) return;
      value[date] = (jsonDecode(result)[date].cast<double>());
    }
    return;
  }
  //내장 데이터 관련 코드

  List<int> incodeMotorValue(int value) {        //입력값을 바탕으로 모터의 움직임을 제어할 정수를 반환
    int t = 0;
    if(value >= 8) {
      t = 2;
      value -= 8;
    }
    if(value >= 0) {return [value,t,0];}
    else {return [0,t, -value];}
  }

  /* 기준 코드 */
  int walkCategory (List<double> value) {   //비율 데이터를 입력받고 걸음 유형을 반환하는 함수(기울기를 이용)

    if(value[2] * 100 >= 16.5 && value[3] * 100 >= 13){ //평발
      //3과 4의 기울기
      double num1 = value[3] - value[2];
      List<double> line1 = [7.4, 1.9, -3.7, -20.21, -31.2, -42, -99999];
      int res = 0;

      for(int i = 3; i >= -3; i--) {
        if(num1*100 >= line1[3-i]) {res += i; break;}
      }
      //4와 5의 기울기
      double num2 = value[4] - value[3];
      List<double> line2 = [-7.6, -11.4, -15, -24, -29, -34, -99999];

      for(int i = -3; i <= 3; i++) {
        if(num2*100 >= line2[3+i]) {res += i; break;}
      }
      return res + 15;
    } else { //평발 아닌 경우
      //1과 2의 기울기
      double num1 = value[1] - value[0];
      List<double> line1 = [31, 22, 13.5, 2, -1, -5.7, -99999];
      int res = 0;

      for(int i = 3; i >= -3; i--) {
        if(num1*100 >= line1[3-i]) {res += i; break;}
      }
      //4와 5의 기울기
      double num2 = value[4] - value[3];
      List<double> line2 = [31.9, 28, 24, 14.5, 8.5, 2.7, -99999];

      for(int i = -3; i <= 3; i++) {
        if(num2*100 >= line2[3+i]) {res += i; break;}
      }
      return res;
    }
  }

  writeData(String data) async {                   //string data를 입력하면 블루투스 모듈로 전송
    if (widget.targetCharacteristicW == null) return;

    List<int> bytes = utf8.encode(data);
    print("bytes recieved ${bytes} ");
    print("쓰기 속성 ${widget.targetCharacteristicW!.properties.write}");
    await widget.targetCharacteristicW!.write(bytes, withoutResponse: true);
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;

    return Scaffold(
      backgroundColor: style.commonbackground_con(widget.con()),
      appBar: AppBar(
        title: Text('Smart Shoes'),
        actions: [IconButton(    //알람버튼으로 알림 기능을 끄고 킬 수 있도록
            onPressed: () => setState(() => alarm = !alarm),
            icon: alarm ? Icon(Icons.notifications) : Icon(Icons.notifications_off)
        ),],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.con() ? Container(              //상단부 연결 버튼 라인의 코드 (연결 되었을 때)
            width: double.infinity,
            color: style.commonbackground_con(widget.con()),
            child: ListTile(
                title: Text('스마트 신발 연결을 해제합니다', style: style.commontext),
                trailing: TextButton(onPressed: (){
                  widget.disconnect();  //해제 버튼 누르면 연결 해제
                }, child: Text('해제', style: TextStyle(fontWeight: FontWeight.w900)),)
            ),
          )
              : Container(                         //상단부 연결 버튼 라인의 코드 (연결이 되지 않았을 때)
            width: double.infinity,
            color: style.commonbackground_con(widget.con()),
            child: ListTile(
                title: Text('스마트 신발을 연결해주세요', style: style.commontext),
                trailing: widget.connectLoding ? CircularProgressIndicator()        //연결할 때 로링 중이라면 로딩중 표현
                    : TextButton(onPressed: (){
                  widget.blueconnect('HC-06', context);       //HC-06 블루투스 모듈 기준
                }, child: Text('연결', style: TextStyle(fontWeight: FontWeight.w900)),)
            ),
          ),
          //Padding(padding: EdgeInsets.all(10)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding : EdgeInsets.all(10),
                  //height: height * 0.5,
                  width: double.infinity,
                  decoration: boxdesign(widget.con()),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [                    //내 신발과 신발 사진 부분 코드

                      Text('내 신발', style: style.commontext,),

                      widget.con() ? StreamBuilder<List<int>>(
                          stream: widget.targetCharacteristicR!.value,
                          initialData: widget.targetCharacteristicR!.lastValue,
                          builder: (c, snapshot) {
                            List<int>? walkData = snapshot.data;
                            print((walkData ?? [0]).toString());
                            List<double> walkEncodeData = widget.decodeValue(walkData ?? [0]);
                            return style.shoes(walkEncodeData != [] && walkEncodeData.length == 5 ? walkEncodeData : nullwalkData, height, width); //데이터가 올바른지 확인 후 그림으로 표현
                            //Text((walkEncodeData == []  ? [0] : walkEncodeData).toString());
                          }
                      )
                          : Image.asset('assets/shoes_unconnected.png',height: height * 0.3, width: double.infinity,),  //블루투스가 연결되지 않았을 경우
                    ],
                  ),
                ),
                Padding(padding: EdgeInsets.all(10)),
                Container(               //걸음걸이의 유형에 맞는 문구 출력하는 부분
                  alignment: Alignment.centerLeft,
                  padding : EdgeInsets.all(13),
                  height: 100, width: double.infinity,
                  decoration: boxdesign(widget.con()),
                  child: widget.con() ? StreamBuilder<List<int>>(
                      stream: widget.targetCharacteristicR!.value,
                      initialData: widget.targetCharacteristicR!.lastValue,
                      builder: (c, snapshot) {
                        List<int>? walkData = snapshot.data;
                        List<double> walkEncodeData = widget.decodeValue(walkData ?? [0]);
                        presentState = walkCategory(walkEncodeData.length != 5 ? nullwalkData : walkEncodeData);
                        return Text(style.categoryInfo[presentState + 7], style: style.infotext,);
                        //Text((walkEncodeData == []  ? [0] : walkEncodeData).toString());
                      }
                  )
                      : Text('연결해주세요'),  //블루투스 연결되지 않았을 경우 연결해주세요 출력


                ),
                Padding(padding: EdgeInsets.all(10)),
                GestureDetector(      //신발 조정하기 버튼 부분
                  onTap: () { if(widget.con()) {showDialog(context: context, builder: (context) {  printData(today); return AdjustDialog(writeData: writeData,
                    incodeMotorValue: incodeMotorValue, walkCategory: walkCategory, value: value,);});}}, //블루투스 연결이 되었을 경우에만 이용가능
                  child: Container(
                      padding : EdgeInsets.all(13),
                      width: double.infinity,
                      decoration: boxdesign(widget.con()),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: Icon(Icons.star),
                          ),
                          Text('신발 조정하기', style: style.commontext),
                        ],
                      )
                  ),
                ),
                Padding(padding: EdgeInsets.all(10)),
                GestureDetector(    //Smart Shoes 정보 버튼 부분
                  onTap: () => showDialog(context: context, builder: (context) => InfoDialog()),
                  child: Container(
                      padding : EdgeInsets.all(13),
                      width: double.infinity,
                      decoration: boxdesign(widget.con()),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: Icon(Icons.info),
                          ),
                          Text('Smart Shoes 정보', style: style.commontext),
                        ],
                      )
                  ),
                ),
                // Padding(padding: EdgeInsets.all(8)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class InfoDialog extends StatelessWidget {   //Smart Shoes 정보 버튼 눌렸을 때 이용될 Dialog
  const InfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.star),
          Padding(padding: EdgeInsets.all(8)),
          Text('Smart Shoes'),
          Padding(padding: EdgeInsets.all(8)),
          Text('버전 1.0.0'),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: EdgeInsets.all(8),
      actions: [
        TextButton(
          child: Text("Cancel"),   //닫기 버튼
          onPressed: (){Navigator.pop(context);},
        ),
      ],
    );
  }
}

class AdjustDialog extends StatefulWidget {   //신발 조정하기 버튼 눌렸을울 때 이용될 Dialog
  const AdjustDialog({Key? key, this.writeData, this.incodeMotorValue, this.walkCategory, this.value}) : super(key: key);

  final value;
  final writeData;
  final incodeMotorValue;
  final walkCategory;

  @override
  State<AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<AdjustDialog> {
  @override
  Widget build(BuildContext context) {

    String today = DateFormat('yyyyMMdd').format(DateTime.now()).toString();

    List<int> motorvalue = [0,0,0];
    var elevatestyle = ElevatedButton.styleFrom(primary: style.commonbackground);
    if(widget.value.containsKey(today)) motorvalue = widget.incodeMotorValue( widget.walkCategory(widget.value[today]));  //motor 가동되는 초 계산해서 motorvalue 변수에 입력력


    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: SizedBox(
        height: 70,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if(motorvalue[0] != 0) Text(motorvalue[0].toString() + '초'),   //0초가 아닐 경우만 버튼 표현
                if(motorvalue[1] != 0) Text(motorvalue[1].toString() + '초'),
                if(motorvalue[2] != 0) Text(motorvalue[2].toString() + '초'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if(motorvalue[0] != 0) ElevatedButton(onPressed: () { widget.writeData(motorvalue[0].toString());}, child: Text('1번', style: style.commontext,), style: elevatestyle),
                if(motorvalue[1] != 0) ElevatedButton(onPressed: () { widget.writeData(motorvalue[1].toString());}, child: Text('2번', style: style.commontext,), style: elevatestyle),
                if(motorvalue[2] != 0) ElevatedButton(onPressed: () { widget.writeData(motorvalue[2].toString());}, child: Text('3번', style: style.commontext,), style: elevatestyle),
                if(motorvalue[0] == 0 && motorvalue[1] == 0 && motorvalue[2] == 0) Text(widget.value.containsKey(today) ? '걸음걸이가 완벽합니다' : '데이터를 더 모아오세요') //버튼이 없을 때의 text
              ],
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: EdgeInsets.all(-5),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: (){Navigator.pop(context);},
        ),
      ],
    );
  }
}
