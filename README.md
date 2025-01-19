# 👟 사용자화 걸음 교정 시스템
### 🏆 Awards
2022 ICT 융합 프로젝트 공모전 🏆 **최우수상**    

### ✨ Role
<code>Mobile</code>, <code>Embedded System</code>, <code>Data Analysis</code>     
### ✨ Tech Stack
<code>Flutter</code>, <code>Dart</code>, <code>ATmega128</code>, <code>C</code>, <code>UART</code>    
### ✨ Tools 
<code>Teraterm</code>, <code>AtmelStudio</code>, <code>Excel</code>        


## 📌 족저압 데이터 수집 및 분석
![image](https://github.com/user-attachments/assets/835ed88b-3bf7-428c-9bd2-6d5bd7df555a)

![image](https://github.com/user-attachments/assets/71d5341f-28ec-4083-bf19-8cc3e8aa45f1)

UART 설정과 PRINT 설정을 해줌으로써, teraterm으로 압력센서 다중 동시 변환의 결과를 확인하였다.

### ▪️수집 족저압 데이터 변환 
![image](https://github.com/user-attachments/assets/4074ffe2-886f-4227-bc59-54bfbc4465d8)

### ▪️점수 제도 
: 압력분포 데이터를 바탕으로 사용자의 걸음걸이를 분석하기 위해 도입    
걸음걸이 판단 뿐 아니라 에어펌프모터의 작동시간을 조절하는 척도

![image](https://github.com/user-attachments/assets/e60f5709-cbce-4212-821e-19512ac7493a)
![image](https://github.com/user-attachments/assets/d56966ba-2faf-4638-a136-f413f86d829c)



## 📌 임베디드 SW
### ▪️압력 센서
force의 관계식을 이용해 다섯 개의 압력센서를 동시에 adc 다중 변환을 하여 사용자의 압력 데이터를 얻기 위한 코드이다. 코드1에서는 AD 변환 제어를 위해 ADMUX, ADCSRA, ADC 3개의 레지스터를 사용하였다. ADMUX 레지스터는 기준 전압과 입력 채널 설정, ADCSRA 레지스터는 AD 변환 과정을 제어, ADC 레지스터는 변환된 데이터를 저장하기 위해 사용했다.
 atmega128은 ADC 변환기가 하나이기 때문에, 여러 개의 압력센서의 값을 ADC 동시 다중변환할 수 없다. 따라서 ADMUX 레지스터를 이용해, 변환시킬 아날로그 값의 채널을 선택할 수 있게끔 설정하고, 다중 ADC변환을 수행하되 사용자에게는 동시 ADC 변환이 수행된 것처럼 보이게 하기 위해 충분히 짧은 딜레이를 주었다.

해당 ADC변환을 수행할 채널을 선택하고, 압력센서 출력값의 ADC 변환이 완료되면 변환값을 read라는 변수에 저장한다. 앞서 3.1.3에서 아날로그의 출력 전압값의 범위는 0\~5v이며, atmega의 adc 변환을 한 후의 디지털의 출력 전압값의 범위가 0\~1023이라고 했다. 따라서 Vser=1023Vout/5의 관계식을 구했는데, 여기서 read라는 변수에 저장된 값이 Vser이다.

압력센서로부터 압력 값을 입력받고, 그 값을 블루투스를 통해 핸드폰으로 전송하기 위한 코드이다. 압력센서로부터 값을 입력받을 때, 불규칙적인 시간마다 의도치 않은 쓰레기 값이 들어오는 문제상황이 발생했다. 문제상황에 대한 내용은 고찰에서 자세히 다루었다. 이를 해결하기 위해 zero data함수를 사용하였다.
정상적으로 걸으면 5개의 센서 중 몇 개는 반드시 15 이상의 압력 값을 나타내게 된다. 하지만 만약 1\~5번 센서 전체가 입력된 압력 값이 10 또는 15를 넘기지 않는다면, 걷지 않았음을 나타내므로 0을 반환하여 쓰레기 값과 실제 압력 값을 구별해 주었다. 압력센서로부터 압력 값을 받는 것은 ADC_SELECT_CHANNEL을 통해 1\~5번 압력센서 중 값을 받을 센서를 결정하고 read_ADC()함수를 사용해 read배열에 선택된 센서의 값을 입력한다. 압력 정보를 보내는 과정에서 두 가지 작업을 아트메가 코드에서 진행하였다. 
 첫 번째는 ‘한 걸음 마다 압력의 최댓값 추출’이다. 압력의 최댓값을 측정하는 이유는 사람이 걸을 때 뒷꿈치에서 앞꿈치 순서로 걷게 되는데, 만약에 이 값들을 모두 전송하게 된다면 뒷꿈치 혹은 앞꿈치가 값이 없는 데이터가 전달될 것이다. 하지만 한 걸음마다 추출해서 휴대폰으로 정보를 보내기 위해선 ‘한 걸음’을 구분 지을 필요가 있다. 
 그래서 두 번째 작업은 걸음 마디를 구분 짓는 작업이다. 다음과 같이 구분을 지었는데, (1. 발을 딛기 전 공중에 뜬 상태 2. 발을 딛은 상태 3. 발을 딛고 난 후 다시 땅에서 뗀 상태) 데이터가 전송된 횟수(변수 walking)가 2 미만이고 현재 zero data함수가 0을 반환할 때(압력센서에 어떠한 압력도 가해지지 않았을 때) 발을 딛기 전 공중에 떠있는 상태임을 확인할 수 있다.


### ▪️에어펌프 모터
PORTB가 0x01값을 가질 때 에어모터에 출력이 가해지고, 0x00일 때 동작이 정지된다. main문에서 인터럽트를 일정시간 동안 계속 반복적으로 발생시켜 ISR함수 내에 있는 코드가 지속적으로 작동하도록 만들었다. 변수 size는 에어모터가 작동할 시간 값으로 블루투스로 연결된 휴대폰으로부터 전송 받는다. 휴대폰에서 char형으로 숫자를 전송하면 전송된 char형 숫자에서 char형 “0”을 차감해줘 인위적으로 int형으로 형 변환이 가능하다. 에어모터가 켜지고 제공된 시간만큼 계속 작동하다가 for문이 끝나면 0x00으로 PORTB값을 바꿔 멈추도록 한다. 




## 📌 모바일 앱
### ▪️발의 실시간 압력분포
![image](https://github.com/user-attachments/assets/3ff64d58-dd91-4765-8922-653272bce091)

데이터를 반복적으로 수집해서 내장 데이터에 평균의 형태로 저장하는 코드이다. decodeValue 함수로 수집된 압력을 비율로 전환한 후, saveData 함수로 내장 데이터에 저장한다.

![image](https://github.com/user-attachments/assets/72225c53-7196-4f7c-89c6-457196c17f99)

발자국 그림으로 표현할 때, 압력의 정도에 따른 색 판별을 다루는 함수인 colorIncode 의 내용이다. 평발의 여부에 따라 구분하여 List 변수에 들어있는 기준대로 크기를 비교하여 1 부터 5까지의 값을 반환한다. 1이 강한 압력이 가해진 경우이고, 3이 정상, 5가 약한 압력이 가해진 경우이다.

### ▪️걸음걸이 분석
![image](https://github.com/user-attachments/assets/15a36f9b-840d-4974-945a-c6b1874fc3b0)

입력받은 데이터를 기준에 맞게 판단하여 데이터의 걸음 유형을 반환하는 함수인 walkCategory의 내용이다. value 리스트의 3,4번째 값을 기준으로 평발을 판단한 후, 각각의 기준에 맞게 걸음의 유형을 판단한다. 1,2번째 데이터의 기울기와 4,5번째 데이터의 기울기에 대해 각각의 단계를 계산한 수 더한 값을 반환한다. 이 때, 입력값이 평발이라고 판단될 경우 계산된 단계에 15를 더해 반환한다. 

### ▪️깔창 조절
![image](https://github.com/user-attachments/assets/72879955-59e1-4de4-84b9-a5ae1d78dba2)

걸음걸이의 유형에 맞게, 모터를 작동시킬 버튼을 생성시키는 코드이다. 모터를 작동시킬 필요가 없는 부분의 버튼은 나타나지 않으며 버튼이 하나도 없는 경우에는 저장된 데이터의 유무에 따라 텍스트를 출력한다.



## 📌 걸음걸이 교정
![image](https://github.com/user-attachments/assets/dc462832-52a0-4b77-8c7a-34d479273b89)



## 📌 2022 ICT 융합 프로젝트 공모전 수상작 모음집
▶️ https://www.devicemart.co.kr/goods/view?no=15007233&srsltid=AfmBOoqFx7Vri9bEnaQY6kE42DZDazT25CEFZGu0AK2IpZrH4Ky2aJTv

<!-- ![image](https://github.com/user-attachments/assets/874efbf1-3b23-48d3-be11-4306770098d2) -->
