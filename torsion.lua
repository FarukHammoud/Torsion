setmetatable(_G,{__index=require "processing"})
MAX_LAYERS = 10000
EPSILON = 0.001

PSurface = {
	x = 0,
	y = 0,
	d = 0,
	exist = false,
	h = 0,
	layer = nil,
}
function PSurface:null()
	local self = setmetatable({},{__index = PSurface})
	self.exist = false
	self.h = 0
	self.layer = 0
	return self
end
function PSurface:new(x,y,parts)
	local self = setmetatable({},{__index = PSurface})
	self.x = x
	self.y = y
	self.exist = true
	self.d = 50/parts
	self.h = 0
	self.layer = nil
	return self
end
function PSurface:show_base()
	stroke(0)
	fill(120)
	rect(self.x-self.d,self.y-self.d,2*self.d,2*self.d)
	fill(0)
	text(self.h,self.x,self.y)
end
function PSurface:find_layer()
	
			
end

Model = {
	name = 'default',
	last_run = '',
}

function Model:new(name,inside,parts)
	local self = setmetatable({},{__index = Model})
	self.name = name
	self.matrix = {}
	self.parts = parts
	self.dx = 100/parts
	for i = 0,parts+2 do
		self.matrix[i] = {}
		for j = 0, parts+2 do
			local x,y = (i-1)*self.dx,(j-1)*self.dx
			if inside(x,y) then
				self.matrix[i][j] = PSurface:new(x,y,parts)
			else
				self.matrix[i][j] = PSurface:null()
			end
		end
	end
	self.max_layer = self:find_layers()
	return self
end
function Model:up_force(i,j,max_layer)
	
	local upf = 0

	local function up_tension_force(di,dj)
		dh = self.matrix[i][j].h - self.matrix[i+di][j+dj].h
		hp = math.sqrt(dh^2 + (self.dx)^2)
		return dh*(self.dx/hp-1)
	end
	local function up_pression_force(di,dj)
		dh = self.matrix[i][j].h - self.matrix[i+di][j+dj].h
		hp = math.sqrt(dh^2 + (self.dx)^2)
		return self.dx/hp
	end	
	for di = -1,1 do
		for dj = -1,1 do
			--print(i,j,di,dj,up_tension_force(di,dj),up_pression_force(di,dj))
			if self.matrix[i][j].layer > max_layer then
				upf = upf + up_tension_force(0,0) + up_pression_force(0,0)
			else
				upf = upf + up_tension_force(di,dj) + up_pression_force(di,dj)
			end
		end
	end

	return upf
end
function Model:simulate()
	local max_layer,counter = 1,1
	while max_layer <= self.max_layer and counter <= 10000 do
		io.write('\rRunning layer/loop number: ',max_layer,' ',counter)
		local d_max = self:run(0.1,max_layer)
		if d_max < EPSILON then
			max_layer = max_layer + 1
		end
		counter = counter + 1
	end
end
function Model:run(dt,max_layer)
	local d_max = 0
	for i = 1,parts+1 do
		for j = 1, parts+1 do
			local ps = self.matrix[i][j]
			if ps.exist and ps.layer <= max_layer then
				d = self:up_force(i,j,max_layer)
				ps.h = ps.h + d*dt
				if math.abs(d) > d_max then
					d_max = math.abs(d)
				end 
			end
		end
	end
	return d_max
end
function Model:find_layers()
	local someone_without_layer = true
	local counter = 1
	while someone_without_layer do
		someone_without_layer = false
		for i = 1,parts+1 do
			for j = 1, parts+1 do
				if self.matrix[i][j].exist then
					local min = MAX_LAYERS
					for di = -1,1 do
						for dj = -1,1 do
							if self.matrix[i+di][j+dj].layer ~= nil then
								if  self.matrix[i+di][j+dj].layer <= min then
									min = self.matrix[i+di][j+dj].layer 
								end
							end
						end
					end
					if min == -1 or min > counter then
						someone_without_layer = true
					else
						self.matrix[i][j].layer = min + 1
					end
				end
			end
		end
		counter = counter + 1
	end
	return counter
	--[[
	for i = 1,parts+1 do
		for j = 1, parts+1 do
			print(i,j,self.matrix[i][j].layer)
		end		
	end
	]]
end
function Model:show_base()
	background(255,124,0)
	translate(200,200)
	scale(6)
	textSize(3)
	strokeWeight(0.5)
	for i = 1,parts+1 do
		for j = 1, parts+1 do
			if self.matrix[i][j].exist then
				self.matrix[i][j]:show_base()
			end
		end
	end
	redraw()
end
function Model:show_membrane()
	background(255,124,0)
	textSize(3)
	strokeWeight(0.5)
	stroke(0)
	translate(400,600)
	rotateX(-math.pi/8)
	rotateY(math.pi/6)
	rotateZ(math.pi/2)
	scale(5)
	for i = 1,parts+1 do
		for j = i%2+1, parts+1,2 do
			local ps = self.matrix[i][j]
			local n = self.matrix[i][j+1]
			local s = self.matrix[i][j-1]
			local w = self.matrix[i-1][j]
			local e = self.matrix[i+1][j]
			if ps.exist then
				
				translate(ps.x,ps.y)
				stroke(0,100)
				
				strokeWeight(1)
				
				-- NE triangle 
				fill(200,100,100,150)
				beginShape()
				vertex(0,0,ps.h)
				vertex(self.dx,0,e.h)
				vertex(0,self.dx,n.h)
				endShape()
				-- NW triangle
				fill(100,200,200,150)
				beginShape()
				vertex(0,0,ps.h)
				vertex(-self.dx,0,w.h)
				vertex(0,self.dx,n.h)
				endShape()
				-- SW triangle
				fill(100,100,200,150)
				beginShape()
				vertex(0,0,ps.h)
				vertex(-self.dx,0,w.h)
				vertex(0,-self.dx,s.h)
				endShape()
				-- SE triangle
				fill(120,120,120,150)
				beginShape()
				vertex(0,0,ps.h)
				vertex(self.dx,0,e.h)
				vertex(0,-self.dx,s.h)
				endShape()

				translate(-ps.x,-ps.y)
			end
		end
	end
	
	redraw()

end



local function rectangle(x,y)
	if x == 50 and y == 50 then
		return false 
	elseif (x >= 0 and x <= 100 and y >= 0 and y <= 100) then
		return true
	end
	-- (x >= 0 and x <= 100 and y >= 0 and y <= 100)
end 
local function circ(x,y)
	if (x-50)^2+(y-50)^2 <= 50^2 then
		return true
	else
		return false
	end
end
parts = 20

model = Model:new('',circ,parts)
model:simulate()
model:show_membrane()



