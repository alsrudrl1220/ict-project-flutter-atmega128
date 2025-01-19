import 'package:flutter/material.dart';

var commonbackground = Color.fromRGBO(240, 240, 240, 1);  //기본 배경 색
var uncommonbackground = Color.fromRGBO(230, 230, 230, 1); //연결이 해제되었을 때의 배경 색

commonbackground_con(con)  //연결 여부에 따라 배경 색 바꿈
{
  return con ? commonbackground
      : uncommonbackground;
}

var commontext = TextStyle(   //기본 글자 스타일(버튼 글자)
  letterSpacing: 2.0,
  fontWeight: FontWeight.w600,
  fontSize: 15,
  color: Colors.black,
);

var infotext = TextStyle( //기본 글자 스타일(설명 글자)
    letterSpacing: 2.0,
    fontWeight: FontWeight.w400,
    fontSize: 15
);

var theme = ThemeData(  //appbar의 테마 설정
    appBarTheme: AppBarTheme(
        color: commonbackground,
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 25),
        actionsIconTheme: IconThemeData(color: Colors.black)
    ),
    iconTheme: IconThemeData(
      color: Colors.black,
    )
);



shoes(t, height, width) {       //발 그림 표현 나타내는 함수 (데이터(5개의 double 값 가진 리스트), 화면 높이, 화면 너비)
  bool flat = ((t[2] >= 16.5) && (t[3] >= 13)); //평발 판단
  return Stack(
    children: [
      Image.asset('assets/shoes.png',height: height * 0.3, width: double.infinity,),
      shoesDot(t[0], height, width, 0, flat),  //프로토타입 -> 오른발 데이터만 확인하여 왼발은 대칭으로 표현
      shoesDot(t[0], height, width, 1, flat),
      shoesDot(t[1], height, width, 2, flat),
      shoesDot(t[1], height, width, 3, flat),
      shoesDot(t[2], height, width, 4, flat),
      shoesDot(t[2], height, width, 5, flat),
      shoesDot(t[3], height, width, 6, flat),
      shoesDot(t[3], height, width, 7, flat),
      shoesDot(t[4], height, width, 8, flat),
      shoesDot(t[4], height, width, 9, flat),
    ],
  );
}


shoesDot(color, height, width, sNum, flat){  //발 사진 위에서 점으로 눌려진 압력 표현 (데이터(double), 화면 높이 화면 너비, 점의 번째 수, 평발 여부)
  List<double> posHeight = [0.1, 0.1, 0.112, 0.112, 0.15, 0.15, 0.15, 0.15, 0.23, 0.23, 0.23, 0.23];
  List<double> posWidth = [0.32, 0.61, 0.25, 0.69, 0.29, 0.64, 0.24, 0.69, 0.31, 0.60, 0.26, 0.65];

  return Positioned(
    top: height * posHeight[sNum],
    left: width * posWidth[sNum],
    child: Container(
      height: height * 0.02,
      width: height* 0.02,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular((30))),
        color: colorRep(colorIncode(color, sNum, flat)),
      ),
    ),
  );
}

colorRep(colorNum) {
  switch (colorNum) {
    case 0:
      return Color.fromRGBO(255, 255, 255, 0);
    case 1:
      return Color.fromRGBO(229, 44, 47, 1.0);
    case 2:
      return Color.fromRGBO(243, 66, 161, 0.611764705882353);
    case 3:
      return Color.fromRGBO(70, 70, 255, 0.611764705882353);
    case 4:
      return Color.fromRGBO(255, 238, 135, 0.6901960784313725);
    case 5:
      return Color.fromRGBO(255, 201, 0, 0.6705882352941176);
    default:
      return Color.fromRGBO(0, 0, 0, 1);
  }
}


int colorIncode(color, sNum, flat) { //데이터를 바탕으로 압력이 많이 눌렸는지 판단 -> 5개의 값으로 나눔, 예외 사항일 경우 6 반환

  List<List<double>> line = [[34.3,34.3, 57.6,57.6, 5.5,5.5, 6.1,6.1, 33.6,33.6],   //정상 발일 때 압력 판단하는 기준 데이터
    [32.5,32.5, 48.5,48.5, 3.75,3.75, 4.55,4.55, 29.4,29.4],
    [28.6,28.6, 32.15,32.15, 0,0, 0,0, 17.05,17.05],
    [26.5,26.5, 24.9,24.9, 0,0, 0,0, 8.9,8.9]];
  List<List<double>> line2 = [[37.3,37.3, 33.3,33.3, 33.8,33.8, 24.5,24.5, 12.1,12.1],  //평발일 때 압력 판단하는 기준 데이터
    [32.9,32.9, 26,26, 16.5,16.5, 12.9,12.9, 8.8,8.8],
    [19.8,19.8, 11.2,11.2, 0.8,0.8, 1.7,1.7, 3.2,3.2],
    [18.3,18.3, 7.8,7.8, 0,0, 0,0, 0,0]];

  if(flat) {
    if (line[0][sNum] <= color * 100) {
      return 1;
    }
    else if (line[1][sNum] <= color * 100 && color * 100 < line[0][sNum]) {
      return 2;
    }
    else if (line[2][sNum] <= color * 100 && color * 100 < line[1][sNum]) {
      return 3;
    }
    else if (line[3][sNum] <= color * 100 && color * 100 < line[2][sNum]) {
      return 4;
    }
    else if (color * 100 < line[3][sNum]) {
      return 5;
    }
    else {
      return 6;
    }
  } else {
    if (line[0][sNum] <= color * 100) {
      return 1;
    }
    else if (line[1][sNum] <= color * 100 && color * 100 < line[0][sNum]) {
      return 2;
    }
    else if (line[2][sNum] <= color * 100 && color * 100 < line[1][sNum]) {
      return 3;
    }
    else if (line[3][sNum] <= color * 100 && color * 100 < line[2][sNum]) {
      return 4;
    }
    else if (color * 100 < line[3][sNum]) {
      return 5;
    }
    else {
      return 6;
    }
  }
}

// 발의 유형에 맞는 문구 출력. 정상 대신 "올바른 걸음이에요" 같은 문구로 대체 가능
List<String> categoryInfo = ['안짱7','안짱6','안짱5','안짱4','안짱3','안짱2','안짱1','정상','팔자1','팔자2','팔자3','팔자4','팔자5','팔자6','팔자7',
  '평발안짱7','평발안짱6','평발안짱5','평발안짱4','평발안짱3','평발안짱2','평발안짱1','평발정상','평발팔자1','평발팔자2','평발팔자3','평발팔자4','평발팔자5','평발팔자6','평발팔자7'];
