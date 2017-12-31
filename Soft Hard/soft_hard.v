// +FHDR-----------------------------------------------------------------------
//                             张金帅创建
// ----------------------------------------------------------------------------
// PROJECT        : 课程设计，自动售货机，用于生成硬件IP
// AUTHOR         : jszhang
// ----------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE     AUTHOR    DESCRIPTION
// 0.1   20170411   jszhang    首次创建
// ----------------------------------------------------------------------------
// ABSTRACT    :        自动售货机软硬结合硬件部分
// -FHDR-----------------------------------------------------------------------
module soft_hard(
//系统接口
//--------------
clk,
reset_n,
chipselect,
address,
write,
writedata,
read,
//byteenable,
readdata,
//--------------
HEX7_o,
HEX6_o,
HEX5_o,
HEX4_o,
HEX2_o,
HEX1_o,
HEX0_o,
LED7_o,
LED0_o
);

parameter IDLE=4'd0,//空闲状态
	  coin_in=4'd1,//投币状态
	  return_ver=4'd2,//找零状态
	  cancel=4'd3,
	  success=4'd4;//交易结束
  
input clk; //时钟信号
input reset_n; //复位信号
input chipselect; //片选信号
input [3:0]address; //2位地址信号，译码后确定寄存器offset，确定往哪个寄存器写
input write; //写使能信号
input [7:0] writedata; //写数值信号
input read; //读使能信号
//input [3:0] byteenable; //字节使能信号
output [7:0] readdata; //8位读数据值

output [6:0] HEX7_o,HEX6_o,HEX5_o,HEX4_o,HEX2_o,HEX1_o,HEX0_o;
output LED7_o,LED0_o;
reg [6:0]HEX7_o,HEX6_o,HEX5_o,HEX4_o,HEX2_o,HEX1_o,HEX0_o;

reg [6:0]HEX7_r,HEX6_r,HEX5_r,HEX4_r,HEX2_r,HEX1_r,HEX0_r;

//kind_r：商品种类3'b001商品1,3'b010商品2,3'b100商品3
//change_i:投币类型，3'b001一角,3'b010五角,3'b100一元
reg [2:0] kind_r,change_r;
//--------------------------------------------------
reg LED0,LED7;
reg  LED7_o;
wire LED0_o;
//cancel_r:取消购买
//sure_i:确认购买
//n_teset_i:复位
//done_r:确认完成整个交易完成
reg cancel_r,sure_r,done_r;
//--------------------------------------------------
reg kind_r_s,change_r_s,cancel_r_s,sure_r_s,done_r_s;

reg [1:0] change_in1,change_in2,change_in0;
reg [1:0] cancel_in,sure_in,done_in;
wire change_ok0,change_ok1,changeok_2;
wire cancel_ok,done_ok;

//检测是否来到上升沿
always@(posedge clk) begin
  if(!reset_n) begin
    change_in0<=0;
    change_in1<=0;
    change_in2<=0;
    cancel_in<=0;
    done_in<=0;
  end
else begin
	change_in0<={change_in0[0],change_r[0]};
	change_in1<={change_in1[0],change_r[1]};
	change_in2<={change_in2[0],change_r[2]};
	cancel_in<={cancel_in[0],cancel_r};
	done_in<={done_in[0],done_r};
end
end
//上升沿检测
assign change_ok0=change_in0[0]&(!change_in0[1]);
assign change_ok1=change_in1[0]&(!change_in1[1]);
assign change_ok2=change_in2[0]&(!change_in2[1]);
assign cancel_ok=cancel_in[0]&(!cancel_in[1]);
assign done_ok=done_in[0]&(!done_in[1]);
//------------------------------------------------

//地址译码
always @ (address) begin
case(address)
	4'b0000:begin
		kind_r_s = 1'b1;
		change_r_s = 1'b0;
		cancel_r_s = 1'b0;
		sure_r_s = 1'b0;
		done_r_s = 1'b0;
	end
	4'b0001:begin
		kind_r_s = 1'b0;
		change_r_s = 1'b1;
		cancel_r_s = 1'b0;
		sure_r_s = 1'b0;
		done_r_s = 1'b0;
	end
	4'b0010:begin
		kind_r_s = 1'b0;
		change_r_s = 1'b0;
		cancel_r_s = 1'b1;
		sure_r_s = 1'b0;
		done_r_s = 1'b0;
	end
	4'b0011:begin
		kind_r_s = 1'b0;
		change_r_s = 1'b0;
		cancel_r_s = 1'b0;
		sure_r_s = 1'b1;
		done_r_s = 1'b0;		
	end
	4'b0100:begin
		kind_r_s = 1'b0;
		change_r_s = 1'b0;
		cancel_r_s = 1'b0;
		sure_r_s = 1'b0;
		done_r_s = 1'b1;		
	end
	default:begin
		kind_r_s = 1'b0;
		change_r_s = 1'b0;
		cancel_r_s = 1'b0;
		sure_r_s = 1'b0;
		done_r_s = 1'b0;		
	end
endcase
end

//写种类寄存器 kind_r_s
always@(posedge clk or negedge reset_n)begin
	if(!reset_n)begin
		kind_r <= 3'd0;
	end
	else begin
		if(write & chipselect & kind_r_s) 
			kind_r <= writedata[2:0];
		else 
			kind_r <= kind_r;
	end
end

//写投币寄存器 change_r
always@(posedge clk or negedge reset_n)begin
	if(!reset_n)begin
		change_r <= 3'd0;
	end
	else begin
		if(write & chipselect & change_r_s) 
			change_r <= writedata[2:0];
		else 
			change_r <= change_r;
	end
end

//写寄存器 cancel_r
always@(posedge clk or negedge reset_n)begin
	if(!reset_n)begin
		cancel_r <= 1'd0;
	end
	else begin
		if(write & chipselect & cancel_r_s) 
			cancel_r <= writedata[0];
		else 
			change_r <= change_r;
	end
end

//写寄存器 sure_r
always@(posedge clk or negedge reset_n)begin
	if(!reset_n)begin
		sure_r <= 1'd0;
	end
	else begin
		if(write & chipselect & sure_r_s) 
			sure_r <= writedata[0];
		else 
			sure_r <= sure_r;
	end
end
//写投币寄存器 done_r
always@(posedge clk or negedge reset_n)begin
	if(!reset_n)begin
		done_r <= 1'd0;
	end
	else begin
		if(write & chipselect & done_r_s) 
			done_r <= writedata[0];
		else 
			done_r <= done_r;
	end
end





//--------------------------------------------------
//
//                       状态转换
//                      三段状态机
//
//--------------------------------------------------
reg [3:0] state,next_state;

//**************************************************
//                     现态逻辑
//
//*************************************************
always@(posedge clk or negedge reset_n) begin
	if(!reset_n)begin
		state<=IDLE;
	end
	else begin
		state<=next_state;
	end
end
//**************************************************
//               状态转移，产生下一状态
//
//**************************************************
always@(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		next_state<=IDLE;
	end
	else begin
		case(state)
			IDLE: begin
				if(|kind_r) begin
					next_state<=coin_in;
				end
				else
					next_state<=IDLE;	
			end
			coin_in: begin
				if(cancel_r==1)begin
					next_state=cancel;
				end
				else if((LED0==1)&&(sure_r==1)) begin
					next_state<=return_ver;
					end
				else begin
					next_state<=coin_in;
					end
			end
			return_ver:begin
				if(done_r==1)
					next_state<=success;
				else
					next_state<=return_ver;
			end
			cancel:begin
				if(done_r==1)
					next_state<=success;
				else
					next_state<=cancel;
			end
			success:begin
				if(done_r==1)
				next_state<=success;
				else
				  next_state<=IDLE;
			end
			default:begin
				next_state<=IDLE;
			end
		endcase			
	end
end

//**************************************************
//               产生输出
//
//**************************************************

//--------------------------------------------------
//                 价格显示
//
//--------------------------------------------------

reg [7:0] money;
reg [7:0] rechange;
reg[2:0] kind_r_q;
always@(posedge clk or negedge reset_n)begin
	if(!reset_n) begin
		HEX7_r<=4'd0;
		HEX6_r<=4'd0;
	end
	else begin
            if(state==IDLE)    begin
                    kind_r_q<=kind_r;
		case(kind_r)
			3'b001:begin
				HEX7_r<=4'd1;
				HEX6_r<=4'd0;
        end
			3'b010:begin
				HEX7_r<=4'd1;
				HEX6_r<=4'd4;
			end
			3'b100:begin
				HEX7_r<=4'd2;
				HEX6_r<=4'd0;
			end
			default:begin
			  HEX7_r<=4'd0;
			  HEX6_r<=4'd0;
			  end
			  endcase
      end
              else begin
              HEX7_r<=HEX7_r;
			  HEX6_r<=HEX6_r;
      end
    end

end
assign LED0_o=LED0;

always@(posedge clk or 	negedge reset_n)begin
        if(!reset_n)begin
                LED0<=0;
        end
        else begin
      		case(kind_r_q)
			3'b001:begin
				if(money>=8'd10)
					LED0<=1;
				else
					LED0<=0;
			end
			3'b010:begin
				if(money>=8'd14)
					LED0<=1;
				else
					LED0<=0;
			end
			3'b100:begin
				if(money>=8'd20)
					LED0<=1;
				else
					LED0<=0;
			end
			  LED0<=0;
			  end
			  endcase
	end

end
//-----------------------------------------------
//              LED7_o输出产生逻辑
//
//-----------------------------------------------
always@(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		LED7<=1'b0;
	end
	else begin
		case(state)
			IDLE: begin
				LED7<=1'b0;
			end
			coin_in: begin
				LED7<=1'b0;
			end
			return_ver: begin
				if(done_r==1)
					LED7<=1'b1;
				else
					LED7<=1'b0;
			end
			cancel: begin
				LED7<=0;
			end
			success: begin
				LED7<=1'b1;
			end
			default: begin
				LED7<=1'b0;
			end
		endcase
	end
end
always@(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		LED7_o<=1'b0;
	end
	else 
		LED7_o<=LED7;
end

//-------------------------------------------------
//          金额计数，每次金额变化则进
//              行相应的金额计数  
//
//-------------------------------------------------
always@(posedge clk or negedge reset_n) begin
	if(!reset_n) 
		money<=8'd0;
	else begin
	       case(state)
		       IDLE: money<=0;
		       coin_in:begin
			       if(change_ok0==1'b1)
				       money<=money+8'd1;
			       else if(change_ok1==1'b1)
				       money<=money+8'd5;
			       else if(change_ok2==1'b1)
				       money<=money+8'd10;
			       else
				       money<=money;
		       end
		       return_ver: begin
			       money<=money;
		       end
		       cancel:begin
			       money<=money;
		       end
		       success: begin
			       money<=money;
		       end
		       default: begin
			       money<=0;
		       end
	       endcase
	end
end
//--------------------------------------------------
//                   找零
//
//--------------------------------------------------
always@(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		rechange<=8'd0;
	end
	else begin
		case(state)
			IDLE:begin
				rechange<=8'd0;
			end
			coin_in:begin
				if(cancel_r==1'b1)begin
					rechange<=money;
				end
				else
					rechange<=0;
			end
			return_ver:begin
				if(cancel_r==1)
					rechange<=money;
				else begin
				case(kind_r_q)
					3'b001:begin
						rechange<=money-8'd10;
					end
					3'b010:begin
						rechange<=money-8'd14;
					end
					3'b100: begin
						rechange<=money-8'd20;
					end
					default:begin
						rechange<=8'd0;
					end
				endcase
			end
			end
			cancel: begin
				rechange<=money;
			end
			success: begin
				rechange<=rechange;
			end
			default:begin
				rechange<=8'd0;
			end
		endcase
	end
end

//--------------------------------------------------
//              根据投币数目显示已投金额
//
//             这里限制只能投少于5元的金额
//--------------------------------------------------
always@(posedge clk) begin
	if(!reset_n) begin
		HEX5_r<=4'd0;
		HEX4_r<=4'd0;
	end
	else begin
		if(money<10)begin			
			HEX5_r<=0;
			HEX4_r<=money;
		end 
		else if((10<=money)&&(money<20)) begin
			HEX5_r<=1;
			HEX4_r<=(money-10);
		end 
		else if((money>=20)&&(money<30)) begin
			HEX5_r<=2;
			HEX4_r<=(money-20);
		end 
		else if((money>=30)&&(money<40))begin
			HEX5_r<=3;
			HEX4_r<=(money-30);
		end
		else begin
			HEX5_r<=HEX5_o;
			HEX4_r<=HEX4_o;
		end
	end
end
always@(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		HEX2_r<=0;
		HEX1_r<=0;
		HEX0_r<=0;
	end
	else begin
		if(rechange<5) begin
			HEX0_r<=rechange;
			HEX1_r<=0;
			HEX2_r<=0;
		end
		else if((rechange>=5)&&(rechange<10)) begin
			HEX0_r<=rechange-5;
			HEX1_r<=1;
			HEX2_r<=0;
		end
		else if((rechange>=10)&&(rechange<15)) begin
			HEX2_r<=1;
			HEX1_r<=0;
			HEX0_r<=rechange-10;
		end
		else if((rechange>=15)&&(rechange<20)) begin
			HEX2_r<=1;
	 		HEX1_r<=1;
		 	HEX0_r<=rechange-15;
		end
		else if((rechange>=20)&&(rechange<25)) begin
			HEX2_r<=2;
			HEX1_r<=0;
			HEX0_r<=rechange-20;
		end
		else if((rechange>=25)&&(rechange<30)) begin
			HEX2_r<=2;
			HEX1_r<=1;
			HEX0_r<=rechange-25;
		end
		else if((rechange>=30)&&(rechange<35)) begin
			HEX2_r<=3;
			HEX1_r<=0;
			HEX0_r<=rechange-30;
		end
		else if((rechange>=35)&&(rechange<40)) begin
			HEX2_r<=3;
			HEX1_r<=1;
			HEX0_r<=rechange-35;
		end
		else if((rechange>=40)&&(rechange<45)) begin
			HEX2_r<=4;
			HEX1_r<=0;
			HEX0_r<=rechange-40;
		end
		else begin
	 		HEX2_r<=0;
			HEX1_r<=0;
			HEX0_r<=0;
		end
	end
end

always@(HEX0_r or reset_n)begin
	if(!reset_n)
		HEX0_o = 7'b1000000;
	else begin
		case(HEX0_r)
		4'd9: HEX0_o <= 7'b0011000;
		4'd8: HEX0_o <= 7'b0000000;
		4'd7: HEX0_o <= 7'b1111000;
		4'd6: HEX0_o <= 7'b0000010;
		4'd5: HEX0_o <= 7'b0010010;
		4'd4: HEX0_o <= 7'b0011001;
		4'd3: HEX0_o <= 7'b0110000;
		4'd2: HEX0_o <= 7'b0100100;
		4'd1: HEX0_o <= 7'b1111001;
		4'd0: HEX0_o <= 7'b1000000;
		default:HEX0_o<=0;
		endcase		
	end
end

always@(HEX1_r or reset_n)begin
	if(!reset_n)
		HEX1_o = 7'b1000000;
	else begin
		case(HEX1_r)
		4'd9: HEX1_o <= 7'b0011000;
		4'd8: HEX1_o <= 7'b0000000;
		4'd7: HEX1_o <= 7'b1111000;
		4'd6: HEX1_o <= 7'b0000010;
		4'd5: HEX1_o <= 7'b0010010;
		4'd4: HEX1_o <= 7'b0011001;
		4'd3: HEX1_o <= 7'b0110000;
		4'd2: HEX1_o <= 7'b0100100;
		4'd1: HEX1_o <= 7'b1111001;
		4'd0: HEX1_o <= 7'b1000000;
		default:HEX1_o<=0;
		endcase		
	end
end

always@(HEX2_r or reset_n)begin
	if(!reset_n)
		HEX2_o = 7'b1000000;
	else begin
		case(HEX2_r)
		4'd9: HEX2_o <= 7'b0011000;
		4'd8: HEX2_o <= 7'b0000000;
		4'd7: HEX2_o <= 7'b1111000;
		4'd6: HEX2_o <= 7'b0000010;
		4'd5: HEX2_o <= 7'b0010010;
		4'd4: HEX2_o <= 7'b0011001;
		4'd3: HEX2_o <= 7'b0110000;
		4'd2: HEX2_o <= 7'b0100100;
		4'd1: HEX2_o <= 7'b1111001;
		4'd0: HEX2_o <= 7'b1000000;
		default:HEX2_o<=0;
		endcase		
	end
end
always@(HEX4_r or reset_n)begin
	if(!reset_n)
		HEX4_o = 7'b1000000;
	else begin
		case(HEX4_r)
		4'd9: HEX4_o <= 7'b0011000;
		4'd8: HEX4_o <= 7'b0000000;
		4'd7: HEX4_o <= 7'b1111000;
		4'd6: HEX4_o <= 7'b0000010;
		4'd5: HEX4_o <= 7'b0010010;
		4'd4: HEX4_o <= 7'b0011001;
		4'd3: HEX4_o <= 7'b0110000;
		4'd2: HEX4_o <= 7'b0100100;
		4'd1: HEX4_o <= 7'b1111001;
		4'd0: HEX4_o <= 7'b1000000;
		default:HEX4_o<=0;
		endcase		
	end
end
always@(HEX5_r or reset_n)begin
	if(!reset_n)
		HEX5_o = 7'b1000000;
	else begin
		case(HEX5_r)
		4'd9: HEX5_o <= 7'b0011000;
		4'd8: HEX5_o <= 7'b0000000;
		4'd7: HEX5_o <= 7'b1111000;
		4'd6: HEX5_o <= 7'b0000010;
		4'd5: HEX5_o <= 7'b0010010;
		4'd4: HEX5_o <= 7'b0011001;
		4'd3: HEX5_o <= 7'b0110000;
		4'd2: HEX5_o <= 7'b0100100;
		4'd1: HEX5_o <= 7'b1111001;
		4'd0: HEX5_o <= 7'b1000000;
		default:HEX5_o<=0;
		endcase		
	end
end
always@(HEX6_r or reset_n)begin
	if(!reset_n)
		HEX6_o = 7'b1000000;
	else begin
		case(HEX6_r)
		4'd9: HEX6_o <= 7'b0011000;
		4'd8: HEX6_o <= 7'b0000000;
		4'd7: HEX6_o <= 7'b1111000;
		4'd6: HEX6_o <= 7'b0000010;
		4'd5: HEX6_o <= 7'b0010010;
		4'd4: HEX6_o <= 7'b0011001;
		4'd3: HEX6_o <= 7'b0110000;
		4'd2: HEX6_o <= 7'b0100100;
		4'd1: HEX6_o <= 7'b1111001;
		4'd0: HEX6_o <= 7'b1000000;
		default:HEX6_o<=0;
		endcase		
	end
end
always@(HEX7_r or reset_n)begin
	if(!reset_n)
		HEX7_o = 7'b1000000;
	else begin
		case(HEX7_r)
		4'd9: HEX7_o <= 7'b0011000;
		4'd8: HEX7_o <= 7'b0000000;
		4'd7: HEX7_o <= 7'b1111000;
		4'd6: HEX7_o <= 7'b0000010;
		4'd5: HEX7_o <= 7'b0010010;
		4'd4: HEX7_o <= 7'b0011001;
		4'd3: HEX7_o <= 7'b0110000;
		4'd2: HEX7_o <= 7'b0100100;
		4'd1: HEX7_o <= 7'b1111001;
		4'd0: HEX7_o <= 7'b1000000;
		default:HEX7_o<=0;
		endcase		
	end
end
endmodule
