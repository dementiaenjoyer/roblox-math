local _math = {};
local pi = 3.1415926535897931;

_math.to_orientation = function(origin_position: Vector3, end_position: Vector3): Vector3
	local direction = (end_position - origin_position).Unit;
	local pitch = (math.atan2(end_position.Y - origin_position.Y, math.sqrt((end_position.X - origin_position.X) ^ 2) + (end_position.Z - origin_position.Z) ^ 2));
	local yaw = math.atan2(-direction.X, -direction.Z);

	return Vector3.new(math.deg(pitch), math.deg(yaw), 0); -- pitch, yaw
end

_math.calculate_vertices = function(offset: Vector3, root: number): any
	local vertices = {};
	if (not root) then
		root = 4;
	end

	for t = 0, pi, (pi / root) do
		for p = 0, (2 * pi), root do
			table.insert(vertices, Vector3.new(math.sin(t) * math.cos(p) * offset.X, (math.cos(t) * offset.Y), math.sin(t) * math.sin(p) * offset.Z));
		end
	end

	return vertices;
end

return _math;
