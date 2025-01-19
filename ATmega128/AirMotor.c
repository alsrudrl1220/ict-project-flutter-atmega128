#define F_CPU 16000000L
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>
#include "UART1.h"
#include <math.h>
#include <avr/interrupt.h>
volatile char size;
volatile char airmotor_start;
FILE OUTPUT \
= FDEV_SETUP_STREAM(UART1_transmit, NULL, _FDEV_SETUP_WRITE);
FILE INPUT \
= FDEV_SETUP_STREAM(NULL, UART1_receive, _FDEV_SETUP_READ);

ISR(TIMER1_OVF_vect)
{
	scanf("%c", &size);
	PORTB=0x01;
	for(int i=0; i<size-'0'; i++) _delay_ms(1000);	
	PORTB=0x00;

}

int main(void)
{
	DDRB = 0x01; // PB0 핀을 출력으로 설정
	PORTB = 0x00; // 모터는 꺼진 상태에서 시작

	stdout = &OUTPUT;
	stdin = &INPUT;
	
	UART1_init(); // UART 통신 초기화
	TCCR1B |= (1 << CS12);
	TIMSK |= (1 << TOIE1);
	sei(); // 전역적으로 인터럽트 허용
	
	while(1)
	{

	}
	
	return 0;
}
