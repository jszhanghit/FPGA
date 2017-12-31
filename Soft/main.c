//+FHDR----------------------------------------------------------------
//           COPRIGHT : 张金帅首次创建
//
//---------------------------------------------------------------------
//
//          PROJECT :main.c 
//          AUTHOR  :JSZHANG
//---------------------------------------------------------------------
//   VERSION   DATA     AUTHOR    DESCRIBE
//      01   20170405  张金帅   为课程设计创建
//---------------------------------------------------------------------
//
//    ABSTRACT  :这是一个初级版本，很多功能不完善，但是操作
//               规范的话，功能是没有问题的，经实物验证
//-FHDR---------------------------------------------------------------
#include "../inc/sopc.h"
#include "unistd.h"
#include "../inc/system.h"
#include "stdio.h"
#include "../inc/alt_irq.h"
#include "../inc/alter_avalon_pio_regs.h"
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
unsigned int control_num,rst_num,flag_c,flag_r=0;//分别存放控制IO，复位IO的数，控制，复位中断标志位
int time=0;
    //显示函数，输入不同的数是将数解码为形影的数码管亮灭
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
  // 改写edge_capture指针以匹配alt_irq_register()函数原型
  void* edge_capture_ptr = (void*) &edge_capture;

  // 使能所有4个按钮中断
  IOWR_ALTERA_AVALON_PIO_IRQ_MASK(BUTTON_PIO_BASE, 0xf);

  // 清边沿捕获寄存器
  IOWR_ALTERA_AVALON_PIO_EDGE_CAP(BUTTON_PIO_BASE, 0x0);



  alt_irq_register(CONTROL,
                   edge_capture_ptr,
                   handle_button_interrupts);

}*/

//控制寄存器中断函数，当满足中断要求时，计入中断函数处理
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
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(CONTROL, 0xfff);//清中断沿
}
int initial_control(void)
{  
    //CONTROL->INTERRUPT_MASK = 0x1ff;
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(CONTROL,0xfff);  //打开中断
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(CONTROL,0xfff);  
    return alt_irq_register(CONTROL_IRQ,NULL,control_isr);       //中断函数映射
}

//下面处理同control的处理

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

//主函数

int main()
{

    
    initial_control();
    initial_rst();//中断初始化
   
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
        IOWR_ALTERA_AVALON_PIO_DATA(HEX0, display(0));//在初试状态，没有选择商品的时候，所有数码管显示都是0
        IOWR_ALTERA_AVALON_PIO_DATA(LED7, 0);
       
        IOWR_ALTERA_AVALON_PIO_DATA(LED0, 0);//灭
        if(kind==0x01||kind==0x02||kind==0x04)//选择商品种类
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
        while(flag_c==0) //选择结束等待其他操作
        {
            usleep(2000);
        }
                   
            while((cancel!=0x01)&&(money<pri)&&(flag_r==0))//投币环节，在投币过程中若出现取消购买，投币足够或售货机复位即结束投币
                                                   //若是张金帅来买，可以不执行投币过程。。。。关键是要机器认得是他啊~.~
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
                        if(money>=pri)//投币充足，LED0置位
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

         can:   if(flag_r==0x01)//结束投币的原因有取消购买，价格足够，复位，先检测是否是复位引起的，若是因复位引起的，跳出循环
                 //这么无情，投的钱呢，竟然给我吃了 
            {
                flag_r=0;
            }

            else
            {
                if(cancel==0x01)//不是因复位引起的，良心商家！！投币后还是可以后悔的，竟然还会找零
                {
                 change_10 = money/10;
                 change_5 = (money-change_10*10)/5;
                 change_1 = money - change_10*10 - change_5*5;
                 IOWR_ALTERA_AVALON_PIO_DATA(HEX2, display(change_10));  
                 IOWR_ALTERA_AVALON_PIO_DATA(HEX1, display(change_5));
                 IOWR_ALTERA_AVALON_PIO_DATA(HEX0, display(change_1));  
                 while(done!=0x01)//等待done信号，若无操作，等待一段时间后跳出循环呢
                 {
                     usleep(10000000);
                     goto start;
                  }
                 }
               else//不是取消购买引起的
              {
                while(sure!=0x01)//等待确认购买
                {
                    if(cancel==0x01)//此时如果还不愿意买的话还可以后悔，就一个字人性化
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
        //这一定是确认购买了，恭喜你！购买成功，等待商品出炉吧
                
                    change=money-pri;
                    change_10 = change/10;
                    change_5 = (change-change_10*10)/5;
                    change_1 = change - change_10*10 - change_5*5;    
                    IOWR_ALTERA_AVALON_PIO_DATA(HEX2, display(change_10));  
                    IOWR_ALTERA_AVALON_PIO_DATA(HEX1, display(change_5));
                    IOWR_ALTERA_AVALON_PIO_DATA(HEX0, display(change_1));   
                           
            /*    while(done!=0x01)//你对我的商品是否满意，请评分。。。
                     //不愿意评分就算了，不等你了，回到空状态
                {
                   IOWR_ALTERA_AVALON_PIO_DATA(LED7, 1); 
                   usleep(10000000);//时间太长可能需要等待太久，可以适当缩短时间
                   break;
                }*/
                   while(done!=0x01)//你对我的商品是否满意，请评分。。。
                     //不愿意评分就算了，不等你了，回到空状态
                {
            

                   IOWR_ALTERA_AVALON_PIO_DATA(LED7, 1);
           if(time==100)
           {
               break;
           }
                   usleep(100000);//时间太长可能需要等待太久，可以适当缩短时间 
           time++;
                }
                
             }
            }

        }
    }
    return 0;
}




