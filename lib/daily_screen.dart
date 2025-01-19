import 'package:flutter/material.dart';
import './style.dart' as style;
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Daily extends StatefulWidget {
  const Daily({Key? key}) : super(key: key);

  @override
  State<Daily> createState() => _DailyState();
}

class _DailyState extends State<Daily> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    printData(printData(DateFormat('yyyyMMdd').format(DateTime.now()).toString()));
  }  //오늘의 데이터를 내장데이터에서 value로 꺼내둠

  // var storage;
  final List<double> nullwalkData = [1,0,0,0,0];

  Map <String, List<double>> value = {  //매일매일의 데이터를 꺼내 담아두는 변수

  };

  printData(date) async {     //내장 데이터에서 value 변수에 필요한 날짜의 데이터를 이동
    var storage = await SharedPreferences.getInstance();
    var result = storage.getString('daily') ?? 'xxx';
    if (result == 'xxx') {
      return 0;
    } else {
      if(jsonDecode(result)[date] == null) return 0;

      setState(() {
        value[date] = (jsonDecode(result)[date].cast<double>());
      });
    }
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
      print(num2);
      List<double> line2 = [-7.6, -11.4, -15, -24, -29, -34, -99999];

      for(int i = -3; i <= 3; i++) {
        if(num2*100 >= line2[3+i]) {res += i; break;}
      }

      return res + 15;
    } else { //평발이 아닐 때
      //1과 2의 기울기
      double num1 = value[1] - value[0];
      List<double> line1 = [31, 22, 13.5, 2, -1, -5.7, -99999];
      int res = 0;

      for(int i = 3; i >= -3; i--) {
        if(num1*100 >= line1[3-i]) {res += i; break;}
      }

      //4와 5의 기울기
      double num2 = value[4] - value[3];
      print(num2);
      List<double> line2 = [31.9, 28, 24, 14.5, 8.5, 2.7, -99999];

      for(int i = -3; i <= 3; i++) {
        if(num2*100 >= line2[3+i]) {res += i; break;}
      }

      return res;
    }
  }


  ItemScrollController itemScrollController = ItemScrollController();  //스크롤을 자동으로 이동해주기 위해 필요한 변수
  DateTime _selectedDate = DateTime(   //선택된 날짜를 저장해두는 변수
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );


  var boxdesign = BoxDecoration(
    borderRadius: BorderRadius.circular(20), //모서리를 둥글게
    color: Color.fromRGBO(255, 255, 255, 1.0),
  ); //테두리
  DateTime scrollStartDay = DateTime(DateTime.now().year);
  DateTime scrollFinalDay = DateTime(  //스크롤 되는 숫자의 범위
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  void moveScroll(currentScroll) {       //스크롤을 자동으로 이동해주는 함수
    itemScrollController.scrollTo(index: currentScroll,
        duration: Duration(milliseconds: 700), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;

    return Scaffold(
      backgroundColor: style.commonbackground,
      appBar: AppBar(
        title: Text('Daily Info'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 50,
            child: ScrollablePositionedList.builder(     //여러개의 숫자 탭 생성(여러 날짜 참조할 수 있도록)
                reverse: true,
                itemScrollController: itemScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: int.parse(DateTime.now().difference(scrollStartDay).inDays.toString()) + 1,
                itemBuilder: (c,i) {
                  DateTime currenttab = scrollFinalDay.subtract(Duration(days: i));
                  bool _selectedTrue = (_selectedDate == currenttab);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = currenttab;
                        moveScroll(i);
                      });
                    },
                    child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular((30))),
                          color: _selectedTrue ? Colors.white : style.commonbackground,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: currenttab.day != 1
                              ? Text(DateFormat('d').format(currenttab), style: style.commontext,)
                              : Text(DateFormat('M/d').format(currenttab), style: style.commontext,),   //매달의 1일에는 달도 표현(클라이언트로 하여금 알아보기 쉽게)
                        )
                    ),
                  );
                }
            ),
          ),
          //Padding(padding: EdgeInsets.all(10)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding : EdgeInsets.all(10),
                  //height: 450,
                  width: double.infinity,
                  decoration: boxdesign,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ListTile(
                          title: GestureDetector(
                              onTap: () {
                                Future<DateTime?> selected = showDatePicker(       //날짜 클릭하면 달력 이용 가능
                                  context: context,
                                  initialDate: _selectedDate, // 초깃값
                                  firstDate: DateTime(DateTime.now().year), // 시작일
                                  lastDate: DateTime.now(), // 마지막일
                                );
                                selected.then ((dateTime) { setState(() {
                                  _selectedDate = dateTime ?? DateTime.now();});

                                moveScroll(int.parse(DateTime.now().difference(_selectedDate).inDays.toString()));
                                printData(DateFormat('yyyyMMdd').format(_selectedDate).toString());
                                });
                              },
                              child: Text(DateFormat('yyyy년 M월 d일 (E)').format(_selectedDate), style: style.commontext)
                          ),
                        ),
                      ),
                      Padding(padding: EdgeInsets.all(8)),
                      style.shoes(value.containsKey(DateFormat('yyyyMMdd').format(_selectedDate).toString()) ?
                      (value[DateFormat('yyyyMMdd').format(_selectedDate).toString()] ?? nullwalkData) : nullwalkData, height, width),    //참조한 날의 걸음 데이터 평균내서 그림에 표현
                    ],
                  ),
                ),
                Padding(padding: EdgeInsets.all(10)),
                Container(                 //참조한 날의 걸음걸이 유형 출력
                  alignment: Alignment.centerLeft,
                  padding : EdgeInsets.all(13),
                  height: 100, width: double.infinity,
                  decoration: boxdesign,
                  child: Text(style.categoryInfo[walkCategory(value.containsKey(DateFormat('yyyyMMdd').format(_selectedDate).toString()) ?
                  (value[DateFormat('yyyyMMdd').format(_selectedDate).toString()] ?? nullwalkData) : nullwalkData) + 7], style: style.infotext,),)

              ],
            ),
          )
        ],
      ),
    );
  }
}
