local _math = {};

_math.to_orientation = function(origin_position: Vector3, end_position: Vector3): Vector3
	local direction = (end_position - origin_position).Unit;
	local pitch = (math.atan2(end_position.Y - origin_position.Y, math.sqrt((end_position.X - origin_position.X) ^ 2) + (end_position.Z - origin_position.Z) ^ 2));
	local yaw = math.atan2(-direction.X, -direction.Z);

	return Vector3.new(math.deg(pitch), math.deg(yaw), 0); -- pitch, yaw
end

return _math;
