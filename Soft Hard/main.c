#include "stdio.h"
#include <system.h>
#include "unistd.h"
#include "../inc/sopc.h"
#include "altera_avalon_pio_regs.h"
unsigned int kind,coin,cancel,done,sure;//�ֱ��Ӧsw0-2,sw8-10,sw17,sw15,sw16;
                                               //sw0-2��ѡ����Ʒ���࣬�߼���Ʒ���ȣ�
                                               //sw8-10��Ͷ�����ͣ����Ӳ�����ȣ�
                                               //sw17:ȡ������
                                               //sw 16��ȷ�Ϲ���;
                                               //sw 15��ȷ�������������;
                                               //key0��reset
       
unsigned int money=0,pri=0,change=0;    //����Ͷ��Ǯ��,��Ʒ�۸�����Ĵ���
   
unsigned int pri_ge=0,pri_shi=0;//�۸�ʮλ����λ����Ӧ�����7��6
unsigned int money_ge=0,money_shi=0;//ͶǮ�ĸ�λ��ʮλ����Ӧ�����5��4
unsigned int change_10=0,change_5=0,change_1=0;//����
unsigned int control_num,rst_num,flag_c,flag_r;//�ֱ��ſ���IO����λIO���������ƣ���λ�жϱ�־λ
void control_isr(void* isr_context,unsigned long id)
{
    usleep(20000);
    //IOWR_ALTERA_AVALON_PIO_DATA(HEX5, display(7));
    control_num = IORD_ALTERA_AVALON_PIO_DATA(CONTROL);   
    //IOWR_ALTERA_AVALON_PIO_DATA(HEX2, display(control_num&0x07)); 
 
             kind = control_num & 0x07;
        coin = (control_num>>3) & 0x07;
        cancel = (control_num>>6) & 0x01;
        done = (control_num>>7) & 0x01;
        sure = (control_num>>8) & 0x01;
     
    flag_c=1;
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(CONTROL, 0x1ff);//���ж���
}
int initial_control(void)
{  
    //CONTROL->INTERRUPT_MASK = 0x1ff;
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(CONTROL,0x1ff);  //���ж�
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(CONTROL,0x1ff);  
    return alt_irq_register(CONTROL_IRQ,NULL,control_isr);       //�жϺ���ӳ��
}

int main()
{
    initial_control();
    
    while (1)
    {
        if(flag_c==1)
        {
            HARD->kind_r_s=kind;
            HARD->change_r_s=coin;
            HARD->cancel_r_s=cancel;
            HARD->sure_r_s=sure;
            HARD->done_r_s=done;
            flag_c=0;
        }
    usleep(200000);
            HARD->change_r_s=0x00;;
            HARD->cancel_r_s=0x00;
            HARD->sure_r_s=0x0;
            HARD->done_r_s=0x0;
    }
    return 0;
   
}
