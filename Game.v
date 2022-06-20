/*----------------------------------------------------- 
Date			: 2022/06/20
Author		: 四電子四A 麥光廷 B10713048
Design Name : 躲避車
File Name   : Game.v
Compiler	   : Quartus II 18.1
Board 		: DE10-Standard
Description : 1. 玩家可以利用按鈕進行左右移動，
				  2. 生成三個車道
				  3. 隨機生成障礙物，要躲避障礙物，
				  4. 障礙物的難度會隨時間增加速度變快並切換場景，
				  5. 每存活一段時間玩家就可以獲得分數(七段顯示器)
				  6. 有三條命，如果碰到障礙物三次就結束遊戲
				  7. 指撥開關可以開turbo(加速)
              ----------------------------------------
遊 玩 方 式	: Key[1:0]分別為"左右"移動。
				  SW[9]為Turbo(加速)開關，速度為原先兩倍。
				  SW[0]為Stop (暫停)開關，"1"即可開始遊戲，"0"可暫停遊戲。
				  7-Segment會顯示獲取分數，一段時間後，速度達最高速。
				  左上: 顯示當前遊戲狀態。
				  右上: 三格血，歸零則遊戲結束。
				  左下: 遊玩經過的時間。
				  右下: 顯示獲得分數和最佳分數。
----------------------------------------------------*/
module Game (RGB, VGA_CLK, VGA_BLANK_N, 
				 VGA_HS, VGA_VS, VGA_SYNC_N,
				 Seg5, Seg4, Seg3, Seg2, Seg1, Seg0,
				 Clk_50MHz, Key, turbo, Stop);
//---------------------------------------------------- IO Port
// Output for VGA
output reg [23:0]RGB;
output reg VGA_CLK = 1'b0, 
			  VGA_BLANK_N, VGA_HS, VGA_VS, 
			  VGA_SYNC_N = 1'b0;
// Output for 7-Segment
output reg [6:0]Seg5 = 7'b100_0000, Seg4 = 7'b100_0000,
					 Seg3 = 7'b100_0000, Seg2 = 7'b100_0000,
					 Seg1 = 7'b100_0000, Seg0 = 7'b100_0000;
// Input for Clock 50MHz
input Clk_50MHz;
// Input for Key[3] = Restart, Key[1] = Left, Key[0] = Right
input [3:0]Key;
// Input for Switch
input turbo, Stop;
//---------------------------------------------------- VGA Scan Sync
// 25MHz -> 40ns
always@(posedge Clk_50MHz) VGA_CLK = ~VGA_CLK;
// Screen SCAN
reg [9:0]hor_counter, ver_counter;
always@(posedge VGA_CLK)begin
	// Horizontal Scan
	if(hor_counter == 795) hor_counter = 0;
	else hor_counter = hor_counter + 1;
	// Vertical Scan
	if(ver_counter == 523 && hor_counter == 700) ver_counter = 0;
	else if(hor_counter == 700) ver_counter = ver_counter + 1;
	// Horizontal Signal
	if(hor_counter >= 658 && hor_counter <= 753) VGA_HS = 1'b0;
	else VGA_HS = 1'b1;
	// Vertical Signal
	if(ver_counter >= 491 && ver_counter <= 492) VGA_VS = 1'b0;
	else VGA_VS = 1'b1;
	// Output RGB Data
	if(hor_counter >= 0 && hor_counter <= 639) VGA_BLANK_N = 1'b1;
	else VGA_BLANK_N = 1'b0;
end
//---------------------------------------------------- 7-Segment Function
// Binary to Seg
function [6:0]Encoder;
	input [3:0]In; // input
	begin// Converter
		case(In)
			4'd0:Encoder = 7'b100_0000;
			4'd1:Encoder = 7'b111_1001;
			4'd2:Encoder = 7'b010_0100;
			4'd3:Encoder = 7'b011_0000;
			4'd4:Encoder = 7'b001_1001;
			4'd5:Encoder = 7'b001_0010;
			4'd6:Encoder = 7'b000_0010;
			4'd7:Encoder = 7'b111_1000;
			4'd8:Encoder = 7'b000_0000;
			4'd9:Encoder = 7'b001_0000;
		endcase
	end
endfunction
//---------------------------------------------------- Number Paint Function
// Number to Paint
function [6:0]Number_Paint;
	input [3:0]In; // input
	input [9:0]x, y;
	begin // Return
		case(In)
			4'd0:Number_Paint = dataX_Zero[x][y];
			4'd1:Number_Paint = dataX_One[x][y];
			4'd2:Number_Paint = dataX_Two[x][y];
			4'd3:Number_Paint = dataX_Three[x][y];
			4'd4:Number_Paint = dataX_Four[x][y];
			4'd5:Number_Paint = dataX_Five[x][y];
			4'd6:Number_Paint = dataX_Six[x][y];
			4'd7:Number_Paint = dataX_Seven[x][y];
			4'd8:Number_Paint = dataX_Eight[x][y];
			4'd9:Number_Paint = dataX_Nine[x][y];
		endcase
	end
endfunction
//---------------------------------------------------- Generate Clock
// 6Hz Clock for control Car move
reg CLK_6 = 1'b0;
reg [27:0]CLK_count_6 = 28'd0;
always@(posedge Clk_50MHz or negedge Stop)begin
	if(!Stop) begin
		CLK_6 = 1'b0;
		CLK_count_6 = 28'd0;
	end else begin
		if(CLK_count_6 > 4166667)begin
			CLK_6 = ~CLK_6; CLK_count_6 = 0;
		end else CLK_count_6 = CLK_count_6 + 1;
	end
end
//---------------------------------------------------- 
// 8 Hz or 16 Hz Clock for speed count up
reg [27:0]CLK_count_8_16 = 28'd0, COUNT_CLK = 3125000;
always@(posedge Clk_50MHz or negedge Stop or negedge Key[3])begin
	// Restart
	if(!Key[3]) begin
		speed_count = 10937500;
		CLK_count_8_16 = 28'd0;
	// Stop
	end else if(!Stop) begin
		CLK_count_8_16 = 28'd0;
	// Start
	end else begin
		// turbo on
		if(turbo) COUNT_CLK = 1562500; // (16Hz) 1562500
		else 		 COUNT_CLK = 3125000; // ( 8Hz) 3125000 
		// speed up
		if(CLK_count_8_16 > COUNT_CLK)begin
			CLK_count_8_16 = 0;
			//---------------------------------------------------- --------------
			// when(CLK_8_16) addition "speed_count" up until the N-Clock is 128Hz.
			if(turbo && speed_count >= 12402343) speed_count = 12402343; // N-Clock == 256Hz
			else if(turbo && speed_count >= 12304688) speed_count = speed_count + 500; // N-Clock < 256Hz
			else if(speed_count >= 12304688) speed_count = 12304688; // N-Clock == 128Hz
			else if(speed_count >= 12109375) speed_count = speed_count + 500; // N-Clock < 128Hz
			else if(speed_count >= 11718750) speed_count = speed_count + 1000; // N-Clock < 64Hz
			else speed_count = speed_count + 2000; // N-Clock < 32Hz
			//-------------------------------------------------------------------
		end else CLK_count_8_16 = CLK_count_8_16 + 1;
	end
end
//---------------------------------------------------- 
// N Hz Clock for Barrier down
reg CLK = 1'b0;
reg [27:0]CLK_count = 28'd0, speed_count = 10937500; // initial N-Clock is 16Hz.
always@(posedge Clk_50MHz or negedge Stop or negedge Key[3])begin
	if(!Key[3]) begin
		CLK = 1'b0;
		CLK_count = 28'd0;
	end else if(!Stop) begin
		CLK = 1'b0;
		CLK_count = 28'd0;
	end else begin
		if(CLK_count > (12500000 - speed_count))begin
			CLK = ~CLK; CLK_count = 0;
		end else CLK_count = CLK_count + 1;
	end
end
//---------------------------------------------------- Main Program
// Compute Score
reg [19:0]score_count = 0,  // Score
			 best_score  = 0;  // Best
reg [27:0]clk_score_count = 28'd0, turbo_score_count;
always@(posedge Clk_50MHz or negedge Stop or negedge Key[3])begin
	if(!Key[3])begin
		score_count = 0;
		clk_score_count = 28'd0;
	end else if(!Stop)begin
		clk_score_count = 28'd0;
	end else begin
		// turbo on or off
		if(turbo) turbo_score_count =  6250000;
		else 		 turbo_score_count = 12500000;
		// Score up
		if(clk_score_count > turbo_score_count)begin
			clk_score_count = 0;
			// Score up
			if(State_Blood != 3'b000)begin
				score_count = score_count + 1;
				// 2 times
				if(Coin_up && turbo_score_count == 12500000) 
					score_count = score_count + 500;
				// 4 times
				if(Coin_up && turbo_score_count ==  6250000) 
					score_count = score_count + 250;
			end else begin
				score_count = score_count;
				// Best Score
				if(score_count > best_score) best_score <= score_count;
			end
		end else clk_score_count = clk_score_count + 1;
	end
end
//----------------------------------------------------
// 1 second Timer (turbo => 0.5 second)
reg [27:0]one_second = 28'd0, lfsr_count = 100000000, timer_count;
reg [19:0]lfsr_timer  = 0;  // time
reg Scene_State = 1'b0;
// LFSR Clock 
reg CLK_LFSR = 1'b0;
reg [27:0]LFSR_CLK_Conut = 28'd0;
always@(posedge Clk_50MHz or negedge Stop or negedge Key[3])begin
	if(!Key[3]) begin
		lfsr_count = 100000000;
		lfsr_timer = 0;
		one_second = 28'd0;
		LFSR_CLK_Conut = 28'd0;
		Scene_State = 1'b0;
	end else if(!Stop) begin
		one_second = 28'd0;
		LFSR_CLK_Conut = 28'd0;
	end else begin
		// turbo on or off
		if(turbo) timer_count = 25000000;
		else 		 timer_count = 50000000; 
		// 1 or 0.5 second timer
		if(one_second > timer_count)begin
			one_second = 0;
			// time up
			if(State_Blood != 3'b000) lfsr_timer = lfsr_timer + 1;
			else lfsr_timer = lfsr_timer;
			// 10 second count
			if(lfsr_timer % 10 == 0)begin
				if(lfsr_count != 12500000) lfsr_count = lfsr_count / 2;
				// Background swap
				if(State_Blood != 3'b000) Scene_State = ~Scene_State;
			end
		end else one_second = one_second + 1;
		// Generate Clock for LFSR
		if(LFSR_CLK_Conut > lfsr_count)begin
			CLK_LFSR = ~CLK_LFSR; LFSR_CLK_Conut = 0;
		end else LFSR_CLK_Conut = LFSR_CLK_Conut + 1;
	end
end
//---------------------------------------------------- 
// Display Score to 7-Segment
reg [3:0]m2 = 0, m1 = 0, s2 = 0, s1 = 0;
reg [3:0]mt, m, t, h, d, b;
reg [3:0]b_mt, b_m, b_t, b_h, b_d, b_b;
always@(score_count or lfsr_timer)begin
	// time
	m2 = (lfsr_timer / 60) / 10;
	m1 = (lfsr_timer / 60) % 10;
	s2 = (lfsr_timer % 60) / 10;
	s1 = (lfsr_timer % 60) % 10;
	// Score number display
	mt = score_count / 100000; 
	m  = (score_count % 100000) / 10000; 
	t  = ((score_count % 100000) % 10000) / 1000;
	h  = (((score_count % 100000) % 10000) % 1000) / 100;
	d  = ((((score_count % 100000) % 10000) % 1000) % 100) / 10;
	b  = ((((score_count % 100000) % 10000) % 1000) % 100) % 10;
	Seg5 = Encoder(mt); 
	Seg4 = Encoder(m); 
	Seg3 = Encoder(t);
	Seg2 = Encoder(h); 
	Seg1 = Encoder(d); 
	Seg0 = Encoder(b);
	// Best number display
	b_mt = best_score / 100000; 
	b_m  = (best_score % 100000) / 10000; 
	b_t  = ((best_score % 100000) % 10000) / 1000;
	b_h  = (((best_score % 100000) % 10000) % 1000) / 100;
	b_d  = ((((best_score % 100000) % 10000) % 1000) % 100) / 10;
	b_b  = ((((best_score % 100000) % 10000) % 1000) % 100) % 10;
end
//----------------------------------------------------
// LFSR Generate Random number
reg [7:0]rand_num = 8'b1001_0101;
reg [2:0]Barrier = 3'b000;
always@(posedge CLK_LFSR)begin
	// generate 255 ~ 0
	if(rand_num == 0)begin
		rand_num = 8'b1001_0101;
	end else begin
		rand_num[0] <= rand_num[7];
		rand_num[1] <= rand_num[0];
		rand_num[2] <= rand_num[1];
		rand_num[3] <= rand_num[2];
		rand_num[4] <= rand_num[3] ^ rand_num[7];
		rand_num[5] <= rand_num[4] ^ rand_num[7];
		rand_num[6] <= rand_num[5] ^ rand_num[7];
		rand_num[7] <= rand_num[6];
	end
end
//----------------------------------------------------
// LFSR for Box Probability
reg [7:0]prob = 8'b1101_0001;
always@(posedge CLK)begin
	// generate 255 ~ 0
	if(prob == 0)begin
		prob = 8'b1001_0101;
	end else begin
		prob[0] <= prob[7];
		prob[1] <= prob[0];
		prob[2] <= prob[1];
		prob[3] <= prob[2];
		prob[4] <= prob[3] ^ prob[7];
		prob[5] <= prob[4] ^ prob[7];
		prob[6] <= prob[5] ^ prob[7];
		prob[7] <= prob[6];
	end
end
//----------------------------------------------------
// Collision Event
reg Event_Collision = 0, car_boom = 0;
reg [27:0]CLK_count_2 = 28'd0, boom_count = 28'd0;
reg [2:0]Empty_box = 3'b000;
always@(posedge Clk_50MHz or negedge Key[3])begin
	// Reply Blood
	if(!Key[3]) State_Blood = 3'b111;
	else if(Stop)begin
		// Timer 1 second => Boom Special Effects
		if(!car_boom) begin
			boom_count = 28'd0;
		end else begin
			if(boom_count > 25000000)begin
				car_boom  = 0;
				Blood_up  = 0;
				Bomb_down = 0;
				Coin_up   = 0;
				Empty_box = 0;
			end else boom_count = boom_count + 1;
		end
		// Collision
		if(!Event_Collision)begin
			CLK_count_2 = 28'd0;
			case(Move_Car)
				6'b000001: begin
					// C-Barrier
					if(Scene_State)begin
						if((yBarrC + 43) > 315 && yBarrC < 325)begin
							if(prob > 190 && State_Blood != 3'b000)begin 
								State_Blood <= {State_Blood[1:0], 1'b1};
								Blood_up[0] = 1;
							end else if(prob > 130 && prob < 191 && State_Blood != 3'b000)begin
								State_Blood = State_Blood >> 2;
								Bomb_down[0] = 1;
							end else if(prob > 60 && prob < 131 && State_Blood != 3'b000)begin
								Coin_up[0] = 1;
							end else begin
								State_Blood = State_Blood >> 1;
								Empty_box[0] = 1;
							end
							Event_Collision = 1;
							car_boom = 1;
						end
					end else begin
						if((yBarrC + 43) > 315 && yBarrC < 325)begin
							State_Blood = State_Blood >> 1;
							Event_Collision = 1;
							car_boom = 1;
						end
					end
				end
				6'b000010: begin
					// C-Bus
					if((yBusC + 43) > 315 && yBusC < 325)begin
						State_Blood = State_Blood >> 1;
						Event_Collision = 1;
						car_boom = 1;
					end
				end
				6'b000100: begin
					// B-Barrier
					if(Scene_State)begin
						if((yBarrB + 43) > 315 && yBarrB < 325)begin
							if(prob > 190 && State_Blood != 3'b000)begin 
								State_Blood <= {State_Blood[1:0], 1'b1};
								Blood_up[1] = 1;
							end else if(prob > 130 && prob < 191 && State_Blood != 3'b000)begin
								State_Blood = State_Blood >> 2;
								Bomb_down[1] = 1;
							end else if(prob > 60 && prob < 131 && State_Blood != 3'b000)begin
								Coin_up[1] = 1;
							end else begin
								State_Blood = State_Blood >> 1;
								Empty_box[1] = 1;
							end
							Event_Collision = 1;
							car_boom = 1;
						end
					end else begin
						if((yBarrB + 43) > 315 && yBarrB < 325)begin
							State_Blood = State_Blood >> 1;
							Event_Collision = 1;
							car_boom = 1;
						end
					end
				end
				6'b001000: begin
					// B-Bus
					if((yBusB + 43) > 315 && yBusB < 325)begin 
						State_Blood = State_Blood >> 1;
						Event_Collision = 1;
						car_boom = 1;
					end
				end
				6'b010000: begin
					// A-Barrier
					if(Scene_State)begin
						if((yBarrA + 43) > 315 && yBarrA < 325)begin
							if(prob > 190 && State_Blood != 3'b000)begin 
								State_Blood <= {State_Blood[1:0], 1'b1};
								Blood_up[2] = 1;
							end else if(prob > 130 && prob < 191 && State_Blood != 3'b000)begin
								State_Blood = State_Blood >> 2;
								Bomb_down[2] = 1;
							end else if(prob > 60 && prob < 131 && State_Blood != 3'b000)begin
								Coin_up[2] = 1;
							end else begin
								State_Blood = State_Blood >> 1;
								Empty_box[2] = 1;
							end
							Event_Collision = 1;
							car_boom = 1;
						end
					end else begin
						if((yBarrA + 43) > 315 && yBarrA < 325)begin
							State_Blood = State_Blood >> 1;
							Event_Collision = 1;
							car_boom = 1;
						end
					end
				end
				6'b100000: begin
					// A-Bus
					if((yBusA + 43) > 315 && yBusA < 325)begin 
						State_Blood = State_Blood >> 1;
						Event_Collision = 1;
						car_boom = 1;
					end
				end
			endcase
		end else begin
			// Timer 2 second => Uncollision Event
			if(CLK_count_2 > 50000000) Event_Collision = 0;
			else CLK_count_2 = CLK_count_2 + 1;
		end
	end
end
//---------------------------------------------------- 
// Control Car Move
reg [9:0]x = 332, y = 315;
reg [5:0]Move_Car = 6'b000100;
always@(posedge CLK_6 or negedge Key[3])begin
	// Restart
	if(!Key[3]) Move_Car <= 6'b000100;
	// Right Move
	else if(!Key[0]) Move_Car <= (Move_Car[0] == 1) ? 6'b000001 : {Move_Car[0], Move_Car[5:1]};
	// Left Move
	else if(!Key[1]) Move_Car <= (Move_Car[5] == 1) ? 6'b100000 : {Move_Car[4:0], Move_Car[5]};
end
always@(Move_Car)begin
	// Setting Car Coordinate
	case (Move_Car)
		6'b000001: x = 432;
		6'b000010: x = 387;
		6'b000100: x = 332;
		6'b001000: x = 287;
		6'b010000: x = 232;
		6'b100000: x = 187;
		default:   x = x;
	endcase
end
//---------------------------------------------------- 
// Car Output Setting
// Scaling 2 times
reg [9:0]x_Car, y_Car;
reg [21:0]X_Car, Y_Car, Z_Car, W_Car, M_Car, N_Car, O_Car;
always@(*)begin
	// Car
	if(hor_counter > x && ver_counter > y) begin
		x_Car = (hor_counter - (x + 1))/2;
		y_Car = (ver_counter - (y + 1))/2;
		X_Car = dataX_Car[x_Car][y_Car];
		Y_Car = dataY_Car[x_Car][y_Car];
		Z_Car = dataZ_Car[x_Car][y_Car];
		W_Car = dataW_Car[x_Car][y_Car];
		M_Car = dataM_Car[x_Car][y_Car];
		N_Car = dataN_Car[x_Car][y_Car];
		O_Car = dataO_Car[x_Car][y_Car];
	end
	// Stop Scan
	if(x_Car > 9 || y_Car > 21) begin
		X_Car = 0; Y_Car = 0; Z_Car = 0; W_Car = 0;
		M_Car = 0; N_Car = 0; O_Car = 0;
	end
end
//---------------------------------------------------- 
// A-Barrier Output Setting
// Scaling 2 times
reg [9:0]xBarrA = 225, yBarrA = 70;
always@(posedge CLK or negedge Key[3])begin
	if(!Key[3])begin
		Barrier[2] = 0;
		yBarrA = 70;
	end else if(Barrier[2])begin
		yBarrA = yBarrA + 1;
		if(yBarrA >= 370) begin
			yBarrA = 70;
			Barrier[2] = 0;
		end else if(Blood_up[2] || Bomb_down[2] || Coin_up[2] || Empty_box[2])begin
			yBarrA = 70;
			Barrier[2] = 0;
		end
	end else if(rand_num > 170) Barrier[2] = 1;
end
reg [9:0]x_barr_A, y_barr_A;
reg [20:0]X_Barr_A, Y_Barr_A;
always@(*)begin
	// Barrier
	if(hor_counter > xBarrA && ver_counter > yBarrA) begin
		x_barr_A = (hor_counter - (xBarrA + 1))/2;
		y_barr_A = (ver_counter - (yBarrA + 1))/2;
		if(!Scene_State)begin
			X_Barr_A = dataX_Hole[x_barr_A][y_barr_A];
			Y_Barr_A = 0;
		end else begin
			X_Barr_A = dataX_Box[x_barr_A][y_barr_A];
			Y_Barr_A = dataY_Box[x_barr_A][y_barr_A];
		end
	end
	// Stop Scan
	if(x_barr_A > 18 || y_barr_A > 20) begin
		X_Barr_A = 0; Y_Barr_A = 0;
	end
end
//---------------------------------------------------- 
// B-Barrier Output Setting
// Scaling 2 times
reg [9:0]xBarrB = 325, yBarrB = 70;
always@(posedge CLK or negedge Key[3])begin
	if(!Key[3])begin
		Barrier[1] = 0;
		yBarrB = 70;
	end else if(Barrier[1])begin
		yBarrB = yBarrB + 1;
		if(yBarrB >= 370)begin
			yBarrB = 70;
			Barrier[1] = 0;
		end else if(Blood_up[1] || Bomb_down[1] || Coin_up[1] || Empty_box[1])begin
			yBarrB = 70;
			Barrier[1] = 0;
		end
	end else if(rand_num > 90 && rand_num < 171) Barrier[1] = 1;
end
reg [9:0]x_barr_B, y_barr_B;
reg [20:0]X_Barr_B, Y_Barr_B;
always@(*)begin
	// Barrier
	if(hor_counter > xBarrB && ver_counter > yBarrB) begin
		x_barr_B = (hor_counter - (xBarrB + 1))/2;
		y_barr_B = (ver_counter - (yBarrB + 1))/2;
		if(!Scene_State)begin
			X_Barr_B = dataX_Hole[x_barr_B][y_barr_B];
			Y_Barr_B = 0;
		end else begin
			X_Barr_B = dataX_Box[x_barr_B][y_barr_B];
			Y_Barr_B = dataY_Box[x_barr_B][y_barr_B];
		end
	end
	// Stop Scan
	if(x_barr_B > 18 || y_barr_B > 20) begin
		X_Barr_B = 0; Y_Barr_B = 0;
	end
end
//---------------------------------------------------- 
// C-Barrier Output Setting
// Scaling 2 times
reg [9:0]xBarrC = 425, yBarrC = 70;
always@(posedge CLK or negedge Key[3])begin
	if(!Key[3])begin
		Barrier[0] = 0;
		yBarrC = 70;
	end else if(Barrier[0])begin
		yBarrC = yBarrC + 1;
		if(yBarrC >= 370)begin
			yBarrC = 70;
			Barrier[0] = 0;
		end else if(Blood_up[0] || Bomb_down[0] || Coin_up[0] || Empty_box[0])begin
			yBarrC = 70;
			Barrier[0] = 0;
		end
	end else if(rand_num < 91) Barrier[0] = 1;
end
reg [9:0]x_barr_C, y_barr_C;
reg [20:0]X_Barr_C, Y_Barr_C;
always@(*)begin
	// Barrier
	if(hor_counter > xBarrC && ver_counter > yBarrC) begin
		x_barr_C = (hor_counter - (xBarrC + 1))/2;
		y_barr_C = (ver_counter - (yBarrC + 1))/2;
		if(!Scene_State)begin
			X_Barr_C = dataX_Hole[x_barr_C][y_barr_C];
			Y_Barr_C = 0;
		end else begin
			X_Barr_C = dataX_Box[x_barr_C][y_barr_C];
			Y_Barr_C = dataY_Box[x_barr_C][y_barr_C];
		end
	end
	// Stop Scan
	if(x_barr_C > 18 || y_barr_C > 20) begin
		X_Barr_C = 0; Y_Barr_C = 0;
	end
end
//---------------------------------------------------- 
// A-Bus Output Setting
// Coordinate Locate in A(188, 71)
// Scaling 2 times
reg [9:0]xBusA = 187, yBusA = 70;
always@(posedge CLK or negedge Key[3])begin
	if(!Key[3]) yBusA = 70;
	else yBusA = (yBusA == 370) ? 70 : yBusA + 1;
end
reg [9:0]x_bus_A, y_bus_A;
reg [21:0]X_Bus_A, Y_Bus_A, Z_Bus_A, W_Bus_A, M_Bus_A, N_Bus_A;
always@(*)begin
	// Bus
	if(hor_counter > xBusA && ver_counter > yBusA) begin
		x_bus_A = (hor_counter - (xBusA + 1))/2;
		y_bus_A = (ver_counter - (yBusA + 1))/2;
		X_Bus_A = dataX_Bus[x_bus_A][y_bus_A];
		Y_Bus_A = dataY_Bus[x_bus_A][y_bus_A];
		Z_Bus_A = dataZ_Bus[x_bus_A][y_bus_A];
		W_Bus_A = dataW_Bus[x_bus_A][y_bus_A];
		M_Bus_A = dataM_Bus[x_bus_A][y_bus_A];
		N_Bus_A = dataN_Bus[x_bus_A][y_bus_A];
	end
	// Stop Scan
	if(x_bus_A > 9 || y_bus_A > 21) begin
		X_Bus_A = 0; Y_Bus_A = 0; Z_Bus_A = 0; W_Bus_A = 0;
		M_Bus_A = 0; N_Bus_A = 0;
	end
end
//---------------------------------------------------- 
// B-Bus Output Setting
// Coordinate Locate in B(288, 201)
// Scaling 2 times
reg [9:0]xBusB = 287, yBusB = 200;
always@(posedge CLK or negedge Key[3])begin
	if(!Key[3]) yBusB = 200;
	else yBusB = (yBusB == 370) ? 70 : yBusB + 1;
end
reg [9:0]x_bus_B, y_bus_B;
reg [21:0]X_Bus_B, Y_Bus_B, Z_Bus_B, W_Bus_B, M_Bus_B, N_Bus_B;
always@(*)begin
	// Bus
	if(hor_counter > xBusB && ver_counter > yBusB) begin
		x_bus_B = (hor_counter - (xBusB + 1))/2;
		y_bus_B = (ver_counter - (yBusB + 1))/2;
		X_Bus_B = dataX_Bus[x_bus_B][y_bus_B];
		Y_Bus_B = dataY_Bus[x_bus_B][y_bus_B];
		Z_Bus_B = dataZ_Bus[x_bus_B][y_bus_B];
		W_Bus_B = dataW_Bus[x_bus_B][y_bus_B];
		M_Bus_B = dataM_Bus[x_bus_B][y_bus_B];
		N_Bus_B = dataN_Bus[x_bus_B][y_bus_B];
	end
	// Stop Scan
	if(x_bus_B > 9 || y_bus_B > 21) begin
		X_Bus_B = 0; Y_Bus_B = 0; Z_Bus_B = 0; W_Bus_B = 0;
		M_Bus_B = 0; N_Bus_B = 0;
	end
end
//---------------------------------------------------- 
// C-Bus Output Setting
// Coordinate Locate in C(388, 301)
// Scaling 2 times
reg [9:0]xBusC = 387, yBusC = 300;
always@(posedge CLK or negedge Key[3])begin
	if(!Key[3]) yBusC = 300;
	else yBusC = (yBusC == 370) ? 70 : yBusC + 1;
end
reg [9:0]x_bus_C, y_bus_C;
reg [21:0]X_Bus_C, Y_Bus_C, Z_Bus_C, W_Bus_C, M_Bus_C, N_Bus_C;
always@(*)begin
	// Bus
	if(hor_counter > xBusC && ver_counter > yBusC) begin
		x_bus_C = (hor_counter - (xBusC + 1))/2;
		y_bus_C = (ver_counter - (yBusC + 1))/2;
		X_Bus_C = dataX_Bus[x_bus_C][y_bus_C];
		Y_Bus_C = dataY_Bus[x_bus_C][y_bus_C];
		Z_Bus_C = dataZ_Bus[x_bus_C][y_bus_C];
		W_Bus_C = dataW_Bus[x_bus_C][y_bus_C];
		M_Bus_C = dataM_Bus[x_bus_C][y_bus_C];
		N_Bus_C = dataN_Bus[x_bus_C][y_bus_C];
	end
	// Stop Scan
	if(x_bus_C > 9 || y_bus_C > 21) begin
		X_Bus_C = 0; Y_Bus_C = 0; Z_Bus_C = 0; W_Bus_C = 0;
		M_Bus_C = 0; N_Bus_C = 0;
	end
end
//----------------------------------------------------
// SCORE Output Setting
// Coordinate Locate in (416, 370)
// Scaling 2 times
reg [9:0]x_score_5, y_score_5, x_score_4, y_score_4, x_score_3, y_score_3, x_score_2, y_score_2, x_score_1, y_score_1, x_score_0, y_score_0;
reg [6:0]X_Score, Y_Score, Z_Score, W_Score, M_Score, N_Score;
always@(*)begin
	if(hor_counter > 415 && ver_counter > 369) begin
		x_score_5 = (hor_counter - 416)/2;
		y_score_5 = (ver_counter - 370)/2;
		X_Score = Number_Paint(mt, x_score_5, y_score_5);
		if(hor_counter > 425)begin
			x_score_4 = (hor_counter - 426)/2;
			y_score_4 = (ver_counter - 370)/2;
			Y_Score = Number_Paint(m, x_score_4, y_score_4);
			if(hor_counter > 435)begin
				x_score_3 = (hor_counter - 436)/2;
				y_score_3 = (ver_counter - 370)/2;
				Z_Score = Number_Paint(t, x_score_3, y_score_3);
				if(hor_counter > 445)begin
					x_score_2 = (hor_counter - 446)/2;
					y_score_2 = (ver_counter - 370)/2;
					W_Score = Number_Paint(h, x_score_2, y_score_2);
					if(hor_counter > 455)begin
						x_score_1 = (hor_counter - 456)/2;
						y_score_1 = (ver_counter - 370)/2;
						M_Score = Number_Paint(d, x_score_1, y_score_1);
						if(hor_counter > 465)begin
							x_score_0 = (hor_counter - 466)/2;
							y_score_0 = (ver_counter - 370)/2;
							N_Score = Number_Paint(b, x_score_0, y_score_0);
						end
					end
				end
			end
		end
	end
	// Stop Scan
	if(x_score_5 > 3 || y_score_5 > 6) X_Score = 0;
	if(x_score_4 > 3 || y_score_4 > 6) Y_Score = 0;
	if(x_score_3 > 3 || y_score_3 > 6) Z_Score = 0;
	if(x_score_2 > 3 || y_score_2 > 6) W_Score = 0;
	if(x_score_1 > 3 || y_score_1 > 6) M_Score = 0;
	if(x_score_0 > 3 || y_score_0 > 6) N_Score = 0;
end
//----------------------------------------------------
// BEST Output Setting
// Coordinate Locate in (416, 390)
// Scaling 2 times
reg [9:0]x_best_5, y_best_5, x_best_4, y_best_4, x_best_3, y_best_3, x_best_2, y_best_2, x_best_1, y_best_1, x_best_0, y_best_0;
reg [6:0]X_Best, Y_Best, Z_Best, W_Best, M_Best, N_Best;
always@(*)begin
	if(hor_counter > 415 && ver_counter > 389) begin
		x_best_5 = (hor_counter - 416)/2;
		y_best_5 = (ver_counter - 390)/2;
		X_Best = Number_Paint(b_mt, x_best_5, y_best_5);
		if(hor_counter > 425)begin
			x_best_4 = (hor_counter - 426)/2;
			y_best_4 = (ver_counter - 390)/2;
			Y_Best = Number_Paint(b_m, x_best_4, y_best_4);
			if(hor_counter > 435)begin
				x_best_3 = (hor_counter - 436)/2;
				y_best_3 = (ver_counter - 390)/2;
				Z_Best = Number_Paint(b_t, x_best_3, y_best_3);
				if(hor_counter > 445)begin
					x_best_2 = (hor_counter - 446)/2;
					y_best_2 = (ver_counter - 390)/2;
					W_Best = Number_Paint(b_h, x_best_2, y_best_2);
					if(hor_counter > 455)begin
						x_best_1 = (hor_counter - 456)/2;
						y_best_1 = (ver_counter - 390)/2;
						M_Best = Number_Paint(b_d, x_best_1, y_best_1);
						if(hor_counter > 465)begin
							x_best_0 = (hor_counter - 466)/2;
							y_best_0 = (ver_counter - 390)/2;
							N_Best = Number_Paint(b_b, x_best_0, y_best_0);
						end
					end
				end
			end
		end
	end
	// Stop Scan
	if(x_best_5 > 3 || y_best_5 > 6) X_Best = 0;
	if(x_best_4 > 3 || y_best_4 > 6) Y_Best = 0;
	if(x_best_3 > 3 || y_best_3 > 6) Z_Best = 0;
	if(x_best_2 > 3 || y_best_2 > 6) W_Best = 0;
	if(x_best_1 > 3 || y_best_1 > 6) M_Best = 0;
	if(x_best_0 > 3 || y_best_0 > 6) N_Best = 0;
end
//----------------------------------------------------
// SCORE Text Output Setting
// Coordinate Locate in (363, 370)
// Scaling 2 times
reg [9:0]x_score, y_score;
reg [6:0]Score_Text;
always@(*)begin
	if(hor_counter > 362 && ver_counter > 369) begin
		x_score = (hor_counter - 363)/2;
		y_score = (ver_counter - 370)/2;
		Score_Text = dataX_Score[x_score][y_score];
	end
	// Stop Scan
	if(x_score > 23 || y_score > 6) Score_Text = 0;
end
//----------------------------------------------------
// BEST Text Output Setting
// Coordinate Locate in (363, 390)
// Scaling 2 times
reg [9:0]x_best, y_best;
reg [6:0]Best_Text;
always@(*)begin
	if(hor_counter > 362 && ver_counter > 389) begin
		x_best = (hor_counter - 363)/2;
		y_best = (ver_counter - 390)/2;
		Best_Text = dataX_Best[x_best][y_best];
	end
	// Stop Scan
	if(x_best > 23 || y_best > 6) Best_Text = 0;
end
//----------------------------------------------------
// Timer Output Setting
// Coordinate Locate in (168, 370)
// Scaling 2 times
reg [9:0]x_time_m2, y_time_m2, x_time_m1, y_time_m1, x_time_s2, y_time_s2, x_time_s1, y_time_s1, x_dot, y_dot;
reg [6:0]M_Time_2, M_Time_1, S_Time_2, S_Time_1, X_Dot;
always@(*)begin
	if(hor_counter > 167 && ver_counter > 369) begin
		x_time_m2 = (hor_counter - 168)/2;
		y_time_m2 = (ver_counter - 370)/2;
		M_Time_2 = Number_Paint(m2, x_time_m2, y_time_m2);
		if(hor_counter > 177)begin
			x_time_m1 = (hor_counter - 178)/2;
			y_time_m1 = (ver_counter - 370)/2;
			M_Time_1 = Number_Paint(m1, x_time_m1, y_time_m1);
			if(hor_counter > 187)begin
				x_dot = (hor_counter - 188)/2;
				y_dot = (ver_counter - 370)/2;
				X_Dot = dataX_Dot[x_dot][y_dot];
				if(hor_counter > 197)begin
					x_time_s2 = (hor_counter - 198)/2;
					y_time_s2 = (ver_counter - 370)/2;
					S_Time_2 = Number_Paint(s2, x_time_s2, y_time_s2);
					if(hor_counter > 207)begin
						x_time_s1 = (hor_counter - 208)/2;
						y_time_s1 = (ver_counter - 370)/2;
						S_Time_1 = Number_Paint(s1, x_time_s1, y_time_s1);
					end
				end
			end
		end
	end
	// Stop Scan
	if(x_time_m2 > 3 || y_time_m2 > 6) M_Time_2 = 0;
	if(x_time_m1 > 3 || y_time_m1 > 6) M_Time_1 = 0;
	if(x_time_s2 > 3 || y_time_s2 > 6) S_Time_2 = 0;
	if(x_time_s1 > 3 || y_time_s1 > 6) S_Time_1 = 0;
	if(x_dot 	 > 3 || y_dot	   > 6) X_Dot	  = 0;
end
//----------------------------------------------------
// Coin in Road Output Setting
// Coordinate Locate in A(232, 291) B(332, 291) C(432, 291)
// Scaling 2 times
reg [9:0]x_coin_a, y_coin_a, x_coin_b, y_coin_b, x_coin_c, y_coin_c;
reg [11:0]X_Coin_A, Y_Coin_A, X_Coin_B, Y_Coin_B, X_Coin_C, Y_Coin_C;
reg [2:0]Coin_up = 3'b000;
always@(*)begin
	if(hor_counter > 231 && ver_counter > 290) begin
		x_coin_a = (hor_counter - 232)/2;
		y_coin_a = (ver_counter - 291)/2;
		X_Coin_A = dataX_Coin[x_coin_a][y_coin_a];
		Y_Coin_A = dataY_Coin[x_coin_a][y_coin_a];
		if(hor_counter > 331) begin
			x_coin_b = (hor_counter - 332)/2;
			y_coin_b = (ver_counter - 291)/2;
			X_Coin_B = dataX_Coin[x_coin_b][y_coin_b];
			Y_Coin_B = dataY_Coin[x_coin_b][y_coin_b];
			if(hor_counter > 431) begin
				x_coin_c = (hor_counter - 432)/2;
				y_coin_c = (ver_counter - 291)/2;
				X_Coin_C = dataX_Coin[x_coin_c][y_coin_c];
				Y_Coin_C = dataY_Coin[x_coin_c][y_coin_c];
			end
		end
	end
	// Stop Scan
	if(x_coin_a > 10 || y_coin_a > 11)begin 
		X_Coin_A = 0; Y_Coin_A = 0;
	end
	if(x_coin_b > 10 || y_coin_b > 11)begin 
		X_Coin_B = 0; Y_Coin_B = 0;
	end
	if(x_coin_c > 10 || y_coin_c > 11)begin 
		X_Coin_C = 0; Y_Coin_C = 0;
	end
end
//----------------------------------------------------
// Bomb in Road Output Setting
// Coordinate Locate in A(232, 291) B(332, 291) C(432, 291)
// Scaling 2 times
reg [9:0]x_bomb_a, y_bomb_a, x_bomb_b, y_bomb_b, x_bomb_c, y_bomb_c;
reg [11:0]X_Bomb_A, Y_Bomb_A, X_Bomb_B, Y_Bomb_B, X_Bomb_C, Y_Bomb_C;
reg [2:0]Bomb_down = 3'b000;
always@(*)begin
	if(hor_counter > 231 && ver_counter > 290) begin
		x_bomb_a = (hor_counter - 232)/2;
		y_bomb_a = (ver_counter - 291)/2;
		X_Bomb_A = dataX_Bomb[x_bomb_a][y_bomb_a];
		Y_Bomb_A = dataY_Bomb[x_bomb_a][y_bomb_a];
		if(hor_counter > 331) begin
			x_bomb_b = (hor_counter - 332)/2;
			y_bomb_b = (ver_counter - 291)/2;
			X_Bomb_B = dataX_Bomb[x_bomb_b][y_bomb_b];
			Y_Bomb_B = dataY_Bomb[x_bomb_b][y_bomb_b];
			if(hor_counter > 431) begin
				x_bomb_c = (hor_counter - 432)/2;
				y_bomb_c = (ver_counter - 291)/2;
				X_Bomb_C = dataX_Bomb[x_bomb_c][y_bomb_c];
				Y_Bomb_C = dataY_Bomb[x_bomb_c][y_bomb_c];
			end
		end
	end
	// Stop Scan
	if(x_bomb_a > 10 || y_bomb_a > 11)begin 
		X_Bomb_A = 0; Y_Bomb_A = 0;
	end
	if(x_bomb_b > 10 || y_bomb_b > 11)begin 
		X_Bomb_B = 0; Y_Bomb_B = 0;
	end
	if(x_bomb_c > 10 || y_bomb_c > 11)begin 
		X_Bomb_C = 0; Y_Bomb_C = 0;
	end
end
//----------------------------------------------------
// Blood in Road Output Setting
// Coordinate Locate in A(232, 291) B(332, 291) C(432, 291)
// Scaling 2 times
reg [9:0]x_blood_a, y_blood_a, x_blood_b, y_blood_b, x_blood_c, y_blood_c;
reg [11:0]X_Blood_A, Y_Blood_A, X_Blood_B, Y_Blood_B, X_Blood_C, Y_Blood_C;
reg [2:0]Blood_up = 3'b000;
always@(*)begin
	if(hor_counter > 231 && ver_counter > 290) begin
		x_blood_a = (hor_counter - 232)/2;
		y_blood_a = (ver_counter - 291)/2;
		X_Blood_A = dataX_Blood[x_blood_a][y_blood_a];
		Y_Blood_A = dataY_Blood[x_blood_a][y_blood_a];
		if(hor_counter > 331) begin
			x_blood_b = (hor_counter - 332)/2;
			y_blood_b = (ver_counter - 291)/2;
			X_Blood_B = dataX_Blood[x_blood_b][y_blood_b];
			Y_Blood_B = dataY_Blood[x_blood_b][y_blood_b];
			if(hor_counter > 431) begin
				x_blood_c = (hor_counter - 432)/2;
				y_blood_c = (ver_counter - 291)/2;
				X_Blood_C = dataX_Blood[x_blood_c][y_blood_c];
				Y_Blood_C = dataY_Blood[x_blood_c][y_blood_c];
			end
		end
	end
	// Stop Scan
	if(x_blood_a > 10 || y_blood_a > 11)begin 
		X_Blood_A = 0; Y_Blood_A = 0;
	end
	if(x_blood_b > 10 || y_blood_b > 11)begin 
		X_Blood_B = 0; Y_Blood_B = 0;
	end
	if(x_blood_c > 10 || y_blood_c > 11)begin 
		X_Blood_C = 0; Y_Blood_C = 0;
	end
end
//---------------------------------------------------- 
// GAME-OVER Output Setting
// Coordinate Locate in (246, 11)
// Scaling 1 times
reg [9:0]x_gg, y_gg;
reg [26:0]X_GG;
always@(*)begin
	if(hor_counter >245 && ver_counter > 10) begin
		x_gg = (hor_counter - 246)/3;
		y_gg = (ver_counter - 11)/3;
		X_GG = dataX_GG[x_gg][y_gg];
	end
	// Stop Scan
	if(x_gg > 44 || y_gg > 26) X_GG = 0;
end
//---------------------------------------------------- 
// Pa Output Setting
// Coordinate Locate in (168, 11)
// Scaling 3 times
reg [9:0]x_pa, y_pa;
reg [17:0]X_Pa, Y_Pa, Z_Pa, M_Pa, N_Pa;
always@(*)begin
	if(hor_counter > 167 && ver_counter > 10) begin
		x_pa = (hor_counter - 168)/3;
		y_pa = (ver_counter - 11)/3;
		X_Pa = dataX_Pa[x_pa][y_pa];
		Y_Pa = dataY_Pa[x_pa][y_pa];
		Z_Pa = dataZ_Pa[x_pa][y_pa];
		M_Pa = dataM_Pa[x_pa][y_pa];
		N_Pa = dataN_Pa[x_pa][y_pa];
	end
	// Stop Scan
	if(x_pa > 23 || y_pa > 17) begin
		X_Pa = 0; Y_Pa = 0; Z_Pa = 0;
		M_Pa = 0; N_Pa = 0;
	end
end
//---------------------------------------------------- 
// Blood Output Setting
// Coordinate Locate in (438, 101)
// Scaling 1 times
reg [2:0]State_Blood = 3'b111;
reg [9:0]x_blood_1, y_blood_1, x_blood_2, y_blood_2, x_blood_3, y_blood_3;
reg [11:0]X_Blood_1, Y_Blood_1, X_Blood_2, Y_Blood_2, X_Blood_3, Y_Blood_3;
always@(*)begin
	if(hor_counter > 437 && ver_counter > 100 && State_Blood[0] == 1) begin
		x_blood_1 = hor_counter - 438;
		y_blood_1 = ver_counter - 101;
		X_Blood_1 = dataX_Blood[x_blood_1][y_blood_1];
		Y_Blood_1 = dataY_Blood[x_blood_1][y_blood_1];
		if(hor_counter > 449 && State_Blood[0] == 1 && State_Blood[1] == 1) begin
			x_blood_2 = hor_counter - 450;
			y_blood_2 = ver_counter - 101;
			X_Blood_2 = dataX_Blood[x_blood_2][y_blood_2];
			Y_Blood_2 = dataY_Blood[x_blood_2][y_blood_2];
			if(hor_counter > 461 && State_Blood[0] == 1 && State_Blood[1] == 1 && State_Blood[2] == 1) begin
				x_blood_3 = hor_counter - 462;
				y_blood_3 = ver_counter - 101;
				X_Blood_3 = dataX_Blood[x_blood_3][y_blood_3];
				Y_Blood_3 = dataY_Blood[x_blood_3][y_blood_3];
			end
		end
	end
	// Stop Scan
	if(x_blood_1 > 10 || y_blood_1 > 11)begin 
		X_Blood_1 = 0; Y_Blood_1 = 0;
	end
	if(x_blood_2 > 10 || y_blood_2 > 11)begin 
		X_Blood_2 = 0; Y_Blood_2 = 0;
	end
	if(x_blood_3 > 10 || y_blood_3 > 11)begin
		X_Blood_3 = 0; Y_Blood_3 = 0;
	end
end
//---------------------------------------------------- 
// State Output SSetting
// Coordinate Locate in (168, 51)
// Scaling 2 times
reg [9:0]x_go, y_go, x_stop, y_stop;
reg [28:0]X_Go, Y_Go, X_Stop, Y_Stop;
always@(*)begin
	// "STOP" or "Go"
	if(!Stop) begin
		// Clear
		X_Go = 0; Y_Go = 0;
		// data
		if(hor_counter > 167 && ver_counter > 50) begin
			x_stop = (hor_counter - 168)/2;
			y_stop = (ver_counter - 51)/2;
			X_Stop = dataX_Stop[x_stop][y_stop];
			Y_Stop = dataY_Stop[x_stop][y_stop];
		end
	end else begin
		// Clear
		X_Stop = 0; Y_Stop = 0;
		// data
		if(hor_counter > 167 && ver_counter > 50) begin
			x_go = (hor_counter - 168)/2;
			y_go = (ver_counter - 51)/2;
			X_Go = dataX_Go[x_go][y_go];
			Y_Go = dataY_Go[x_go][y_go];
		end
	end
	// Stop Scan
	if(x_stop > 28 || y_stop > 28) begin
		X_Stop = 0; Y_Stop = 0;
	end
	if(x_go > 28 || y_go > 28) begin
		X_Go = 0;  Y_Go = 0;
	end
end
//---------------------------------------------------- 
// Road & Yellow-Line Output Setting
// Coordinate Locate in (168, 116)
// Scaling 5 times
// upper-left :(168, 116)
// lower-right:(472, 365)
reg [9:0]x_road, y_road, x_line, y_line;
reg [49:0]X_road, Y_road, Z_road;
reg [47:0]X_line, Y_line, Z_line;
always@(*)begin
	// Road
	if(hor_counter > 167 && ver_counter > 115) begin
		x_road = (hor_counter - 168)/5;
		y_road = (ver_counter - 116)/5;
		X_road = dataX_Road[x_road][y_road];
		Y_road = dataY_Road[x_road][y_road];
		Z_road = dataZ_Road[x_road][y_road];
	end
	// Stop Scan
	if(x_road > 60 || y_road > 49) begin
		X_road = 0; Y_road = 0; Z_road = 0;
	end
	// Yellow Line
	if(hor_counter > 217 && ver_counter > 120) begin
		x_line = (hor_counter - 218)/5;
		y_line = (ver_counter - 121)/5;
		X_line = dataX_Line[y_line];
		if(hor_counter > 317) begin
			x_line = (hor_counter - 318)/5;
			y_line = (ver_counter - 121)/5;
			Y_line = dataX_Line[y_line];
			if(hor_counter > 417) begin
				x_line = (hor_counter - 418)/5;
				y_line = (ver_counter - 121)/5;
				Z_line = dataX_Line[y_line];
			end
		end
	end
	// Stop Scan
	if(x_line > 0 || y_line > 47) begin
		X_line = 0; Y_line = 0; Z_line = 0;
	end
end
//---------------------------------------------------- 
// RGB Output Color
always@(*)begin
	// Car Color-------------------------
		  if(X_Car && State_Blood != 3'b000) RGB = 24'h000000;
	else if(Y_Car && State_Blood != 3'b000) RGB = 24'h808080;
	else if(Z_Car && State_Blood != 3'b000) RGB = 24'hD9D9D9;
	else if(W_Car && State_Blood != 3'b000) RGB = 24'hAEAAAA;
	else if(M_Car && State_Blood != 3'b000) RGB = 24'hFFFF00;
	else if(N_Car && State_Blood != 3'b000) RGB = 24'hFF0000;
	else if(O_Car && State_Blood != 3'b000) RGB = 24'hFFC000;
	// Blood Color-----------------------
	else if(X_Blood_1 || X_Blood_2 || X_Blood_3) 
		RGB = 24'hFF0000;
	else if(Y_Blood_1 || Y_Blood_2 || Y_Blood_3) 
		RGB = 24'hFFFFFF;	
	// State Color-----------------------
	else if(X_Go && State_Blood != 3'b000) 
		RGB = 24'h00DD00;
	else if(X_Stop && State_Blood != 3'b000) 
		RGB = 24'hFF0000;
	else if(Y_Go && State_Blood != 3'b000) 
		RGB = 24'hFFFFFF;
	else if(Y_Stop && State_Blood != 3'b000) 
		RGB = 24'hFFFFFF;
	// GAMEOVER Color--------------------
	else if(X_GG && State_Blood == 3'b000) 
		RGB = 24'hFF0000;
	// Pa Color--------------------------
	else if(X_Pa && State_Blood == 3'b000) RGB = 24'h000000;
	else if(Y_Pa && State_Blood == 3'b000) RGB = 24'h833C0C;
	else if(Z_Pa && State_Blood == 3'b000) RGB = 24'hFFFFFF;
	else if(M_Pa && State_Blood == 3'b000) RGB = 24'hD9D9D9;
	else if(N_Pa && State_Blood == 3'b000) RGB = 24'hBFBFBF;
	// Time Color -----------------------
	else if(M_Time_2 || M_Time_1 || S_Time_2 || S_Time_1 || X_Dot)
		if(!Scene_State) RGB = 24'h000000;
		else RGB = 24'hFFFFFF;
	// SCORE Text Color -----------------
	else if(Score_Text)begin
		if(!Scene_State) RGB = 24'h000000;
		else RGB = 24'hFFFFFF;
	end
	// BEST Text Color -----------------
	else if(Best_Text)begin
		if(!Scene_State) RGB = 24'h000000;
		else RGB = 24'hFFFFFF;
	end
	// SCORE Color ----------------------
	else if(X_Score || Y_Score || Z_Score || W_Score || M_Score || N_Score) 
		RGB = 24'hFF0000;
	// BEST Color ----------------------
	else if(X_Best || Y_Best || Z_Best || W_Best || M_Best || N_Best) 
		RGB = 24'hFFFF00;
	// Background Color
	else if(hor_counter > 167 && hor_counter < 473 && 
			  ver_counter >   0 && ver_counter < 116 ||
			  hor_counter > 167 && hor_counter < 473 && 
			  ver_counter > 365 && ver_counter < 480)begin
		if(!Scene_State) RGB = 24'hCCCCCC;
		else RGB = 24'h555555;
	end
	// Coin Color in Road---------------
	else if(X_Coin_A && Coin_up[2]) RGB = 24'hFFFF00;
	else if(Y_Coin_A && Coin_up[2]) RGB = 24'hC9C400;
	else if(X_Coin_B && Coin_up[1]) RGB = 24'hFFFF00;
	else if(Y_Coin_B && Coin_up[1]) RGB = 24'hC9C400;
	else if(X_Coin_C && Coin_up[0]) RGB = 24'hFFFF00;
	else if(Y_Coin_C && Coin_up[0]) RGB = 24'hC9C400;
	// Bomb Color in Road---------------
	else if(X_Bomb_A && Bomb_down[2]) RGB = 24'h000000;
	else if(Y_Bomb_A && Bomb_down[2]) RGB = 24'hFFFFFF;
	else if(X_Bomb_B && Bomb_down[1]) RGB = 24'h000000;
	else if(Y_Bomb_B && Bomb_down[1]) RGB = 24'hFFFFFF;
	else if(X_Bomb_C && Bomb_down[0]) RGB = 24'h000000;
	else if(Y_Bomb_C && Bomb_down[0]) RGB = 24'hFFFFFF;
	// Blood Color in Road---------------
	else if(X_Blood_A && Blood_up[2]) RGB = 24'hFF0000;
	else if(Y_Blood_A && Blood_up[2]) RGB = 24'hFFFFFF;
	else if(X_Blood_B && Blood_up[1]) RGB = 24'hFF0000;
	else if(Y_Blood_B && Blood_up[1]) RGB = 24'hFFFFFF;
	else if(X_Blood_C && Blood_up[0]) RGB = 24'hFF0000;
	else if(Y_Blood_C && Blood_up[0]) RGB = 24'hFFFFFF;
	// Bus Color-------------------------
	else if(X_Bus_A || X_Bus_B || X_Bus_C) RGB = 24'h000000;
	else if(Y_Bus_A || Y_Bus_B || Y_Bus_C) RGB = 24'h808080;
	else if(Z_Bus_A || Z_Bus_B || Z_Bus_C) RGB = 24'hD9D9D9;
	else if(W_Bus_A || W_Bus_B || W_Bus_C) RGB = 24'h203764;
	else if(M_Bus_A || M_Bus_B || M_Bus_C) RGB = 24'h4472C4;
	else if(N_Bus_A || N_Bus_B || N_Bus_C) RGB = 24'hFFFF00;
	// Barrier Color------------------------
	else if(X_Barr_A || X_Barr_B || X_Barr_C)begin
		if(!Scene_State) RGB = 24'h000000;
		else RGB = 24'hC65911;
	end
	else if(Y_Barr_A || Y_Barr_B || Y_Barr_C)begin
		if(!Scene_State) RGB = 24'h000000;
		else RGB = 24'h833C0C;
	end
	// Yellow Line Color-----------------
	else if(X_line || Y_line || Z_line)begin
		if(!Scene_State) RGB = 24'hFFFF00;
		else RGB = 24'hC9C400;
	end
	// Road Color------------------------
	else if(X_road) RGB = 24'h000000;
	else if(Y_road)begin
		if(!Scene_State) RGB = 24'hA6A6A6;
		else RGB = 24'h3A3838;
	end
	else if(Z_road)begin
		if(!Scene_State) RGB = 24'hD0CECE;
		else RGB = 24'h757171;
	end
	// Other Color------------------
	else begin
		if(!Scene_State) RGB = 24'hCCCCCC;
		else RGB = 24'h555555;
	end
end
//---------------------------------------------------- Graph SQL
// BEST
reg [6:0]dataX_Best[0:23];
always@(*)begin
	// BEST
	dataX_Best[0]  = 7'b1111111;
	dataX_Best[1]  = 7'b1001001;
	dataX_Best[2]  = 7'b1001001;
	dataX_Best[3]  = 7'b0110110;
	dataX_Best[4]  = 7'b0000000;
	dataX_Best[5]  = 7'b0000000;
	dataX_Best[6]  = 7'b1111111;
	dataX_Best[7]  = 7'b1001001;
	dataX_Best[8]  = 7'b1001001;
	dataX_Best[9]  = 7'b1000001;
	dataX_Best[10] = 7'b0000000;
	dataX_Best[11] = 7'b0000000;
	dataX_Best[12] = 7'b0100110;
	dataX_Best[13] = 7'b1001001;
	dataX_Best[14] = 7'b1001001;
	dataX_Best[15] = 7'b0110010;
	dataX_Best[16] = 7'b0000000;
	dataX_Best[17] = 7'b0000000;
	dataX_Best[18] = 7'b0000001;
	dataX_Best[19] = 7'b0000001;
	dataX_Best[20] = 7'b1111111;
	dataX_Best[21] = 7'b0000001;
	dataX_Best[22] = 7'b0000001;
	dataX_Best[23] = 7'b0000000;
end
// SCORE
reg [6:0]dataX_Score[0:23];
always@(*)begin
	// SCORE
	dataX_Score[0]  = 7'b0100110;
	dataX_Score[1]  = 7'b1001001;
	dataX_Score[2]  = 7'b1001001;
	dataX_Score[3]  = 7'b0110010;
	dataX_Score[4]  = 7'b0000000;
	dataX_Score[5]  = 7'b0111110;
	dataX_Score[6]  = 7'b1000001;
	dataX_Score[7]  = 7'b1000001;
	dataX_Score[8]  = 7'b0100010;
	dataX_Score[9]  = 7'b0000000;
	dataX_Score[10] = 7'b0111110;
	dataX_Score[11] = 7'b1000001;
	dataX_Score[12] = 7'b1000001;
	dataX_Score[13] = 7'b0111110;
	dataX_Score[14] = 7'b0000000;
	dataX_Score[15] = 7'b1111111;
	dataX_Score[16] = 7'b0011001;
	dataX_Score[17] = 7'b0101001;
	dataX_Score[18] = 7'b1000110;
	dataX_Score[19] = 7'b0000000;
	dataX_Score[20] = 7'b1111111;
	dataX_Score[21] = 7'b1001001;
	dataX_Score[22] = 7'b1001001;
	dataX_Score[23] = 7'b1000001;
end
// Number 0 ~ 9 and Dot
reg [6:0]dataX_Dot[0:3], dataX_Zero[0:3], dataX_One[0:3], dataX_Two[0:3], dataX_Three[0:3], dataX_Four[0:3], dataX_Five[0:3], dataX_Six[0:3], dataX_Seven[0:3], dataX_Eight[0:3], dataX_Nine[0:3];
always@(*)begin
	// dot
	dataX_Dot[0] = 7'b0000000;
	dataX_Dot[1] = 7'b0110110;
	dataX_Dot[2] = 7'b0110110;
	dataX_Dot[3] = 7'b0000000;
	// 0
	dataX_Zero[0] = 7'b0111110;
	dataX_Zero[1] = 7'b1000001;
	dataX_Zero[2] = 7'b1000001;
	dataX_Zero[3] = 7'b0111110;
	// 1
	dataX_One[0] = 7'b0000000;
	dataX_One[1] = 7'b1000001;
	dataX_One[2] = 7'b1111111;
	dataX_One[3] = 7'b1000000;
	// 2
	dataX_Two[0] = 7'b1100010;
	dataX_Two[1] = 7'b1010001;
	dataX_Two[2] = 7'b1001001;
	dataX_Two[3] = 7'b1000110;
	// 3
	dataX_Three[0] = 7'b0100010;
	dataX_Three[1] = 7'b1001001;
	dataX_Three[2] = 7'b1001001;
	dataX_Three[3] = 7'b0110110;
	// 4
	dataX_Four[0] = 7'b0011000;
	dataX_Four[1] = 7'b0010100;
	dataX_Four[2] = 7'b0010010;
	dataX_Four[3] = 7'b1111111;
	// 5
	dataX_Five[0] = 7'b1001111;
	dataX_Five[1] = 7'b1001001;
	dataX_Five[2] = 7'b1001001;
	dataX_Five[3] = 7'b0110001;
	// 6
	dataX_Six[0] = 7'b0111110;
	dataX_Six[1] = 7'b1001001;
	dataX_Six[2] = 7'b1001001;
	dataX_Six[3] = 7'b0110010;
	// 7
	dataX_Seven[0] = 7'b0000011;
	dataX_Seven[1] = 7'b1110001;
	dataX_Seven[2] = 7'b0001001;
	dataX_Seven[3] = 7'b0000111;
	//8
	dataX_Eight[0] = 7'b0110110;
	dataX_Eight[1] = 7'b1001001;
	dataX_Eight[2] = 7'b1001001;
	dataX_Eight[3] = 7'b0110110;
	// 9
	dataX_Nine[0] = 7'b0101110;
	dataX_Nine[1] = 7'b1001001;
	dataX_Nine[2] = 7'b1001001;
	dataX_Nine[3] = 7'b0111110;
end
// BUS
reg [21:0]dataX_Bus[0:9], dataY_Bus[0:9], dataZ_Bus[0:9], dataW_Bus[0:9], dataM_Bus[0:9], dataN_Bus[0:9];
always@(*)begin
	// #000000 輪胎
	dataX_Bus[0] = 22'b0000111100000001111000;
	dataX_Bus[1] = 22'b0000000000000000000000;
	dataX_Bus[2] = 22'b0000000000000000000000;
	dataX_Bus[3] = 22'b0000000000000000000000;
	dataX_Bus[4] = 22'b0000000000000000000000;
	dataX_Bus[5] = 22'b0000000000000000000000;
	dataX_Bus[6] = 22'b0000000000000000000000;
	dataX_Bus[7] = 22'b0000000000000000000000;
	dataX_Bus[8] = 22'b0000000000000000000000;
	dataX_Bus[9] = 22'b0000111100000001111000;
	// #808080 車頭外殼
	dataY_Bus[0] = 22'b0000000000000000000000;
	dataY_Bus[1] = 22'b1111110000000000000000;
	dataY_Bus[2] = 22'b0100010000000000000000;
	dataY_Bus[3] = 22'b0100010000000000000000;
	dataY_Bus[4] = 22'b1100010000000000000000;
	dataY_Bus[5] = 22'b1100010000000000000000;
	dataY_Bus[6] = 22'b0100010000000000000000;
	dataY_Bus[7] = 22'b0100010000000000000000;
	dataY_Bus[8] = 22'b1111110000000000000000;
	dataY_Bus[9] = 22'b0000000000000000000000;
	// #D9D9D9 玻璃
	dataZ_Bus[0] = 22'b0000000000000000000000;
	dataZ_Bus[1] = 22'b0000000000000000000000;
	dataZ_Bus[2] = 22'b0011100000000000000000;
	dataZ_Bus[3] = 22'b0011100000000000000000;
	dataZ_Bus[4] = 22'b0011100000000000000000;
	dataZ_Bus[5] = 22'b0011100000000000000000;
	dataZ_Bus[6] = 22'b0011100000000000000000;
	dataZ_Bus[7] = 22'b0011100000000000000000;
	dataZ_Bus[8] = 22'b0000000000000000000000;
	dataZ_Bus[9] = 22'b0000000000000000000000;
	// #203764 箱子外殼
	dataW_Bus[0] = 22'b0000000000000000000000;
	dataW_Bus[1] = 22'b0000001111111111111110;
	dataW_Bus[2] = 22'b0000001010101010101010;
	dataW_Bus[3] = 22'b0000001010101010101010;
	dataW_Bus[4] = 22'b0000001010101010101010;
	dataW_Bus[5] = 22'b0000001010101010101010;
	dataW_Bus[6] = 22'b0000001010101010101010;
	dataW_Bus[7] = 22'b0000001010101010101010;
	dataW_Bus[8] = 22'b0000001111111111111110;
	dataW_Bus[9] = 22'b0000000000000000000000;
	// #4472C4 箱子內殼
	dataM_Bus[0] = 22'b0000000000000000000000;
	dataM_Bus[1] = 22'b0000000000000000000000;
	dataM_Bus[2] = 22'b0000000101010101010100;
	dataM_Bus[3] = 22'b0000000101010101010100;
	dataM_Bus[4] = 22'b0000000101010101010100;
	dataM_Bus[5] = 22'b0000000101010101010100;
	dataM_Bus[6] = 22'b0000000101010101010100;
	dataM_Bus[7] = 22'b0000000101010101010100;
	dataM_Bus[8] = 22'b0000000000000000000000;
	dataM_Bus[9] = 22'b0000000000000000000000;
	// #FFFF00 車燈
	dataN_Bus[0] = 22'b0000000000000000000000;
	dataN_Bus[1] = 22'b0000000000000000000000;
	dataN_Bus[2] = 22'b1000000000000000000000;
	dataN_Bus[3] = 22'b1000000000000000000000;
	dataN_Bus[4] = 22'b0000000000000000000000;
	dataN_Bus[5] = 22'b0000000000000000000000;
	dataN_Bus[6] = 22'b1000000000000000000000;
	dataN_Bus[7] = 22'b1000000000000000000000;
	dataN_Bus[8] = 22'b0000000000000000000000;
	dataN_Bus[9] = 22'b0000000000000000000000;
end
// GO
reg [28:0]dataX_Go[0:28], dataY_Go[0:28];
always@(*)begin
	// green
	dataX_Go[0]  = 29'b00000000111111111111100000000;
	dataX_Go[1]  = 29'b00000001100000000000110000000;
	dataX_Go[2]  = 29'b00000011001111111110011000000;
	dataX_Go[3]  = 29'b00000110011111111111001100000;
	dataX_Go[4]  = 29'b00001100111111111111100110000;
	dataX_Go[5]  = 29'b00011001111100000011110011000;
	dataX_Go[6]  = 29'b00110011111000000001111001100;
	dataX_Go[7]  = 29'b01100111110011111100111100110;
	dataX_Go[8]  = 29'b11001111100111111110011110011;
	dataX_Go[9]  = 29'b10011111100110011110011111001;
	dataX_Go[10] = 29'b10111111100110011110011111101;
	dataX_Go[11] = 29'b10111111100110011110011111101;
	dataX_Go[12] = 29'b10111111110010011100111111101;
	dataX_Go[13] = 29'b10111111111000011101111111101;
	dataX_Go[14] = 29'b10111111111111111111111111101;
	dataX_Go[15] = 29'b10111111111100000011111111101;
	dataX_Go[16] = 29'b10111111111000000001111111101;
	dataX_Go[17] = 29'b10111111110011111100111111101;
	dataX_Go[18] = 29'b10111111100111111110011111101;
	dataX_Go[19] = 29'b10011111100111111110011111001;
	dataX_Go[20] = 29'b11001111100111111110011110011;
	dataX_Go[21] = 29'b01100111100111111110011100110;
	dataX_Go[22] = 29'b00110011110011111100111001100;
	dataX_Go[23] = 29'b00011001111000000001110011000;
	dataX_Go[24] = 29'b00001100111100000011100110000;
	dataX_Go[25] = 29'b00000110011111111111001100000;
	dataX_Go[26] = 29'b00000011001111111110011000000;
	dataX_Go[27] = 29'b00000001100000000000110000000;
	dataX_Go[28] = 29'b00000000111111111111100000000;
	// white
	dataY_Go[0]  = 29'b00000000000000000000000000000;
	dataY_Go[1]  = 29'b00000000011111111111000000000;
	dataY_Go[2]  = 29'b00000000110000000001100000000;
	dataY_Go[3]  = 29'b00000001100000000000110000000;
	dataY_Go[4]  = 29'b00000011000000000000011000000;
	dataY_Go[5]  = 29'b00000110000011111100001100000;
	dataY_Go[6]  = 29'b00001100000111111110000110000;
	dataY_Go[7]  = 29'b00011000001100000011000011000;
	dataY_Go[8]  = 29'b00110000011000000001100001100;
	dataY_Go[9]  = 29'b01100000011001100001100000110;
	dataY_Go[10] = 29'b01000000011001100001100000010;
	dataY_Go[11] = 29'b01000000011001100001100000010;
	dataY_Go[12] = 29'b01000000001101100011000000010;
	dataY_Go[13] = 29'b01000000000111100010000000010;
	dataY_Go[14] = 29'b01000000000000000000000000010;
	dataY_Go[15] = 29'b01000000000011111100000000010;
	dataY_Go[16] = 29'b01000000000111111110000000010;
	dataY_Go[17] = 29'b01000000001100000011000000010;
	dataY_Go[18] = 29'b01000000011000000001100000010;
	dataY_Go[19] = 29'b01100000011000000001100000110;
	dataY_Go[20] = 29'b00110000011000000001100001100;
	dataY_Go[21] = 29'b00011000011000000001100011000;
	dataY_Go[22] = 29'b00001100001100000011000110000;
	dataY_Go[23] = 29'b00000110000111111110001100000;
	dataY_Go[24] = 29'b00000011000011111100011000000;
	dataY_Go[25] = 29'b00000001100000000000110000000;
	dataY_Go[26] = 29'b00000000110000000001100000000;
	dataY_Go[27] = 29'b00000000011111111111000000000;
	dataY_Go[28] = 29'b00000000000000000000000000000;
end 
// STOP
reg [54:0]dataX_Stop[0:28], dataY_Stop[0:28]; 
always@(*)begin
	// red
	dataX_Stop[0]  = 29'b00000000111111111111100000000;
	dataX_Stop[1]  = 29'b00000001100000000000110000000;
	dataX_Stop[2]  = 29'b00000011001111111110011000000;
	dataX_Stop[3]  = 29'b00000110011101100111001100000;
	dataX_Stop[4]  = 29'b00001100111011011011100110000;
	dataX_Stop[5]  = 29'b00011001111011011011110011000;
	dataX_Stop[6]  = 29'b00110011111011011011111001100;
	dataX_Stop[7]  = 29'b01100111111100110111111100110;
	dataX_Stop[8]  = 29'b11001111111111111111111110011;
	dataX_Stop[9]  = 29'b10011111111111111011111111001;
	dataX_Stop[10] = 29'b10111111111111111011111111101;
	dataX_Stop[11] = 29'b10111111111000000011111111101;
	dataX_Stop[12] = 29'b10111111111111111011111111101;
	dataX_Stop[13] = 29'b10111111111111111011111111101;
	dataX_Stop[14] = 29'b10111111111111111111111111101;
	dataX_Stop[15] = 29'b10111111111100000111111111101;
	dataX_Stop[16] = 29'b10111111111011111011111111101;
	dataX_Stop[17] = 29'b10111111111011111011111111101;
	dataX_Stop[18] = 29'b10111111111011111011111111101;
	dataX_Stop[19] = 29'b10011111111100000111111111001;
	dataX_Stop[20] = 29'b11001111111111111111111110011;
	dataX_Stop[21] = 29'b01100111111000000011111100110;
	dataX_Stop[22] = 29'b00110011111111011011111001100;
	dataX_Stop[23] = 29'b00011001111111011011110011000;
	dataX_Stop[24] = 29'b00001100111111011011100110000;
	dataX_Stop[25] = 29'b00000110011111100111001100000;
	dataX_Stop[26] = 29'b00000011001111111110011000000;
	dataX_Stop[27] = 29'b00000001100000000000110000000;
	dataX_Stop[28] = 29'b00000000111111111111100000000;
	// white
	dataY_Stop[0]  = 29'b00000000000000000000000000000;
	dataY_Stop[1]  = 29'b00000000011111111111000000000;
	dataY_Stop[2]  = 29'b00000000110000000001100000000;
	dataY_Stop[3]  = 29'b00000001100010011000110000000;
	dataY_Stop[4]  = 29'b00000011000100100100011000000;
	dataY_Stop[5]  = 29'b00000110000100100100001100000;
	dataY_Stop[6]  = 29'b00001100000100100100000110000;
	dataY_Stop[7]  = 29'b00011000000011001000000011000;
	dataY_Stop[8]  = 29'b00110000000000000000000001100;
	dataY_Stop[9]  = 29'b01100000000000000100000000110;
	dataY_Stop[10] = 29'b01000000000000000100000000010;
	dataY_Stop[11] = 29'b01000000000111111100000000010;
	dataY_Stop[12] = 29'b01000000000000000100000000010;
	dataY_Stop[13] = 29'b01000000000000000100000000010;
	dataY_Stop[14] = 29'b01000000000000000000000000010;
	dataY_Stop[15] = 29'b01000000000011111000000000010;
	dataY_Stop[16] = 29'b01000000000100000100000000010;
	dataY_Stop[17] = 29'b01000000000100000100000000010;
	dataY_Stop[18] = 29'b01000000000100000100000000010;
	dataY_Stop[19] = 29'b01100000000011111000000000110;
	dataY_Stop[20] = 29'b00110000000000000000000001100;
	dataY_Stop[21] = 29'b00011000000111111100000011000;
	dataY_Stop[22] = 29'b00001100000000100100000110000;
	dataY_Stop[23] = 29'b00000110000000100100001100000;
	dataY_Stop[24] = 29'b00000011000000100100011000000;
	dataY_Stop[25] = 29'b00000001100000011000110000000;
	dataY_Stop[26] = 29'b00000000110000000001100000000;
	dataY_Stop[27] = 29'b00000000011111111111000000000;
	dataY_Stop[28] = 29'b00000000000000000000000000000;

end 
// GAMEOVER
reg [26:0]dataX_GG[0:44];
always@(*)begin
	dataX_GG[0]  = 27'b000_0000_0000_0000_0000_1110_0000;
	dataX_GG[1]  = 27'b000_0000_0000_0000_0011_1111_1000;
	dataX_GG[2]  = 27'b000_0000_0000_0000_0110_0000_1100;
	dataX_GG[3]  = 27'b000_0000_0000_0000_1100_0000_0110;
	dataX_GG[4]  = 27'b000_0011_1000_0001_1000_0000_0011;
	dataX_GG[5]  = 27'b000_1111_1110_0001_1000_0000_0011;
	dataX_GG[6]  = 27'b001_1000_0011_0001_1000_1100_0011;
	dataX_GG[7]  = 27'b011_0000_0001_1000_1100_0100_0000;
	dataX_GG[8]  = 27'b110_0000_0000_1100_0110_0100_0000;
	dataX_GG[9]  = 27'b110_0000_0000_1101_0011_0100_0000;
	dataX_GG[10] = 27'b110_0000_0000_1101_1111_1100_0000;
	dataX_GG[11] = 27'b011_0000_0001_1000_0000_0000_0000;
	dataX_GG[12] = 27'b001_1000_0011_0001_1111_1000_0000;
	dataX_GG[13] = 27'b000_1111_1110_0001_0011_1110_0000;
	dataX_GG[14] = 27'b000_0011_1000_0000_0010_0011_1000;
	dataX_GG[15] = 27'b000_0000_0000_0000_0010_0000_1110;
	dataX_GG[16] = 27'b000_0000_1111_1100_0010_0000_0111;
	dataX_GG[17] = 27'b000_0011_1110_0100_0010_0000_1110;
	dataX_GG[18] = 27'b000_1110_0000_0000_0010_0011_1000;
	dataX_GG[19] = 27'b011_1000_0000_0001_0011_1110_0000;
	dataX_GG[20] = 27'b111_0000_0000_0001_1111_1000_0000;
	dataX_GG[21] = 27'b011_1000_0000_0000_0000_0000_0000;
	dataX_GG[22] = 27'b000_1110_0000_0001_1111_1111_1111;
	dataX_GG[23] = 27'b000_0011_1110_0101_0000_0000_1100;
	dataX_GG[24] = 27'b000_0000_1111_1100_0000_0011_1000;
	dataX_GG[25] = 27'b000_0000_0000_0000_0000_0110_0000;
	dataX_GG[26] = 27'b111_1111_1111_1100_0000_1100_0000;
	dataX_GG[27] = 27'b110_0001_0000_1100_0000_0110_0000;
	dataX_GG[28] = 27'b100_0001_0000_0100_0000_0011_1000;
	dataX_GG[29] = 27'b100_0001_0000_0101_0000_0000_1100;
	dataX_GG[30] = 27'b100_0001_0000_0101_1111_1111_1111;
	dataX_GG[31] = 27'b100_0001_0000_0100_0000_0000_0000;
	dataX_GG[32] = 27'b100_0001_0000_0101_1111_1111_1111;
	dataX_GG[33] = 27'b101_0001_0001_0101_1000_0100_0011;
	dataX_GG[34] = 27'b111_0001_0001_1101_0000_0100_0001;
	dataX_GG[35] = 27'b000_0000_0000_0001_0000_0100_0001;
	dataX_GG[36] = 27'b111_1111_1111_1101_0000_0100_0001;
	dataX_GG[37] = 27'b000_1111_1001_1101_0000_0100_0001;
	dataX_GG[38] = 27'b001_1011_0000_1101_0000_0100_0001;
	dataX_GG[39] = 27'b011_0011_0000_1101_0100_0100_0101;
	dataX_GG[40] = 27'b110_0011_0000_1101_1100_0100_0111;
	dataX_GG[41] = 27'b100_0011_0000_1100_0000_0000_0000;
	dataX_GG[42] = 27'b100_0001_1001_1000_0000_0000_0000;
	dataX_GG[43] = 27'b101_0000_1111_0000_0000_0000_0000;
	dataX_GG[44] = 27'b111_0000_0110_0000_0000_0000_0000;
end	
// 啪!
reg [17:0]dataX_Pa[0:23], dataY_Pa[0:23], dataZ_Pa[0:23], dataM_Pa[0:23], dataN_Pa[0:23];
always@(*)begin
	// #000000 啪、眼睛
	dataX_Pa[0]  = 18'b00_0000_0000_0011_1000;
	dataX_Pa[1]  = 18'b00_0000_0000_0010_1000;
	dataX_Pa[2]  = 18'b00_0000_0000_0011_1000;
	dataX_Pa[3]  = 18'b00_0000_0000_0000_0000;
	dataX_Pa[4]  = 18'b00_0000_0010_0100_0100;
	dataX_Pa[5]  = 18'b00_0000_0011_1111_1111;
	dataX_Pa[6]  = 18'b00_0000_0000_0010_0100;
	dataX_Pa[7]  = 18'b00_0000_0000_0000_0000;
	dataX_Pa[8]  = 18'b00_0000_0011_1111_1100;
	dataX_Pa[9]  = 18'b00_0000_0010_0100_1010;
	dataX_Pa[10] = 18'b00_0000_0010_0100_1001;
	dataX_Pa[11] = 18'b00_0000_0011_1111_1000;
	dataX_Pa[12] = 18'b00_0000_0000_0000_0000;
	dataX_Pa[13] = 18'b00_0000_0000_0000_0000;
	dataX_Pa[14] = 18'b00_0000_0000_0001_0000;
	dataX_Pa[15] = 18'b00_0000_0000_0100_0000;
	dataX_Pa[16] = 18'b00_0000_0000_0000_0000;
	dataX_Pa[17] = 18'b00_0000_0000_0001_0000;
	dataX_Pa[18] = 18'b00_0000_0000_0000_0000;
	dataX_Pa[19] = 18'b00_0000_0000_0000_0000;
	dataX_Pa[20] = 18'b00_0000_0000_0000_0000;
	dataX_Pa[21] = 18'b00_0000_0000_0000_0000;
	dataX_Pa[22] = 18'b00_0000_0000_0000_0000;
	dataX_Pa[23] = 18'b00_0000_0000_0000_0000;
	// #833C0C 背景
	dataY_Pa[0]  = 18'b11_1111_1111_1100_0111;
	dataY_Pa[1]  = 18'b11_1111_1111_1101_0111;
	dataY_Pa[2]  = 18'b11_1111_1111_1100_0111;
	dataY_Pa[3]  = 18'b11_1111_1111_1111_1111;
	dataY_Pa[4]  = 18'b11_1011_1101_1011_1011;
	dataY_Pa[5]  = 18'b11_1001_1100_0000_0000;
	dataY_Pa[6]  = 18'b11_1001_1111_1101_1011;
	dataY_Pa[7]  = 18'b11_1001_1111_1111_1111;
	dataY_Pa[8]  = 18'b11_1001_1100_0000_0011;
	dataY_Pa[9]  = 18'b11_0000_1101_1011_0101;
	dataY_Pa[10] = 18'b01_0000_1101_1011_0110;
	dataY_Pa[11] = 18'b01_0000_0100_0000_0111;
	dataY_Pa[12] = 18'b00_0000_0001_1111_1111;
	dataY_Pa[13] = 18'b00_0000_0001_1000_0011;
	dataY_Pa[14] = 18'b00_0000_0000_0000_0001;
	dataY_Pa[15] = 18'b00_0000_0000_0000_0001;
	dataY_Pa[16] = 18'b00_0000_0000_0000_0001;
	dataY_Pa[17] = 18'b00_0000_0000_0000_0001;
	dataY_Pa[18] = 18'b00_0000_0000_0000_0011;
	dataY_Pa[19] = 18'b00_0000_0000_0000_0111;
	dataY_Pa[20] = 18'b00_0000_0001_1111_1111;
	dataY_Pa[21] = 18'b00_0000_0011_1111_1111;
	dataY_Pa[22] = 18'b00_0000_1111_1111_1111;
	dataY_Pa[23] = 18'b11_1111_1111_1111_1111;
	// #FFFFFF 身體
	dataZ_Pa[0]  = 18'b00_0000_0000_0000_0000;
	dataZ_Pa[1]  = 18'b00_0000_0000_0000_0000;
	dataZ_Pa[2]  = 18'b00_0000_0000_0000_0000;
	dataZ_Pa[3]  = 18'b00_0000_0000_0000_0000;
	dataZ_Pa[4]  = 18'b00_0100_0000_0000_0000;
	dataZ_Pa[5]  = 18'b00_0110_0000_0000_0000;
	dataZ_Pa[6]  = 18'b00_0110_0000_0000_0000;
	dataZ_Pa[7]  = 18'b00_0110_0000_0000_0000;
	dataZ_Pa[8]  = 18'b00_0110_0000_0000_0000;
	dataZ_Pa[9]  = 18'b00_1111_0000_0000_0000;
	dataZ_Pa[10] = 18'b10_1111_0000_0000_0000;
	dataZ_Pa[11] = 18'b10_1111_1000_0000_0000;
	dataZ_Pa[12] = 18'b11_1111_1110_0000_0000;
	dataZ_Pa[13] = 18'b10_1111_1110_0000_1100;
	dataZ_Pa[14] = 18'b10_0111_1111_1110_0110;
	dataZ_Pa[15] = 18'b10_0011_1111_0001_0110;
	dataZ_Pa[16] = 18'b11_0001_1111_0000_0110;
	dataZ_Pa[17] = 18'b11_1001_1111_1000_1110;
	dataZ_Pa[18] = 18'b11_1101_1111_1100_1100;
	dataZ_Pa[19] = 18'b01_1111_1111_1111_1000;
	dataZ_Pa[20] = 18'b00_1111_1110_0000_0000;
	dataZ_Pa[21] = 18'b00_1111_1100_0000_0000;
	dataZ_Pa[22] = 18'b00_1111_0000_0000_0000;
	dataZ_Pa[23] = 18'b00_0000_0000_0000_0000;
	// #D9D9D9 淺灰
	dataM_Pa[0]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[1]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[2]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[3]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[4]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[5]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[6]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[7]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[8]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[9]  = 18'b00_0000_0000_0000_0000;
	dataM_Pa[10] = 18'b00_0000_0000_0000_0000;
	dataM_Pa[11] = 18'b00_0000_0000_0000_0000;
	dataM_Pa[12] = 18'b00_0000_0000_0000_0000;
	dataM_Pa[13] = 18'b00_0000_0000_0111_0000;
	dataM_Pa[14] = 18'b00_0000_0000_0000_1000;
	dataM_Pa[15] = 18'b00_0000_0000_0000_1000;
	dataM_Pa[16] = 18'b00_0000_0000_1110_1000;
	dataM_Pa[17] = 18'b00_0000_0000_0110_0000;
	dataM_Pa[18] = 18'b00_0000_0000_0011_0000;
	dataM_Pa[19] = 18'b10_0000_0000_0000_0000;
	dataM_Pa[20] = 18'b11_0000_0000_0000_0000;
	dataM_Pa[21] = 18'b11_0000_0000_0000_0000;
	dataM_Pa[22] = 18'b11_0000_0000_0000_0000;
	dataM_Pa[23] = 18'b00_0000_0000_0000_0000;
	// #BFBFBF 深灰
	dataN_Pa[0]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[1]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[2]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[3]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[4]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[5]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[6]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[7]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[8]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[9]  = 18'b00_0000_0000_0000_0000;
	dataN_Pa[10] = 18'b00_0000_0000_0000_0000;
	dataN_Pa[11] = 18'b00_0000_0000_0000_0000;
	dataN_Pa[12] = 18'b00_0000_0000_0000_0000;
	dataN_Pa[13] = 18'b01_0000_0000_0000_0000;
	dataN_Pa[14] = 18'b01_1000_0000_0000_0000;
	dataN_Pa[15] = 18'b01_1100_0000_1010_0000;
	dataN_Pa[16] = 18'b00_1110_0000_0001_0000;
	dataN_Pa[17] = 18'b00_0110_0000_0000_0000;
	dataN_Pa[18] = 18'b00_0010_0000_0000_0000;
	dataN_Pa[19] = 18'b00_0000_0000_0000_0000;
	dataN_Pa[20] = 18'b00_0000_0000_0000_0000;
	dataN_Pa[21] = 18'b00_0000_0000_0000_0000;
	dataN_Pa[22] = 18'b00_0000_0000_0000_0000;
	dataN_Pa[23] = 18'b00_0000_0000_0000_0000;
end
// Box
reg [20:0]dataX_Box[0:18], dataY_Box[0:18];
always@(*)begin
	// 外
	dataX_Box[0]  = 21'b0_0000_0000_0000_0000_0000;
	dataX_Box[1]  = 21'b0_1111_1110_0000_0000_0000;
	dataX_Box[2]  = 21'b0_1010_1010_0000_0000_0000;
	dataX_Box[3]  = 21'b0_1010_1010_0000_0000_0000;
	dataX_Box[4]  = 21'b0_1010_1011_1111_1000_0000;
	dataX_Box[5]  = 21'b0_1010_1011_0100_1000_0000;
	dataX_Box[6]  = 21'b0_1111_1111_0100_1000_0000;
	dataX_Box[7]  = 21'b0_0000_0001_0100_1000_0000;
	dataX_Box[8]  = 21'b0_1111_1111_1111_1110_0000;
	dataX_Box[9]  = 21'b0_1001_0101_0110_1010_0000;
	dataX_Box[10] = 21'b0_1001_0101_0110_1010_0000;
	dataX_Box[11] = 21'b0_1001_0101_0110_1010_0000;
	dataX_Box[12] = 21'b0_1001_0101_0110_1010_0000;
	dataX_Box[13] = 21'b0_1001_0101_0110_1010_0000;
	dataX_Box[14] = 21'b0_1001_0101_0110_1010_0000;
	dataX_Box[15] = 21'b0_1001_0101_0111_1110_0000;
	dataX_Box[16] = 21'b0_1001_0101_0100_0000_0000;
	dataX_Box[17] = 21'b0_1111_1111_1100_0000_0000;
	dataX_Box[18] = 21'b0_0000_0000_0000_0000_0000;
	// 內
	dataY_Box[0]  = 21'b0_0000_0000_0000_0000_0000;
	dataY_Box[1]  = 21'b0_0000_0000_0000_0000_0000;
	dataY_Box[2]  = 21'b0_0101_0100_0000_0000_0000;
	dataY_Box[3]  = 21'b0_0101_0100_0000_0000_0000;
	dataY_Box[4]  = 21'b0_0101_0100_0000_0000_0000;
	dataY_Box[5]  = 21'b0_0101_0100_1011_0000_0000;
	dataY_Box[6]  = 21'b0_0000_0000_1011_0000_0000;
	dataY_Box[7]  = 21'b0_0000_0000_1011_0000_0000;
	dataY_Box[8]  = 21'b0_0000_0000_0000_0000_0000;
	dataY_Box[9]  = 21'b0_0110_1010_1001_0100_0000;
	dataY_Box[10] = 21'b0_0110_1010_1001_0100_0000;
	dataY_Box[11] = 21'b0_0110_1010_1001_0100_0000;
	dataY_Box[12] = 21'b0_0110_1010_1001_0100_0000;
	dataY_Box[13] = 21'b0_0110_1010_1001_0100_0000;
	dataY_Box[14] = 21'b0_0110_1010_1001_0100_0000;
	dataY_Box[15] = 21'b0_0110_1010_1000_0000_0000;
	dataY_Box[16] = 21'b0_0110_1010_1000_0000_0000;
	dataY_Box[17] = 21'b0_0000_0000_0000_0000_0000;
	dataY_Box[18] = 21'b0_0000_0000_0000_0000_0000;
end
// Hole
reg [20:0]dataX_Hole[0:18];
always@(*)begin
	dataX_Hole[0]  = 21'b0_0000_0100_0001_0000_0000;
	dataX_Hole[1]  = 21'b0_0010_1110_0011_0000_0010;
	dataX_Hole[2]  = 21'b0_0111_0111_0011_1001_1110;
	dataX_Hole[3]  = 21'b0_1111_1011_0111_1011_1110;
	dataX_Hole[4]  = 21'b0_0111_1111_1111_1111_1100;
	dataX_Hole[5]  = 21'b0_1111_1111_1111_1111_1000;
	dataX_Hole[6]  = 21'b1_1111_1111_1111_1110_0000;
	dataX_Hole[7]  = 21'b0_1111_1111_1111_1111_0000;
	dataX_Hole[8]  = 21'b0_0111_1111_1111_1111_1000;
	dataX_Hole[9]  = 21'b0_0011_1111_1111_1111_1000;
	dataX_Hole[10] = 21'b0_0011_1111_1111_1111_1110;
	dataX_Hole[11] = 21'b1_1111_1111_1111_1111_0000;
	dataX_Hole[12] = 21'b0_1111_1111_1111_1111_1000;
	dataX_Hole[13] = 21'b0_1001_1001_1111_1110_1100;
	dataX_Hole[14] = 21'b0_0000_0011_1111_1100_0110;
	dataX_Hole[15] = 21'b0_0000_0111_1111_1000_0000;
	dataX_Hole[16] = 21'b0_1100_0011_1111_0000_0000;
	dataX_Hole[17] = 21'b0_1110_0101_1110_0000_0000;
	dataX_Hole[18] = 21'b0_0000_0000_1000_0000_0000;
end
// Car
reg [21:0]dataX_Car[0:9], dataY_Car[0:9], dataZ_Car[0:9], dataW_Car[0:9], dataM_Car[0:9], dataN_Car[0:9], dataO_Car[0:9];
always@(*)begin
	if(car_boom)begin
		// #000000 輪胎
		dataX_Car[0] = 22'b00_0001_1100_0000_1110_0000;
		dataX_Car[1] = 22'b00_0000_0000_1100_0010_0000;
		dataX_Car[2] = 22'b00_0000_0000_1000_0100_0000;
		dataX_Car[3] = 22'b00_0001_0001_1110_1000_0000;
		dataX_Car[4] = 22'b00_1000_1111_1111_0000_0010;
		dataX_Car[5] = 22'b00_1000_0000_1110_1000_1100;
		dataX_Car[6] = 22'b00_1000_0001_0010_0111_0000;
		dataX_Car[7] = 22'b00_0000_0100_0001_0000_0000;
		dataX_Car[8] = 22'b00_0000_1000_0010_0000_0000;
		dataX_Car[9] = 22'b00_0001_1100_0000_1110_0000;
		// #808080 殼
		dataY_Car[0] = 22'b00_0000_0000_0000_0000_0000;
		dataY_Car[1] = 22'b00_0011_1111_0011_1101_0000;
		dataY_Car[2] = 22'b00_0110_0010_0001_0001_1110;
		dataY_Car[3] = 22'b00_0100_0010_0001_0000_0010;
		dataY_Car[4] = 22'b00_0100_0000_0000_0000_0000;
		dataY_Car[5] = 22'b00_0100_0011_0001_0000_0010;
		dataY_Car[6] = 22'b00_0100_0010_1101_0000_0010;
		dataY_Car[7] = 22'b00_0110_0010_0000_0001_1110;
		dataY_Car[8] = 22'b00_0011_0111_1101_1111_0000;
		dataY_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		// #D9D9D9 玻璃
		dataZ_Car[0] = 22'b00_0000_0000_0000_0000_0000;
		dataZ_Car[1] = 22'b00_0000_0000_0000_0000_0000;
		dataZ_Car[2] = 22'b00_0001_1101_0110_1010_0000;
		dataZ_Car[3] = 22'b00_0000_1100_0000_0110_0000;
		dataZ_Car[4] = 22'b00_0001_0000_0000_1110_0000;
		dataZ_Car[5] = 22'b00_0001_1100_0000_0110_0000;
		dataZ_Car[6] = 22'b00_0001_1100_0000_1000_0000;
		dataZ_Car[7] = 22'b00_0001_1001_1110_1110_0000;
		dataZ_Car[8] = 22'b00_0000_0000_0000_0000_0000;
		dataZ_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		// #AEAAAA 板金
		dataW_Car[0] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[1] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[2] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[3] = 22'b00_0010_0000_0000_0001_1100;
		dataW_Car[4] = 22'b00_0010_0000_0000_0001_1100;
		dataW_Car[5] = 22'b00_0010_0000_0000_0001_0000;
		dataW_Car[6] = 22'b00_0010_0000_0000_0000_1100;
		dataW_Car[7] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[8] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		// #FFFF00 燈
		dataM_Car[0] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[1] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[2] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[3] = 22'b00_0000_0000_0000_0000_0001;
		dataM_Car[4] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[5] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[6] = 22'b00_0000_0000_0000_0000_0001;
		dataM_Car[7] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[8] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		if(turbo) begin
			// #FF0000 外火
			dataN_Car[0] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[1] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[2] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[3] = 22'b10_0000_0000_0000_0000_0000;
			dataN_Car[4] = 22'b01_0000_0000_0000_0000_0000;
			dataN_Car[5] = 22'b10_0000_0000_0000_0000_0000;
			dataN_Car[6] = 22'b01_0000_0000_0000_0000_0000;
			dataN_Car[7] = 22'b10_0000_0000_0000_0000_0000;
			dataN_Car[8] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[9] = 22'b00_0000_0000_0000_0000_0000;
			// #FFC000 內火
			dataO_Car[0] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[1] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[2] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[3] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[4] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[5] = 22'b01_0000_0000_0000_0000_0000;
			dataO_Car[6] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[7] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[8] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		end else begin
			// #000000 外火
			dataN_Car[0] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[1] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[2] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[3] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[4] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[5] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[6] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[7] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[8] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[9] = 22'b00_0000_0000_0000_0000_0000;
			// #000000 內火
			dataO_Car[0] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[1] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[2] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[3] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[4] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[5] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[6] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[7] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[8] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		end
	end else begin
		// #000000 輪胎
		dataX_Car[0] = 22'b00_0001_1100_0000_1110_0000;
		dataX_Car[1] = 22'b00_0000_0000_0000_0000_0000;
		dataX_Car[2] = 22'b00_0000_0000_0000_0000_0000;
		dataX_Car[3] = 22'b00_0000_0000_0000_0000_0000;
		dataX_Car[4] = 22'b00_1000_0000_0000_0000_0000;
		dataX_Car[5] = 22'b00_1000_0000_0000_0000_0000;
		dataX_Car[6] = 22'b00_1000_0000_0000_0000_0000;
		dataX_Car[7] = 22'b00_0000_0000_0000_0000_0000;
		dataX_Car[8] = 22'b00_0000_0000_0000_0000_0000;
		dataX_Car[9] = 22'b00_0001_1100_0000_1110_0000;
		// #808080 殼
		dataY_Car[0] = 22'b00_0000_0000_0000_0000_0000;
		dataY_Car[1] = 22'b00_0011_1111_1111_1111_0000;
		dataY_Car[2] = 22'b00_0110_0010_0001_0001_1110;
		dataY_Car[3] = 22'b00_0100_0011_1111_0000_0010;
		dataY_Car[4] = 22'b00_0100_0011_1111_0000_0010;
		dataY_Car[5] = 22'b00_0100_0011_1111_0000_0010;
		dataY_Car[6] = 22'b00_0100_0011_1111_0000_0010;
		dataY_Car[7] = 22'b00_0110_0010_0001_0001_1110;
		dataY_Car[8] = 22'b00_0011_1111_1111_1111_0000;
		dataY_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		// #D9D9D9 玻璃
		dataZ_Car[0] = 22'b00_0000_0000_0000_0000_0000;
		dataZ_Car[1] = 22'b00_0000_0000_0000_0000_0000;
		dataZ_Car[2] = 22'b00_0001_1101_1110_1110_0000;
		dataZ_Car[3] = 22'b00_0001_1100_0000_1110_0000;
		dataZ_Car[4] = 22'b00_0001_1100_0000_1110_0000;
		dataZ_Car[5] = 22'b00_0001_1100_0000_1110_0000;
		dataZ_Car[6] = 22'b00_0001_1100_0000_1110_0000;
		dataZ_Car[7] = 22'b00_0001_1101_1110_1110_0000;
		dataZ_Car[8] = 22'b00_0000_0000_0000_0000_0000;
		dataZ_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		// #AEAAAA 板金
		dataW_Car[0] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[1] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[2] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[3] = 22'b00_0010_0000_0000_0001_1100;
		dataW_Car[4] = 22'b00_0010_0000_0000_0001_1100;
		dataW_Car[5] = 22'b00_0010_0000_0000_0001_1100;
		dataW_Car[6] = 22'b00_0010_0000_0000_0001_1100;
		dataW_Car[7] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[8] = 22'b00_0000_0000_0000_0000_0000;
		dataW_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		// #FFFF00 燈
		dataM_Car[0] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[1] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[2] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[3] = 22'b00_0000_0000_0000_0000_0001;
		dataM_Car[4] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[5] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[6] = 22'b00_0000_0000_0000_0000_0001;
		dataM_Car[7] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[8] = 22'b00_0000_0000_0000_0000_0000;
		dataM_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		if(turbo) begin
			// #FF0000 外火
			dataN_Car[0] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[1] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[2] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[3] = 22'b10_0000_0000_0000_0000_0000;
			dataN_Car[4] = 22'b01_0000_0000_0000_0000_0000;
			dataN_Car[5] = 22'b10_0000_0000_0000_0000_0000;
			dataN_Car[6] = 22'b01_0000_0000_0000_0000_0000;
			dataN_Car[7] = 22'b10_0000_0000_0000_0000_0000;
			dataN_Car[8] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[9] = 22'b00_0000_0000_0000_0000_0000;
			// #FFC000 內火
			dataO_Car[0] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[1] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[2] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[3] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[4] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[5] = 22'b01_0000_0000_0000_0000_0000;
			dataO_Car[6] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[7] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[8] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		end else begin
			// #000000 外火
			dataN_Car[0] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[1] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[2] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[3] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[4] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[5] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[6] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[7] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[8] = 22'b00_0000_0000_0000_0000_0000;
			dataN_Car[9] = 22'b00_0000_0000_0000_0000_0000;
			// #000000 內火
			dataO_Car[0] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[1] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[2] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[3] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[4] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[5] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[6] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[7] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[8] = 22'b00_0000_0000_0000_0000_0000;
			dataO_Car[9] = 22'b00_0000_0000_0000_0000_0000;
		end
	end
end
// coin
reg [11:0]dataX_Coin[0:10], dataY_Coin[0:10];
always@(*)begin
	// Light Yellow
	dataX_Coin[0]  = 12'b0001_1111_1000;
	dataX_Coin[1]  = 12'b0010_0000_0100;
	dataX_Coin[2]  = 12'b0100_0000_0010;
	dataX_Coin[3]  = 12'b1000_0000_0001;
	dataX_Coin[4]  = 12'b1000_0000_0001;
	dataX_Coin[5]  = 12'b1000_0000_0001;
	dataX_Coin[6]  = 12'b1000_0000_0001;
	dataX_Coin[7]  = 12'b1000_1001_1001;
	dataX_Coin[8]  = 12'b0100_0000_0010;
	dataX_Coin[9]  = 12'b0010_0000_0100;
	dataX_Coin[10] = 12'b0001_1111_1000;
	// Yellow
	dataY_Coin[0]  = 12'b0000_0000_0000;
	dataY_Coin[1]  = 12'b0001_1111_1000;
	dataY_Coin[2]  = 12'b0011_1111_1100;
	dataY_Coin[3]  = 12'b0111_1111_1110;
	dataY_Coin[4]  = 12'b0111_1111_1110;
	dataY_Coin[5]  = 12'b0111_1111_1110;
	dataY_Coin[6]  = 12'b0111_1111_1110;
	dataY_Coin[7]  = 12'b0111_0110_0110;
	dataY_Coin[8]  = 12'b0011_1111_1100;
	dataY_Coin[9]  = 12'b0001_1111_1000;
	dataY_Coin[10] = 12'b0000_0000_0000;
end
// bomb
reg [11:0]dataX_Bomb[0:10], dataY_Bomb[0:10];
always@(*)begin
	// black
	dataX_Bomb[0]  = 12'b0001_1110_0000;
	dataX_Bomb[1]  = 12'b0011_1111_0000;
	dataX_Bomb[2]  = 12'b0111_1111_1000;
	dataX_Bomb[3]  = 12'b1111_1111_1100;
	dataX_Bomb[4]  = 12'b1111_1111_1100;
	dataX_Bomb[5]  = 12'b1111_1111_1100;
	dataX_Bomb[6]  = 12'b1111_1111_1100;
	dataX_Bomb[7]  = 12'b1101_1000_1100;
	dataX_Bomb[8]  = 12'b0111_1111_1000;
	dataX_Bomb[9]  = 12'b0011_1111_0000;
	dataX_Bomb[10] = 12'b0001_1110_0000;
	// white
	dataY_Bomb[0]  = 12'b0000_0000_0000;
	dataY_Bomb[1]  = 12'b0000_0000_0000;
	dataY_Bomb[2]  = 12'b0000_0000_0000;
	dataY_Bomb[3]  = 12'b0000_0000_0000;
	dataY_Bomb[4]  = 12'b0000_0000_0000;
	dataY_Bomb[5]  = 12'b0000_0000_0010;
	dataY_Bomb[6]  = 12'b0000_0000_0001;
	dataY_Bomb[7]  = 12'b0010_0111_0000;
	dataY_Bomb[8]  = 12'b0000_0000_0000;
	dataY_Bomb[9]  = 12'b0000_0000_0000;
	dataY_Bomb[10] = 12'b0000_0000_0000;
end
// Blood
reg [11:0]dataX_Blood[0:10], dataY_Blood[0:10];
always@(*)begin
	// red
	dataX_Blood[0]  = 12'b0000_0111_1100;
	dataX_Blood[1]  = 12'b0000_1111_1110;
	dataX_Blood[2]  = 12'b0001_1111_1111;
	dataX_Blood[3]  = 12'b0011_1111_1111;
	dataX_Blood[4]  = 12'b0111_1111_1110;
	dataX_Blood[5]  = 12'b1111_1111_1100;
	dataX_Blood[6]  = 12'b0111_1111_1110;
	dataX_Blood[7]  = 12'b0011_1111_1111;
	dataX_Blood[8]  = 12'b0001_1011_0011;
	dataX_Blood[9]  = 12'b0000_1111_1110;
	dataX_Blood[10] = 12'b0000_0111_1100;
	// white
	dataY_Blood[0]  = 12'b0000_0000_0000;
	dataY_Blood[1]  = 12'b0000_0000_0000;
	dataY_Blood[2]  = 12'b0000_0000_0000;
	dataY_Blood[3]  = 12'b0000_0000_0000;
	dataY_Blood[4]  = 12'b0000_0000_0000;
	dataY_Blood[5]  = 12'b0000_0000_0000;
	dataY_Blood[6]  = 12'b0000_0000_0000;
	dataY_Blood[7]  = 12'b0000_0000_0000;
	dataY_Blood[8]  = 12'b0000_0100_1100;
	dataY_Blood[9]  = 12'b0000_0000_0000;
	dataY_Blood[10] = 12'b0000_0000_0000;
end
// Road
reg [49:0]dataX_Road[0:60], //  Black : 24h000000
			 dataY_Road[0:60], // Y-Gray : 24hA6A6A6
			 dataZ_Road[0:60]; // Z-Gray : 24hD0CECE
always@(*)begin
	dataX_Road[0]  = 50'b11_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
	dataX_Road[20] = 50'b11_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
	dataX_Road[40] = 50'b11_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
	dataX_Road[60] = 50'b11_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
	dataX_Road[1]  = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[2]  = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[3]  = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[4]  = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[5]  = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[6]  = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[7]  = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[8]  = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[9]  = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[10] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[11] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[12] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[13] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[14] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[15] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[16] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[17] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[18] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[19] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[21] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[22] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[23] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[24] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[25] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[26] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[27] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[28] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[29] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[30] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[31] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[32] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[33] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[34] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[35] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[36] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[37] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[38] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[39] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[41] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[42] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[43] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[44] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[45] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[46] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[47] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[48] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[49] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[50] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[51] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[52] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[53] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[54] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[55] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[56] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[57] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[58] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	dataX_Road[59] = 50'b10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;
	/*************************************************************************************/
	dataY_Road[0]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataY_Road[19] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataY_Road[20] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataY_Road[21] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataY_Road[39] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataY_Road[40] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataY_Road[41] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataY_Road[60] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataY_Road[1]  = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[2]  = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[3]  = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[4]  = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[5]  = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[6]  = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[7]  = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[8]  = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[9]  = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[10] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[11] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[12] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[13] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[14] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[15] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[16] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[17] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[18] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[22] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[23] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[24] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[25] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[26] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[27] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[28] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[29] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[30] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[31] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[32] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[33] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[34] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[35] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[36] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[37] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[38] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[42] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[43] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[44] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[45] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[46] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[47] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[48] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[49] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[50] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[51] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[52] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[53] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[54] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[55] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[56] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[57] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[58] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataY_Road[59] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	/*************************************************************************************/
	dataZ_Road[19] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataZ_Road[21] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataZ_Road[39] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataZ_Road[41] = 50'b01_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1110;
	dataZ_Road[0]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[1]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[2]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[3]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[4]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[5]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[6]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[7]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[8]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[9]  = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[10] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[11] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[12] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[13] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[14] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[15] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[16] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[17] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[18] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[20] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[22] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[23] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[24] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[25] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[26] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[27] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[28] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[29] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[30] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[31] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[32] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[33] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[34] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[35] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[36] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[37] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[38] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[40] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[42] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[43] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[44] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[45] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[46] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[47] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[48] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[49] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[50] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[51] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[52] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[53] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[54] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[55] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[56] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[57] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[58] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[59] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
	dataZ_Road[60] = 50'b00_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
end
// Yellow Line
reg [47:0]dataX_Line = 48'b0000_0111_1111_1000_0000_0111_1111_1000_0000_1111_1111_1000;
always@(posedge CLK or negedge Key[3]) begin
	if(!Key[3]) dataX_Line = 48'b0000_0111_1111_1000_0000_0111_1111_1000_0000_1111_1111_1000;
	else dataX_Line <= {dataX_Line[46:0], dataX_Line[47]};
end
//---------------------------------------------------- 
endmodule 