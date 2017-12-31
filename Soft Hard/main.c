#include "stdio.h"
#include <system.h>
#include "unistd.h"
#include "../inc/sopc.h"
#include "altera_avalon_pio_regs.h"
unsigned int kind,coin,cancel,done,sure;//分别对应sw0-2,sw8-10,sw17,sw15,sw16;
                                               //sw0-2：选择商品种类，高价商品优先；
                                               //sw8-10：投币类型，大额硬币优先；
                                               //sw17:取消购买；
                                               //sw 16：确认购买;
                                               //sw 15：确认整个交易完成;
                                               //key0：reset
       
unsigned int money=0,pri=0,change=0;    //计算投入钱数,商品价格，找零寄存器
   
unsigned int pri_ge=0,pri_shi=0;//价格十位，各位，对应数码管7与6
unsigned int money_ge=0,money_shi=0;//投钱的个位与十位，对应数码管5与4
unsigned int change_10=0,change_5=0,change_1=0;//找零
unsigned int control_num,rst_num,flag_c,flag_r;//分别存放控制IO，复位IO的数，控制，复位中断标志位
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
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(CONTROL, 0x1ff);//清中断沿
}
int initial_control(void)
{  
    //CONTROL->INTERRUPT_MASK = 0x1ff;
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(CONTROL,0x1ff);  //打开中断
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(CONTROL,0x1ff);  
    return alt_irq_register(CONTROL_IRQ,NULL,control_isr);       //中断函数映射
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
