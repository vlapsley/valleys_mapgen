function default.grow_tree(pos, is_apple_tree)
	local rand = math.random()
	local height = math.floor(4 + 2.5 * rand)
	local radius = 3 + rand

	local leaves = minetest.get_content_id("default:leaves")
	local trunk = minetest.get_content_id("default:tree")
	local air = minetest.get_content_id("air")
	local ignore = minetest.get_content_id("ignore")
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map({x = pos.x - 3, y = pos.y, z = pos.z - 3}, {x = pos.x + 3, y = pos.y + height + 3, z = pos.z + 3})
	local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local data = vm:get_data()
	if is_apple_tree then
		vmg.grow_apple_tree(pos, data, area, height, radius, trunk, leaves, minetest.get_content_id("default:apple"), air, ignore)
	else
		vmg.grow_tree(pos, data, area, height, radius, trunk, leaves, air, ignore)
	end
	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
end

function vmg.grow_tree(pos, data, area, height, radius, trunk, leaves, air, ignore)
	local ystride = area.ystride
	local iv = area:indexp(pos)
	data[iv] = air
	for i = 1, height do
		if data[iv] == air or data[iv] == ignore then
			data[iv] = trunk
		end
		iv = iv + ystride
	end
	local np = {offset = 0.8, scale = 0.4, spread = {x = 8, y = 4, z = 8}, octaves = 3, persist = 0.5}
	pos.y = pos.y + height - 1
	vmg.make_leavesblob(pos, data, area, leaves, air, ignore, {x = radius, y = radius, z = radius}, np)
end

function vmg.grow_apple_tree(pos, data, area, height, radius, trunk, leaves, fruit, air, ignore)
	local ystride = area.ystride
	local iv = area:indexp(pos)
	data[iv] = air
	for i = 1, height do
		if data[iv] == air or data[iv] == ignore then
			data[iv] = trunk
		end
		iv = iv + ystride
	end
	local np = {offset = 0.8, scale = 0.4, spread = {x = 8, y = 4, z = 8}, octaves = 3, persist = 0.5}
	pos.y = pos.y + height - 1
	vmg.make_leavesblob(pos, data, area, leaves, air, ignore, {x = radius, y = radius, z = radius}, np, 0.06, fruit)
end

function vmg.make_leavesblob(pos, data, area, leaves, air, ignore, radius, np, fruit_chance, fruit)
	local count = 0
	fruit_chance = fruit_chance or 0

	np.seed = math.random(0, 4294967295)
	local round_radius = {x = math.ceil(radius.x), y = math.ceil(radius.y), z = math.ceil(radius.z)}

	local length = vector.multiply(round_radius, 2)
	local chulens = vector.add(length, 1)
	local minp = vector.subtract(pos, round_radius)
	local maxp = vector.add(minp, length)
	local obj = minetest.get_perlin_map(np, chulens)
	local pmap = obj:get3dMap_flat(minp)
	local i = 1
	for x = minp.x, maxp.x do
		local xval = ((x - pos.x) / radius.x) ^ 2
		for y = minp.y, maxp.y do
			local yval = ((y - pos.y) / radius.y) ^ 2
			for z = minp.z, maxp.z do
				local zval = ((z - pos.z) / radius.z) ^ 2
				local dist = math.sqrt(xval + yval + zval)
				local nval = pmap[i]
				if nval > dist then
					local iv = area:index(x, y, z)
					if data[iv] == air or data[iv] == ignore then
						count = count + 1
						if math.random() < fruit_chance then
							data[iv] = fruit
						else
							data[iv] = leaves
						end
					end
				end
				i = i + 1
			end
		end
	end
end

function vmg.test_conditions(conditions, values)
	local checked = 1
	for k, param in pairs(conditions) do
		local value = values[k]
		local p1, p2, p3, p4 = unpack(param)
		if #param == 2 then
			if value < p1 or value > p2 then
				checked = 0
			end
		elseif value < p2 then
			if p1 < p2 then
				checked = checked * (value - p2) / (p2 - p1)
			else
				checked = 0
			end
		elseif value > p3 then
			if p4 > p3 then
				checked = checked * (p4 - value) / (p4 - p3)
			else
				checked = 0
			end
		end
		checked = math.max(checked, 0)
	end
	return checked
end