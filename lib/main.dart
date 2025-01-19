import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import './doctor_info_screen.dart' as doctorinfo;
import './style.dart' as style;
import './home_screen.dart' as home;
import './daily_screen.dart' as daily;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
      MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('ko', 'KR'),           //daily_screen의 달력 한글을 지원
          ],
          theme: style.theme,
          home: MyApp()
      )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  List<double>? walkEncodeData;

  List<double> decodeValue(List<int> value) {     //전송받은 값을 해석하여 5개의 double값으로 반환 (비율로 전환)
    if(value == [0] || value.length != 5) return [];

    List<double> res = [0, 0, 0, 0, 0];
    double total = 0;
    for (int i = 0; i < 5; i++) {
      total += value[i];
    }

    for (int i = 0; i < 5; i++) {
      res[i] = value[i] / total;
    }
    return res;
  }

  saveData(d) async {                                 //실시간으로 받는 걸음 데이터를 스마트폰 내장 데이터에 업데이트 (평균으로 저장)
    var storage = await SharedPreferences.getInstance();
    var dailyResult = jsonDecode(storage.getString('daily') ?? jsonEncode({}));
    var countResult = jsonDecode(storage.getString('count') ?? jsonEncode({}));          //daily데이터와 count데이터 참조

    String today = DateFormat('yyyyMMdd').format(DateTime.now());            //오늘의 날짜를 key값으로 가지는 데이터에 업데이트

    if(!dailyResult.containsKey(today)) dailyResult[today] = [0,0,0,0,0];
    if(!countResult.containsKey(today)) countResult[today] = 0;              //null값 체크

    var todayData = [];
    for(int i = 0; i < 5; i++){

      double tD = (dailyResult[today][i] * countResult[today] + d[i]) / (countResult[today] + 1);    //평균 계산하는 식
      todayData.add(tD);
    }

    dailyResult[today] = todayData;
    countResult[today]++;                //한번 업데이트 할 때마다 count데이터를 하나씩 늘림

    storage.setString('daily', jsonEncode(dailyResult));
    storage.setString('count', jsonEncode(countResult));

  }

  //블루투스 코드
  bool connectLoding = false;        //블루투스 연결 로딩 중인가

  bool con()    //블루투스 연결이 되었는가
  {
    return deviceState == BluetoothDeviceState.connected;
  }


  FlutterBlue flutterBlue = FlutterBlue.instance;

  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;
  StreamSubscription<BluetoothDeviceState>? _stateListener;
  BluetoothDevice? targetdevice;
  BluetoothCharacteristic? targetCharacteristicR;
  BluetoothCharacteristic? targetCharacteristicW;

  void _blueconnect(name, content) async {       //name의 기기에 블루투스 연결 함수
    Future<bool>? returnValue;
    setState(() {connectLoding = true;});
    await flutterBlue.startScan(timeout: Duration(seconds: 4));  // Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) async {        //주변 기기 스캔할 때마다 코드 실행
      // do something with scan results
      for (ScanResult r in results) {
        if(r.device.name == ''){
          continue;
        }
        print('${r.device.name} found! rssi: ${r.rssi}');
        if(r.device.name == name) {                       //name의 기기가 맞는지 확인
          targetdevice = r.device;
          await targetdevice!
              .connect(autoConnect: false)
              .timeout(Duration(milliseconds: 10000), onTimeout: () {
            //타임아웃 발생
            //returnValue를 false로 설정
            returnValue = Future.value(false);
            debugPrint('timeout failed');

            //연결 상태 disconnected로 변경
            setState(() => deviceState = BluetoothDeviceState.disconnected);
          }).then((data) async {
            if (returnValue == null) {
              //returnValue가 null이면 timeout이 발생한 것이 아니므로 연결 성공
              debugPrint('connection successful');
              returnValue = Future.value(true);
              setState(() {deviceState = BluetoothDeviceState.connected;});
              print("targetdevice = ${targetdevice}");
              await discoverServices(targetdevice);
            }
          });
        }
      }
    });


    Future.delayed(Duration(seconds: 2), () {   //2초 기다린 후 블루투스 scan 끄기

      flutterBlue.stopScan(); // Stop scanning
      subscription.cancel();
      setState(() {connectLoding = false;});
      if(!con()) {             //아직도 연결 안되었다면 연결 실패로 판단
        print("연결실패");
        _connectFailDialog();
      }
    });

  }

  void _connectFailDialog() {      //연결 실패시 뜨는 dialog 창
    showDialog(context: context,  builder: (BuildContext context) {

      Future.delayed(Duration(seconds: 1), () {    //1초 후에 꺼짐
        Navigator.pop(context);
      });
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Text('연결에 실패했습니다'),
      );
    });
  }

  String uuid = "0000ffe0-0000-1000-8000-00805f9b34fb";        //hc-6 블루투스 모듈 기준
  String readUuid = "0000ffe1-0000-1000-8000-00805f9b34fb";
  String writeUuid = "0000ffe2-0000-1000-8000-00805f9b34fb";
  /*값 받는 위치 연결*/
  discoverServices(targetdevicesend) async {
    var services = await targetdevicesend!.discoverServices();

    for (var service in services) {

      if (service.uuid.toString() == uuid) {
        service.characteristics.forEach((characteristic) async {

          if (characteristic.uuid.toString() == readUuid) {
            targetCharacteristicR = characteristic;

            print("All Ready with ${targetdevice!.name}RR");

            await targetCharacteristicR!.setNotifyValue(true);    //read값이 들어올 때마다 앱에 알림
          } else if (characteristic.uuid.toString() == writeUuid) {
            targetCharacteristicW = characteristic;

            print("All Ready with ${targetdevice!.name}WW");
            await targetCharacteristicW!.setNotifyValue(true);

          }
        });
      }
    }
  }

  disconnect() {       //블루투스 연결을 해제하는 함수
    try {
      targetCharacteristicR!.setNotifyValue(false);
      targetdevice!.disconnect();
      setState(() {
        deviceState = BluetoothDeviceState.disconnected;
      });
    } catch (e) {}
  }




  //블루투스 코드


  int tab = 0;     //0 : Home 탭, 1 : doctorinfo 탭, 3 : daily 탭

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            [home.Home(targetCharacteristicR: targetCharacteristicR, targetCharacteristicW: targetCharacteristicW,
              targetdevice: targetdevice, deviceState: deviceState, con: con, disconnect: disconnect,
              connectLoding: connectLoding, blueconnect: _blueconnect, decodeValue: decodeValue,),doctorinfo.DoctorInfo(),daily.Daily()][tab],

            con() ? StreamBuilder<List<int>>(       //어느 탭에 있던지, walkdata가 쌓여 나가며 이는 내장 데이터에 저장됨
                stream: targetCharacteristicR!.value,
                initialData: targetCharacteristicR!.lastValue,
                builder: (c, snapshot) {
                  List<int>? walkData = snapshot.data;

                  walkEncodeData = decodeValue(walkData ?? [0]);
                  if(walkEncodeData != [] && walkEncodeData != null && walkEncodeData!.length == 5) saveData(walkEncodeData);
                  return SizedBox.shrink();
                }
            ) : SizedBox.shrink()],
        ),
        bottomNavigationBar: BottomNavigationBar(
          elevation: 1,
          type: BottomNavigationBarType.fixed,
          backgroundColor: style.commonbackground, //Bar의 배경색
          selectedItemColor: Colors.black, //선택된 아이템의 색상
          unselectedItemColor: Colors.black, //선택 안된 아이템의 색상
          selectedFontSize: 14, //선택된 아이템의 폰트사이즈
          unselectedFontSize: 14, //선택 안된 아이템의 폰트사이즈
          currentIndex: tab, //현재 선택된 Index
          onTap: (int index) { //눌렀을 경우 어떻게 행동할지
            setState(() { //setState()를 추가하여 인덱스를 누를때마다 빌드를 다시함
              tab = index; //index는 처음 아이템 부터 0, 1, 2
            });
          },
          items: [
            BottomNavigationBarItem(
              label: '홈',
              icon: tab == 0 ? Icon(Icons.home) : Icon(Icons.home_outlined),
            ),
            BottomNavigationBarItem(
              label: '의학정보',
              icon: tab == 1 ? Icon(Icons.three_p) : Icon(Icons.three_p_outlined),
            ),
            BottomNavigationBarItem(
              label: '데일리라이프',
              icon: tab == 2 ? Icon(Icons.today) : Icon(Icons.today_outlined),
            ),
          ],
        ),
      ),
    );

    //블루투스 정보 전송 관련 코드

  }
}
