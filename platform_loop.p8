pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
//system core loop
function _init()
 create_game_manager()
 create_color_manager()
end

function _update()
 gm.update()
 cm.update()
end

function _draw()
 cls()
 gm.draw()
 cm.draw()
end
-->8
//game

function create_game_manager()
 gm = {}
 gm.state = 'menu'
 gm.menu_manager = create_menu_manager()
 gm.game_player = create_game_player()
 gm.start_game = function()
  gm.state = 'game'
 end
 
 gm.update = function()
  if gm.state == 'menu' then
   gm.menu_manager.update()
  elseif gm.state == 'game' then
   gm.game_player.update()
  end
 end
 
 gm.draw = function()
  if gm.state == 'menu' then
   gm.menu_manager.draw()
  elseif gm.state == 'game' then
   gm.game_player.draw()
  end
 end
end


-->8
//menu manager
function create_menu_manager()
 menu = {}
 menu.index = 1
 menu.x_pos = 64
 menu.y_pos = 80
 menu.options = {}
 add(menu.options, color_scheme_option())
 add(menu.options, play_option())
 menu.update = function()
  if btnp(2) then
   menu.index -= 1
  elseif btnp(3) then
   menu.index += 1
  elseif btnp(5) then
   menu.options[menu.index].action()
  end
   menu.index = mod_1(menu.index, #menu.options)
 end
 menu.draw = function()
  local x_mid = menu.x_pos
  local y_mid = menu.y_pos
  local line_height = 10
  local char_height = 6
  local char_width = 4
  local y_start = y_mid - (char_height+(line_height*#menu.options))/2
  local y_cur = y_start
  local x_cur
  rectfill(0,0,128,128,cm.get('primary_2'))
  for i = 1, #menu.options do
   string = menu.options[i].get_draw()
   string_color = menu.options[i].get_color()
   x_cur =  x_mid-(#string*char_width)/2
   print(string, x_cur, y_cur, string_color)
   if (menu.index == i) then
    rect(x_cur-2, y_cur-2, x_cur+(char_width*#string), y_cur+char_height, cm.get('extra_1'))
   end
   y_cur+=line_height
  end
 end
 return menu
end

function color_scheme_option()
 local item = {}
 item.get_draw = function()
  return 'color_scheme: '..cm.get_scheme_name()
 end
 item.get_color = function()
  return cm.get('primary_1')
 end
 item.action = function()
  cm.iterate_scheme()
 end
 return item
end

function play_option()
 local item = {}
 item.get_draw = function()
  return 'play'
 end
 item.get_color = function()
  return cm.get('primary_1')
 end
 item.action = function()
  gm.start_game()
 end
 return item
end
-->8
//game_player

function create_game_player()
 gp = {}
 gp.workers = {}
 add(gp.workers, create_game_controller())
 add(gp.workers, create_timer())
 add(gp.workers, create_player())
 add(gp.workers, create_score_keeper())
 add(gp.workers, create_enemies())
 add(gp.workers, create_coin_controller())
 gp.update = function()
  for item in all(gp.workers) do
   item.update()
  end
 end
 gp.draw = function()
  for item in all(gp.workers) do
   item.draw()
  end
 end
 return gp
end

function create_game_controller()
	local this = {}
 this.draw = function()
  rectfill(0,0,128,128,cm.get('primary_2'))  
 end
 this.update = function()
 	if player.dead then
 	 if btnp(5) then
 	  _init()
 	 end
 	end
 end
 return this
end

function create_timer()
 local this = {}
 this.external_time = 1
 this.internal_time = 1
 this.draw = function() 
  print(this.external_time, 120, 0, cm.get('secondary_1'))
 end
 this.update = function()
  if player.dead then
   return 
  end
  this.internal_time += 1
  if this.internal_time >= 8 then
   this.internal_time = 0
   this.external_time += 1
  end
 end
 return this
end

function create_player()
 local this = {}
 this.vel = {1, 0}
 this.loc = {0,120}
 this.width = 8
 this.height = 8
 this.jumps = 2
 this.dead = false
 this.jump = function()
  this.vel[2] = -2.3
  this.jumps -= 1
  this.shoot_lazer()
 end
 this.shoot_lazer = function()
 	create_lazer(this.loc[1], this.loc[2]+this.height, "down")
 end
 this.gravity = function()
 	force = .1
 	this.vel[2] += force 
 end
 this.can_jump = function()
 	local min_velocity = -2
 	return this.jumps >0 and this.vel[2] >= min_velocity
 end
 this.floor = function()
 	if this.loc[2] >= 120 then
 		this.loc[2] = 120
 		this.jumps = 2
 		if this.vel[2] > 0 then
 		 this.vel[2] = 0
 		end
 	end
 end
 this.wrap = function()
 	this.loc[1] = wrap(this.loc[1])
 	if this.loc[1] < 0 then
 	 coin_controller.new_round()
 	end
 end
 this.update = function()
  if this.dead then
   return
  end
  local jump_command = btnp(2)
  if jump_command and this.can_jump() then
  	this.jump()
  end
  this.gravity()
 	this.loc[1] += this.vel[1]
 	this.loc[2] += this.vel[2]
 	this.floor()
  this.wrap()
  this.check_death()
 end
 this.draw = function()
  this.col = cm.get('primary_2')
  //todo:j implement draw with color
  spr(1, this.loc[1], this.loc[2])
 end
 
 this.check_death = function()
  for lazer in all(enemies.lazers) do
   if lazer.loc[1] >= this.loc[1] and lazer.loc[1] <= this.loc[1]+this.width and lazer.loc[2] >= this.loc[2] and lazer.loc[2] <= this.loc[2]+this.height then
    this.dead = true
   end
  end
 end
 player = this
 return this
end

function create_score_keeper()
 local this = {}
 this.score = 0
 this.draw = function()
  if not player.dead then
   print(this.score,0,0,cm.get('secondary_1')) 
  else 
   print("killed by a lazer",30,40,cm.get('secondary_1')) 
  	print(this.score,75,50,cm.get('secondary_3')) 
  	print("score:",51,50,cm.get('secondary_1')) 
  end
 end
 this.increment_score = function()
  this.score += 1
 end
 this.update = function()

 end
 score_keeper = this
 return this
end

function create_enemies()
	local this = {}
	this.lazers = {}
	this.update = function()
		for lazer in all(this.lazers) do
			lazer.update()
		end
	end
	this.draw = function()
		for lazer in all(this.lazers) do
			lazer.draw()
		end
	end
	enemies = this
	return this
end

function create_lazer(x, y, direction)
	local this = {}
	this.speed = 1
	this.length = 4
	this.vel = scale_table(get_dir(direction), this.speed)
	this.loc = {x, y}
	this.update = function()
		this.loc[1] += this.vel[1]
 	this.loc[2] += this.vel[2]
 	this.bounce()
  this.wrap()
	end
	this.draw = function()
 	local hue = cm.get('primary_1')
 	local hue2 = cm.get('secondary_3')
	 for i = 0, this.length-1 do
 	 //todo:j check direction addition?
	  local location = add_tables(this.loc,(scale_table(get_dir(direction), -i)))
	  if i == 0 then  
 		 pset(location[1], location[2], hue)
		 else
		  pset(location[1], location[2], hue2)
		 end
  end
	end
	this.wrap = function()
 	this.loc[1] = wrap(this.loc[1])
 end
 this.bounce = function()
 //todo:j bounce off of platforms??
  if this.loc[2] <= 0 then
   this.loc[2] = 0+this.length-1 
   direction = 'down'
   this.vel = scale_table(get_dir(direction), this.speed)
  end
  if this.loc[2] >= 128 then
   this.loc[2] = 128-this.length +1 
   direction = 'up'
   this.vel = scale_table(get_dir(direction), this.speed)
  end
 end
 if this.loc[1] > 0 and this.loc[1] < 128 then
  add(enemies.lazers, this)
 end
	return this
end

function create_coin_controller()
 local this = {}
 this.coin_radius = 4
 this.real_coin = {}
 this.real_coin.loc = generate_coin_loc()
 this.real_coin.collected = false
 this.fake_coin = {}
 this.fake_coin.loc = generate_coin_loc()
 this.draw = function()
  if not this.real_coin.collected then
   spr(2, this.real_coin.loc[1]-this.coin_radius, this.real_coin.loc[2]-this.coin_radius)
  end
  spr(10, this.fake_coin.loc[1]-this.coin_radius, this.fake_coin.loc[2]-this.coin_radius)
 end
 this.update = function()
  if this.real_coin.collected then
   return
  end
  if rectangle_in_circle({player.loc[1], player.loc[2], player.loc[1]+player.width, player.loc[2] + player.height}, {this.real_coin.loc[1], this.real_coin.loc[2], this.coin_radius}) then
   score_keeper.increment_score()
   this.real_coin.collected = true
  end
 end
 this.new_round = function()
  if not this.real_coin.collected then
   return
  end
  this.real_coin.collected = false
  this.real_coin.loc = this.fake_coin.loc
  this.fake_coin.loc = generate_coin_loc()
 end
 coin_controller = this
 return this
end
-->8
//domain specific helpers

function generate_coin_loc()
 return {rand_int(20, 108), rand_int(70, 120)}
end
-->8
//domain agnostic helpers

function mod(a, b) 
 return a - (flr(a/b)*b)
end

function mod_1(a, b)
 local result = mod(a,b)
 if result == 0 then
  result = b
 end
 return result
end

function wrap(int)
 if int > 128 then
  int = -8
 end
 if int < -8 then
  int = 128
 end
 return int
end

function pick(list)
 return list[rand_int(0, #list)]
end

function rand_int(lo,hi)
 return flr(rnd(hi-lo))+lo+1
end

function sqr(x)
 return x*x
end

function point_in_circle(point, circle)
 return sqr(circle[1] - point[1])+sqr(circle[2]-point[2]) <= sqr(circle[3])
end

function rectangle_in_circle(rectangle, circle)
 local xn = max(rectangle[1], min(circle[1], rectangle[3]))
 local yn = max(rectangle[2], min(circle[2], rectangle[4]))
 local dx = xn - circle[1]
 local dy = yn - circle[2]
 return (sqr(dx) + sqr(dy)) <= sqr(circle[3])
end		

function get_dir(direction)
	if direction == "left" then
		return {-1, 0}
	end
	if direction == "up" then
		return {0, -1}
	end
	if direction == "right" then
		return {1, 0}
	end
	if direction == "down" then
		return {0, 1}
	end
end

function add_tables(t1, t2)
 if #t1 != #t2 then
  return error //todo:j cleanup??
 end
 local t3 = {}
 for i=1, #t1 do
 	add(t3, t1[i]+t2[i])
 end
 return t3
end

function scale_table(t1, el)
	local t2 = {}
	for i=1, #t1 do
 	add(t2, t1[i]*el)
 end
 return t2
end
-->8
//color manager
function create_color_manager()
 if cm then
  return
 end
 cm = {}
 cm.options = {}
 add(cm.options, create_full_color())
 add(cm.options, create_gray_scale())
 add(cm.options, create_blinding())
 add(cm.options, create_pleasant())
 
 cm.scheme = 1
 cm.iterate_scheme = function()
  cm.scheme += 1
  cm.scheme = mod_1(cm.scheme, #cm.options)
 end
 cm.get_scheme_name = function()
  return cm.options[cm.scheme].name
 end
 cm.get = function(color_name) 
  return cm.options[cm.scheme][color_name]
 end
 cm.update = function()
 
 end
 cm.draw = function()
 
 end
end

function create_full_color()
 color_scheme = {}
 color_scheme.name = 'full_color'
 color_scheme['primary_1'] = 15
 color_scheme['primary_2']= 3
 color_scheme['primary_3'] = 2
 color_scheme['secondary_1'] = 7
 color_scheme['secondary_2'] = 11
 color_scheme['secondary_3'] = 14
 color_scheme['extra_1'] = 8
 color_scheme['extra_2'] = 12
 color_scheme['extra_3'] = 10
 color_scheme['extra_4'] = 6
 return color_scheme
end

function create_gray_scale()
 color_scheme = {}
 color_scheme.name = 'gray_scale'
 color_scheme['primary_1'] = 6
 color_scheme['primary_2']= 5
 color_scheme['primary_3'] = 0
 color_scheme['secondary_1'] = 6
 color_scheme['secondary_2'] = 5
 color_scheme['secondary_3'] = 0
 color_scheme['extra_1'] = 7
 color_scheme['extra_2'] = 6
 color_scheme['extra_3'] = 5
 color_scheme['extra_4'] = 6
 return color_scheme
end

function create_blinding()
 color_scheme = {}
 color_scheme.name = 'blinding'
 color_scheme['primary_1'] = 10
 color_scheme['primary_2']= 12
 color_scheme['primary_3'] = 8
 color_scheme['secondary_1'] = 9
 color_scheme['secondary_2'] = 13
 color_scheme['secondary_3'] = 14
 color_scheme['extra_1'] = 11
 color_scheme['extra_2'] = 15
 color_scheme['extra_3'] = 7
 color_scheme['extra_4'] = 6
 return color_scheme
end

function create_pleasant()
 color_scheme = {}
 color_scheme.name = 'pleasant'
 color_scheme['primary_1'] = 4
 color_scheme['primary_2'] = 1
 color_scheme['primary_3'] = 6
 color_scheme['secondary_1'] = 5
 color_scheme['secondary_2'] = 2
 color_scheme['secondary_3'] = 7
 color_scheme['extra_1'] = 13
 color_scheme['extra_2'] = 3
 color_scheme['extra_3'] = 15
 color_scheme['extra_4'] = 0
 return color_scheme
end
__gfx__
00000000088888800008800055555555555555555555555555555555000000000000000000000000000ee0000000000000000000000000000000000000000000
0000000080800808008ee8005dddddd55dddddddddddddddddddddd500000000000000000000000000e00e000000000000000000000000000000000000000000
007007008080080808eeee805dddddd55dddddddddddddddddddddd5000aa00000000000000000000e0000e00000000000000000000000000000000000000000
000770008000000808eeee805dddddd55dddddddddddddddddddddd5000aa00000aaaa00000000000e0000e00000000000000000000000000000000000000000
000770008000080808eeee805dddddd55dddddddddddddddddddddd5000aa00000aaaa00000660000e0000e00000000000000000000000000000000000000000
007007008088880808eeee805dddddd55dddddddddddddddddddddd5000aa00000000000006666000e0000e00000000000000000000000000000000000000000
0000000080000008008ee8005dddddd55dddddddddddddddddddddd500000000000000000666666000e00e000000000000000000000000000000000000000000
00000000888888880008800055555555555555555555555555555555000000000000000077777777000ee0000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000030303030303000000000000000000000505050505050a0a0a0a0a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000050505050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0405050505050505050505050505050505050505050505050505050506050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
