// +FHDR-----------------------------------------------------------------------
//                             �Ž�˧����
// ----------------------------------------------------------------------------
// PROJECT        : �γ���ƣ��Զ��ۻ���
// AUTHOR         : jszhang
// ----------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE     AUTHOR    DESCRIPTION
// 0.1   20170313   jszhang    �״δ���
// ----------------------------------------------------------------------------
// ABSTRACT    :         �����ļ�����Ҫ���������Ҫ���ܳ���������һ��
// -FHDR-----------------------------------------------------------------------
module top(clk_i,kind_i,change_i,cancel_i,sure_i,done_i,n_reset_i,hex7_o,hex6_o,hex5_o,hex4_o,hex2_o,hex1_o,hex0_o,ledg0,ledg7);
input clk_i,cancel_i,sure_i,done_i,n_reset_i;

input [2:0] kind_i,change_i;
output [6:0] hex7_o,hex6_o,hex5_o,hex4_o,hex2_o,hex1_o,hex0_o;
output ledg0,ledg7;
wire [3:0] hex7_oa,hex6_oa,hex5_oa,hex4_oa,hex2_oa,hex1_oa,hex0_oa;

autovending u1(clk_i,kind_i,change_i,cancel_i,sure_i,done_i,n_reset_i,hex7_oa,hex6_oa,hex5_oa,hex4_oa,hex2_oa,hex1_oa,hex0_oa,ledg0,ledg7);

decode d7(clk_i,n_reset_i,hex7_oa,hex7_o);
decode d6(clk_i,n_reset_i,hex6_oa,hex6_o);
decode d5(clk_i,n_reset_i,hex5_oa,hex5_o);
decode d4(clk_i,n_reset_i,hex4_oa,hex4_o);
decode d2(clk_i,n_reset_i,hex2_oa,hex2_o);
decode d1(clk_i,n_reset_i,hex1_oa,hex1_o);
decode d0(clk_i,n_reset_i,hex0_oa,hex0_o);

endmodule
