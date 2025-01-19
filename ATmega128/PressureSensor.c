#define F_CPU 16000000L
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>
#include "UART1.h"
#include <math.h>

// PRINTF 출력을 위한 함수
FILE OUTPUT \
= FDEV_SETUP_STREAM(UART1_transmit, NULL, _FDEV_SETUP_WRITE);
FILE INPUT \
= FDEV_SETUP_STREAM(NULL, UART1_receive, _FDEV_SETUP_READ);

	
void ADC_init(void)
{
   ADMUX |= (1 << REFS0); // AVCC를 기준 전압으로 선택
   ADCSRA |= 0x07; // 분주비를 128로 설정
   ADCSRA |= (1 << ADEN); // ADC 활성화
}
void ADC_select_channel(unsigned char channel)
{
   ADMUX = ((ADMUX & 0xE0) | channel); // 채널 선택
   _delay_ms(100); // 여러개 센서의 adc 동시 변환을 위해 딜레이를 줌
   ADCSRA |= (1 << ADSC); // 변환 시작
}
int read_ADC(void)
{
   while(!(ADCSRA & (1 << ADIF))); // 변환 종료 대기
   
   return ADC; // 10비트 값을 반환
}
int zero_data(int a, int b, int c, int d, int e)
{
   return a<15 && b<15 && c<15 && d<10 && e<10 ? 1 : 0;
}

int main(void)
{
   
   int read[5] = {0,0,0,0,0};
   int walking = 0 ; //데이터 전송 횟수
   int max_walk[5] = {0,0,0,0,0}; //최댓값
   int walk_num = 0; //걸은 횟수
   int walk_sum[5] = {0,0,0,0,0}; //걸어서 나온 데이터합

   // PRINTF 출력을 위한 함수
   stdout = &OUTPUT;
   stdin = &INPUT;
   
   UART1_init(); // UART 통신 초기화
   ADC_init(); // AD 변환기 초기화
   
   DDRB = 0xFF;
   
   while(1)
   {
	  for(int i=0; i<=4; i++){
		 ADC_select_channel(i);
		 read[i]=read_ADC();
	  }


      if(walking < 2 && zero_data(read[0],read[1],read[2], read[3], read[4]))
      {
            walking = 0;
            for(int i = 0; i < 5; i++)
               max_walk[i] = 0;
      }

      else if(!zero_data(read[0],read[1],read[2],read[3],read[4]) )
      {
         walking++;
         for(int i = 0 ; i < 5; i++)
         {
            if(read[i] > max_walk[i])
               max_walk[i] = read[i];
         }
      }

      else if(walking >= 2 && zero_data(read[0],read[1],read[2],read[3],read[4]) )
      {
         for(int i = 0 ; i < 5; i++)
            walk_sum[i] += max_walk[i];
         walk_num++;
      
         walking = 0;
         for(int i = 0; i < 5; i++)
               max_walk[i] = 0;
      }
      if(walk_num >= 10)
      {
         const int oneNum = 4; //한 숫자당 4개의 바이트를 할당
         const int countNum = 5; //총 다섯개의 수
         int walk_res[5];
         char send_message[50];
         
         for(int i = 0; i < 5; i++)
            walk_res[i] = walk_sum[i]/walk_num;
      
         printf("%c%c%c%c%c", walk_res[0], walk_res[1], walk_res[2], walk_res[3], walk_res[4]);

         walk_num = 0;
         for(int i = 0; i < 5; i++)
            walk_sum[i] = 0;
      }
      
      _delay_ms(100);
      
   }
   return 0;
}
