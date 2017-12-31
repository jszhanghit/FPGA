// +FHDR-----------------------------------------------------------------------
//                             张金帅创建
// ----------------------------------------------------------------------------
// PROJECT        : 课程设计，自动售货机
// AUTHOR         : jszhang
// ----------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE     AUTHOR    DESCRIPTION
// 0.1   20170313   jszhang    首次创建
// ----------------------------------------------------------------------------
// ABSTRACT    : 数码管解码电路，应该是没有问题的
// -FHDR-----------------------------------------------------------------------
module decode(clk_i,n_rst_i,in_i,out_o);
input clk_i,n_rst_i;
input [3:0] in_i;
output [6:0] out_o;
reg [6:0] out_o;
always@(posedge clk_i) begin //可以不用时序电路，直接用组合电路也可以 
	if(!n_rst_i) begin
		out_o<=7'd0;
	end
	else begin
		case(in_i)
		4'd9: out_o <= 7'b0011000;
		4'd8: out_o <= 7'b0000000;
		4'd7: out_o <= 7'b1111000;
		4'd6: out_o <= 7'b0000011;
		4'd5: out_o <= 7'b0010010;
		4'd4: out_o <= 7'b0011001;
		4'd3: out_o <= 7'b0110000;
		4'd2: out_o <= 7'b0100100;
		4'd1: out_o <= 7'b1111001;
		4'd0: out_o <= 7'b1000000;
		default:out_o<=0;
		endcase
	end
end


endmodule

