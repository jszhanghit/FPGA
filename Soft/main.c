//+FHDR----------------------------------------------------------------
//           COPRIGHT : �Ž�˧�״δ���
//
//---------------------------------------------------------------------
//
//          PROJECT :main.c 
//          AUTHOR  :JSZHANG
//---------------------------------------------------------------------
//   VERSION   DATA     AUTHOR    DESCRIBE
//      01   20170405  �Ž�˧   Ϊ�γ���ƴ���
//---------------------------------------------------------------------
//
//    ABSTRACT  :����һ�������汾���ܶ๦�ܲ����ƣ����ǲ���
//               �淶�Ļ���������û������ģ���ʵ����֤
//-FHDR---------------------------------------------------------------
#include "../inc/sopc.h"
#include "unistd.h"
#include "../inc/system.h"
#include "stdio.h"
#include "../inc/alt_irq.h"
#include "../inc/alter_avalon_pio_regs.h"
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
unsigned int control_num,rst_num,flag_c,flag_r=0;//�ֱ��ſ���IO����λIO���������ƣ���λ�жϱ�־λ
int time=0;
    //��ʾ���������벻ͬ�����ǽ�������Ϊ��Ӱ�����������
int display(int num)
{
    int out_o;
    switch(num)
    {
        case 9: out_o = 0x18; break;
        case 8: out_o = 0x00; break;
        case 7: out_o = 0x78;break;
        case 6: out_o = 0x03;break;
        case 5: out_o = 0x12;break;
        case 4: out_o = 0x19;break;
        case 3 : out_o = 0x30;break;
        case 2 : out_o = 0x24;break;
        case 1 : out_o = 0x79;break;
        case 0 : out_o = 0x40;break;
        default:out_o =0x40;break;
    }
        return out_o;
}


/*static void initial_control()
{
  // ��дedge_captureָ����ƥ��alt_irq_register()����ԭ��
  void* edge_capture_ptr = (void*) &edge_capture;

  // ʹ������4����ť�ж�
  IOWR_ALTERA_AVALON_PIO_IRQ_MASK(BUTTON_PIO_BASE, 0xf);

  // ����ز���Ĵ���
  IOWR_ALTERA_AVALON_PIO_EDGE_CAP(BUTTON_PIO_BASE, 0x0);



  alt_irq_register(CONTROL,
                   edge_capture_ptr,
                   handle_button_interrupts);

}*/

//���ƼĴ����жϺ������������ж�Ҫ��ʱ�������жϺ�������
void control_isr(void* isr_context,unsigned long id)
{
    usleep(20000);
    //IOWR_ALTERA_AVALON_PIO_DATA(HEX5, display(7));
    control_num = IORD_ALTERA_AVALON_PIO_DATA(CONTROL);   
    //IOWR_ALTERA_AVALON_PIO_DATA(HEX2, display(control_num&0x07)); 
 
             kind = control_num & 0x07;
        coin = (control_num>>3) & 0x07;
        cancel = (control_num>> 6) & 0x01;
        done = (control_num>>7) & 0x01;
        sure = (control_num>>8) & 0x01;
     
    flag_c=1;
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(CONTROL, 0xfff);//���ж���
}
int initial_control(void)
{  
    //CONTROL->INTERRUPT_MASK = 0x1ff;
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(CONTROL,0xfff);  //���ж�
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(CONTROL,0xfff);  
    return alt_irq_register(CONTROL_IRQ,NULL,control_isr);       //�жϺ���ӳ��
}

//���洦��ͬcontrol�Ĵ���

void rst_isr(void* isr_context,unsigned long id)
{
    usleep(20000);
    rst_num = IORD_ALTERA_AVALON_PIO_DATA(RST); 
    flag_r=1;
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(RST, 0x01);
}
int initial_rst(void)
{  
    RST->INTERRUPT_MASK = 0x01;
        IOWR_ALTERA_AVALON_PIO_EDGE_CAP(RST,0x01);
    return alt_irq_register(RST_IRQ,NULL,rst_isr);       
}

//������

int main()
{

    
    initial_control();
    initial_rst();//�жϳ�ʼ��
   
    while(1)
    {

        start:pri = 0;
        time=0;
        IOWR_ALTERA_AVALON_PIO_DATA(HEX7, display(0));
        IOWR_ALTERA_AVALON_PIO_DATA(HEX6, display(0));
        IOWR_ALTERA_AVALON_PIO_DATA(HEX5, display(0));  
        IOWR_ALTERA_AVALON_PIO_DATA(HEX4, display(0)); 
        IOWR_ALTERA_AVALON_PIO_DATA(HEX2, display(0));  
        IOWR_ALTERA_AVALON_PIO_DATA(HEX1, display(0));
        IOWR_ALTERA_AVALON_PIO_DATA(HEX0, display(0));//�ڳ���״̬��û��ѡ����Ʒ��ʱ�������������ʾ����0
        IOWR_ALTERA_AVALON_PIO_DATA(LED7, 0);
       
        IOWR_ALTERA_AVALON_PIO_DATA(LED0, 0);//��
        if(kind==0x01||kind==0x02||kind==0x04)//ѡ����Ʒ����
        {
            money=0;
            if(kind==0x01)
            {
                pri=10;
            }
            else if(kind==0x02)
            {
                pri=14;
            }
            else if(kind==0x04)
            {
                pri=20;
            }
            else
            {
                pri=0;
            }
            pri_ge = pri %10;
            pri_shi = (pri-pri_ge)/10;
            IOWR_ALTERA_AVALON_PIO_DATA(HEX6, display(pri_ge));
            IOWR_ALTERA_AVALON_PIO_DATA(HEX7, display(pri_shi));
        while(flag_c==0) //ѡ������ȴ���������
        {
            usleep(2000);
        }
                   
            while((cancel!=0x01)&&(money<pri)&&(flag_r==0))//Ͷ�һ��ڣ���Ͷ�ҹ�����������ȡ������Ͷ���㹻���ۻ�����λ������Ͷ��
                                                   //�����Ž�˧���򣬿��Բ�ִ��Ͷ�ҹ��̡��������ؼ���Ҫ�����ϵ�������~.~
            {
                if(flag_c==1)
                {
                         if(coin==0x01)
                        {
                            money=money+1;
                        }
                        else if(coin==0x2)
                        {
                            money=money+5;                 
                        }
                        else if(coin==0x4)
                        {
                            money=money+10;
                        }
                        else
                        {
                            money=money;
                        }
                        flag_c = 0;
                        money_ge = money %10;
                        money_shi = (money-money_ge)/10;
                        IOWR_ALTERA_AVALON_PIO_DATA(HEX5, display(money_shi));  
                        IOWR_ALTERA_AVALON_PIO_DATA(HEX4,display( money_ge));
                        if(money>=pri)//Ͷ�ҳ��㣬LED0��λ
                        {
                            IOWR_ALTERA_AVALON_PIO_DATA(LED0, 1);
                        }
                        if(cancel==0x01)
                        {
                            goto can;                            
                        }
                }
                usleep(10000);
            }

         can:   if(flag_r==0x01)//����Ͷ�ҵ�ԭ����ȡ�����򣬼۸��㹻����λ���ȼ���Ƿ��Ǹ�λ����ģ�������λ����ģ�����ѭ��
                 //��ô���飬Ͷ��Ǯ�أ���Ȼ���ҳ��� 
            {
                flag_r=0;
            }

            else
            {
                if(cancel==0x01)//������λ����ģ������̼ң���Ͷ�Һ��ǿ��Ժ�ڵģ���Ȼ��������
                {
                 change_10 = money/10;
                 change_5 = (money-change_10*10)/5;
                 change_1 = money - change_10*10 - change_5*5;
                 IOWR_ALTERA_AVALON_PIO_DATA(HEX2, display(change_10));  
                 IOWR_ALTERA_AVALON_PIO_DATA(HEX1, display(change_5));
                 IOWR_ALTERA_AVALON_PIO_DATA(HEX0, display(change_1));  
                 while(done!=0x01)//�ȴ�done�źţ����޲������ȴ�һ��ʱ�������ѭ����
                 {
                     usleep(10000000);
                     goto start;
                  }
                 }
               else//����ȡ�����������
              {
                while(sure!=0x01)//�ȴ�ȷ�Ϲ���
                {
                    if(cancel==0x01)//��ʱ�������Ը����Ļ������Ժ�ڣ���һ�������Ի�
                    {
                          change_10 = money/10;
                          change_5 = (money-change_10*10)/5;
                          change_1 = money - change_10*10 - change_5*5;     
                          IOWR_ALTERA_AVALON_PIO_DATA(HEX2, display(change_10));  
                          IOWR_ALTERA_AVALON_PIO_DATA(HEX1, display(change_5));
                          IOWR_ALTERA_AVALON_PIO_DATA(HEX0, display(change_1));      
                          usleep(1000000);                                       
                          goto start;
                    }
                }   
        //��һ����ȷ�Ϲ����ˣ���ϲ�㣡����ɹ����ȴ���Ʒ��¯��
                
                    change=money-pri;
                    change_10 = change/10;
                    change_5 = (change-change_10*10)/5;
                    change_1 = change - change_10*10 - change_5*5;    
                    IOWR_ALTERA_AVALON_PIO_DATA(HEX2, display(change_10));  
                    IOWR_ALTERA_AVALON_PIO_DATA(HEX1, display(change_5));
                    IOWR_ALTERA_AVALON_PIO_DATA(HEX0, display(change_1));   
                           
            /*    while(done!=0x01)//����ҵ���Ʒ�Ƿ����⣬�����֡�����
                     //��Ը�����־����ˣ��������ˣ��ص���״̬
                {
                   IOWR_ALTERA_AVALON_PIO_DATA(LED7, 1); 
                   usleep(10000000);//ʱ��̫��������Ҫ�ȴ�̫�ã������ʵ�����ʱ��
                   break;
                }*/
                   while(done!=0x01)//����ҵ���Ʒ�Ƿ����⣬�����֡�����
                     //��Ը�����־����ˣ��������ˣ��ص���״̬
                {
            

                   IOWR_ALTERA_AVALON_PIO_DATA(LED7, 1);
           if(time==100)
           {
               break;
           }
                   usleep(100000);//ʱ��̫��������Ҫ�ȴ�̫�ã������ʵ�����ʱ�� 
           time++;
                }
                
             }
            }

        }
    }
    return 0;
}




