// +FHDR-----------------------------------------------------------------------
//                             张金帅创建
// ----------------------------------------------------------------------------
// PROJECT        : 课程设计，自动售货机
// AUTHOR         : jszhang
// ----------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE     AUTHOR    DESCRIPTION
//   0.1 20170313   jszhang    首次创建
// ----------------------------------------------------------------------------
// ABSTRACT    : 该文件为主体程序，暂时只限于仿真正确，运行时正不正确，鬼知道
// -FHDR-----------------------------------------------------------------------

module autovending(clk_i,kind_i,change_i,cancel_i,sure_i,done_i,n_reset_i,hex7_o,hex6_o,hex5_o,hex4_o,hex2_o,hex1_o,hex0_o,ledg0,ledg7_o);

parameter IDLE=4'd0,//空闲状态
	  coin_in=4'd1,//投币状态
	  return=4'd2,//找零状态
	  cancel=4'd3,
	  success=4'd4;//交易结束

//kind_i：商品种类3'b001商品1,3'b010商品2,3'b100商品3
//change_i:投币类型，3'b001一角,3'b010五角,3'b100一元
input [2:0] kind_i,change_i;
//--------------------------------------------------

//cancel_i:取消购买
//sure_i:确认购买
//n_teset_i:复位
//done_i:确认完成整个交易完成
input cancel_i,sure_i,done_i,n_reset_i,clk_i;
//--------------------------------------------------

//hex7_o,hex6_o  hex5_o,hex4_o    hex2_o,hex1_o,hex0_o
//当前商品价格    显示投币金额        找零
//  元   角       元    角         一元   五角  一角
output [3:0] hex7_o,hex6_o,hex5_o,hex4_o,hex2_o,hex1_o,hex0_o;
//--------------------------------------------------

//   ledg0       ledg7
//  投币充足   购买成功
output ledg0,ledg7_o;
//--------------------------------------------------

reg [3:0] hex7_o,hex6_o,hex5_o,hex4_o,hex2_o,hex1_o,hex0_o;
reg ledg0,ledg7_o;

reg  kind0_r,kind1_r,kind2_r,change0_r,change1_r,change2_r;
reg  cancel_r,sure_r,done_r;

reg [1:0] kind_in1,kind_in2,kind_in0;
reg [1:0] change_in1,change_in2,change_in0;
reg [1:0] cancel_in,sure_in,done_in;

reg ledg7;
wire kind_ok0,kind_ok1,kind_ok2,change_ok0,change_ok1,changeok_2;
wire sure_ok,cancel_ok,done_ok;
//--------------------------------------------------
//
//             检测按键，去抖用
//
//--------------------------------------------------
always@(posedge clk_i) begin
  if(!n_reset_i) begin
    change_in0<=0;
    change_in1<=0;
    change_in2<=0;
    cancel_in<=0;
    done_in<=0;
  end
else begin
	change_in0<={change_in0[0],change_i[0]};
	change_in1<={change_in1[0],change_i[1]};
	change_in2<={change_in2[0],change_i[2]};
	cancel_in<={cancel_in[0],cancel_i};
	done_in<={done_in[0],done_i};
end
end
//上升沿检测
assign change_ok0=change_in0[0]&(!change_in0[1]);
assign change_ok1=change_in1[0]&(!change_in1[1]);
assign change_ok2=change_in2[0]&(!change_in2[1]);
assign cancel_ok=cancel_in[0]&(!cancel_in[1]);
assign done_ok=done_in[0]&(!done_in[1]);
reg temp;
reg [19:0] cnt_base;
always@(posedge clk_i) begin
	if(!n_reset_i) begin
		cnt_base<=20'd0;
		temp<=1'd0;
	end
	else if(change_ok0||change_ok1||change_ok2||cancel_ok||done_ok)
	begin
		cnt_base<=0;
		temp<=1'd1;
	end
	else if(temp==1'b1)begin
		cnt_base<=cnt_base+1;
		if(cnt_base==20'hfffff)
			temp<=0;
		else
			temp<=1;
	end
	else
		cnt_base<=0;
end

always@(posedge clk_i) begin
	if(!n_reset_i) begin
		change0_r<=0;
		change1_r<=0;
		change2_r<=0;
		cancel_r<=1'b0;
		done_r<=1'b0;
	end
	else 
	if(cnt_base==20'h186A0) begin
		change0_r<=change_in0[0];
		change1_r<=change_in1[0];
		change2_r<=change_in2[0];
		cancel_r<=cancel_in[0];
		done_r<=done_in[0];
	end
	else begin               //产生去抖后的按键状态
		change0_r<=0;
		change1_r<=0;
		change2_r<=0;
		cancel_r<=0;
		done_r<=0;		
	end
end

//--------------------------------------------------


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
always@(posedge clk_i or negedge n_reset_i) begin
	if(!n_reset_i)begin
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
always@(posedge clk_i or negedge n_reset_i) begin
	if(!n_reset_i) begin
		next_state<=IDLE;
	end
	else begin
		case(state)
			IDLE: begin
				if(kind_i) begin
					next_state<=coin_in;
				end
				else
					next_state<=IDLE;	
			end
			coin_in: begin
				if(cancel_i==1)begin
					next_state=cancel;
				end
				else if((ledg0==1)&&(sure_i==1)) begin
					next_state<=return;
					end
				else begin
					next_state<=coin_in;
					end
			end
			return:begin
				if(done_i==1)
					next_state<=success;
				else
					next_state<=return;
			end
			cancel:begin
				if(done_i==1)
					next_state<=success;
				else
					next_state<=cancel;
			end
			success:begin
				if(done_i==1)
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
always@(posedge clk_i or negedge n_reset_i)begin
	if(!n_reset_i) begin
		hex7_o<=4'd0;
		hex6_o<=4'd0;
		ledg0<=0;
	end
	else begin
		case(kind_i)
			3'b001:begin
				hex7_o<=4'd1;
				hex6_o<=4'd0;
				if(money>=8'd10)
					ledg0<=1;
				else
					ledg0<=0;
			end
			3'b010:begin
				hex7_o<=4'd1;
				hex6_o<=4'd4;
				if(money>=8'd14)
					ledg0<=1;
				else
					ledg0<=0;
			end
			3'b100:begin
				hex7_o<=4'd2;
				hex6_o<=4'd0;
				if(money>=8'd20)
					ledg0<=1;
				else
					ledg0<=0;
			end
			default:begin
			  hex7_o<=4'd0;
			  hex6_o<=4'd0;
			  ledg0<=0;
			  end
			  endcase
	end

end

//-----------------------------------------------
//              ledg7_o输出产生逻辑
//
//-----------------------------------------------
always@(posedge clk_i or negedge n_reset_i) begin
	if(!n_reset_i) begin
		ledg7<=1'b0;
	end
	else begin
		case(state)
			IDLE: begin
				ledg7<=1'b0;
			end
			coin_in: begin
				ledg7<=1'b0;
			end
			return: begin
				if(done_r==1)
					ledg7<=1'b1;
				else
					ledg7<=1'b0;
			end
			cancel: begin
				ledg7<=0;
			end
			success: begin
				ledg7<=1'b1;
			end
			default: begin
				ledg7<=1'b0;
			end
		endcase
	end
end
always@(posedge clk_i or negedge n_reset_i) begin
	if(!n_reset_i) begin
		ledg7_o<=1'b0;
	end
	else 
		ledg7_o<=ledg7;
end

//-------------------------------------------------
//          金额计数，每次金额变化则进
//              行相应的金额计数  
//
//-------------------------------------------------
always@(posedge clk_i or negedge n_reset_i) begin
	if(!n_reset_i) 
		money<=8'd0;
	else begin
	       case(state)
		       IDLE: money<=0;
		       coin_in:begin
			       if(change0_r==1'b1)
				       money<=money+8'd1;
			       else if(change1_r==1'b1)
				       money<=money+8'd5;
			       else if(change2_r==1'b1)
				       money<=money+8'd10;
			       else
				       money<=money;
		       end
		       return: begin
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
always@(posedge clk_i or negedge n_reset_i) begin
	if(!n_reset_i) begin
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
			return:begin
				if(cancel_r==1)
					rechange<=money;
				else begin
				case(kind_i)
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
always@(posedge clk_i) begin
	if(!n_reset_i) begin
		hex5_o<=4'd0;
		hex4_o<=4'd0;
	end
	else begin
		if(money<10)begin			
			hex5_o<=0;
			hex4_o<=money;
		end 
		else if((10<=money)&&(money<20)) begin
			hex5_o<=1;
			hex4_o<=(money-10);
		end 
		else if((money>=20)&&(money<30)) begin
			hex5_o<=2;
			hex4_o<=(money-20);
		end 
		else if((money>=30)&&(money<40))begin
			hex5_o<=3;
			hex4_o<=(money-30);
		end
		else begin
			hex5_o<=hex5_o;
			hex4_o<=hex4_o;
		end
	end
end
always@(posedge clk_i or negedge n_reset_i) begin
	if(!n_reset_i) begin
		hex2_o<=0;
		hex1_o<=0;
		hex0_o<=0;
	end
	else begin
		if(rechange<5) begin
			hex0_o<=rechange;
			hex1_o<=0;
			hex2_o<=0;
		end
		else if((5<=rechange)&&(rechange<10)) begin
			hex0_o<=rechange-5;
			hex1_o<=1;
			hex2_o<=0;
		end
		else if((rechange>=10)&&(rechange<15)) begin
			hex2_o<=1;
			hex1_o<=0;
			hex0_o<=rechange-10;
		end
		else if((rechange>=15)&&(rechange<20)) begin
			hex2_o<=1;
	 		hex1_o<=1;
		 	hex0_o<=rechange-15;
		end
		else if((rechange>=20)&&(rechange<25)) begin
			hex2_o<=2;
			hex1_o<=0;
			hex0_o<=rechange-20;
		end
		else if((rechange>=25)&&(rechange<30)) begin
			hex2_o<=2;
			hex1_o<=1;
			hex0_o<=rechange-25;
		end
		else if((rechange>=30)&&(rechange<35)) begin
			hex2_o<=3;
			hex1_o<=0;
			hex0_o<=rechange-30;
		end
		else if((rechange>=35)&&(rechange<40)) begin
			hex2_o<=3;
			hex1_o<=1;
			hex0_o<=rechange-35;
		end
		else if((rechange>=40)&&(rechange<45)) begin
			hex2_o<=4;
			hex1_o<=0;
			hex0_o<=rechange-40;
		end
		else begin
	 		hex2_o<=0;
			hex1_o<=0;
			hex0_o<=0;
		end
	end
end

endmodule




