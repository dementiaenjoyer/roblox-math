local math = math;

--[[
	lua-polynomials is a Lua module created by piqey
	(John Kushmer) for finding the roots of second-,
	third- and fourth- degree polynomials.
--]]

--[[
	Just decorating our package for any programmers
	that might possibly be snooping around in here;
	you know, trying to understand and harness the
	potential of all the black magic that's been
	packed in here (you can thank Cardano's formula
	and Ferrari's method for all of that).
--]]

__VERSION = "1.0.0"; -- https://semver.org/
__DESCRIPTION = "Methods for finding the roots of traditional- and higher-degree polynomials (2nd to 4th).";
__URL = "https://github.com/piqey/lua-polynomials";
__LICENSE = "GNU General Public License, version 3";

local eps = 1e-9;
local function is_zero(d)
	return (d > -eps and d < eps);
end

local function cuberoot(x)
	return (x > 0) and math.pow(x, (1 / 3)) or -math.pow(math.abs(x), (1 / 3));
end

local function solve_quadric(c0, c1, c2)
	local s0, s1;

	local p, q, d;

	p = c1 / (2 * c0);
	q = c2 / c0;
	d = p * p - q;

	if is_zero(d) then
		s0 = -p;
		return s0;
	elseif (d < 0) then
		return;
	else -- if (d > 0)
		local sqrt_d = math.sqrt(d);

		s0 = sqrt_d - p;
		s1 = -sqrt_d - p;
		return s0, s1;
	end
end

local function solve_cubic(c0, c1, c2, c3)
	local s0, s1, s2;

	local num, sub;
	local a, b, c;
	local sq_a, p, q;
	local cb_p, d;

	a = c1 / c0;
	b = c2 / c0;
	c = c3 / c0;

	sq_a = a * a;
	p = (1 / 3) * (-(1 / 3) * sq_a + b);
	q = 0.5 * ((2 / 27) * a * sq_a - (1 / 3) * a * b + c);

	cb_p = p * p * p;
	d = q * q + cb_p;

	if is_zero(d) then
		if is_zero(q) then -- one triple solution
			s0 = 0;
			num = 1;
		else -- one single and one double solution
			local u = cuberoot(-q);
			s0 = 2 * u;
			s1 = -u;
			num = 2;
		end
	elseif (d < 0) then -- Casus irreducibilis: three real solutions
		local phi = (1 / 3) * math.acos(-q / math.sqrt(-cb_p));
		local t = 2 * math.sqrt(-p);

		s0 = t * math.cos(phi);
		s1 = -t * math.cos(phi + math.pi / 3);
		s2 = -t * math.cos(phi - math.pi / 3);
		num = 3;
	else -- one real solution
		local sqrt_d = math.sqrt(d);
		local u = cuberoot(sqrt_d - q);
		local v = -cuberoot(sqrt_d + q);

		s0 = u + v;
		num = 1;
	end

	sub = (1 / 3) * a;

	if (num > 0) then s0 = s0 - sub; end
	if (num > 1) then s1 = s1 - sub; end
	if (num > 2) then s2 = s2 - sub; end

	return s0, s1, s2;
end

local module = {};

function module.solve_quartic(c0, c1, c2, c3, c4)
	local s0, s1, s2, s3;

	local coeffs = {};
	local z, u, v, sub;
	local a, b, c, d;
	local sq_a, p, q, r;
	local num;

	a = c1 / c0;
	b = c2 / c0;
	c = c3 / c0;
	d = c4 / c0;

	sq_a = a * a;
	p = -0.375 * sq_a + b;
	q = 0.125 * sq_a * a - 0.5 * a * b + c;
	r = -(3 / 256) * sq_a * sq_a + 0.0625 * sq_a * b - 0.25 * a * c + d;

	if is_zero(r) then
		coeffs[3] = q;
		coeffs[2] = p;
		coeffs[1] = 0;
		coeffs[0] = 1;

		local results = {solve_cubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])};
		num = #results;
		s0, s1, s2 = results[1], results[2], results[3];
	else
		coeffs[3] = 0.5 * r * p - 0.125 * q * q;
		coeffs[2] = -r;
		coeffs[1] = -0.5 * p;
		coeffs[0] = 1;

		s0, s1, s2 = solve_cubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3]);
		z = s0;

		u = z * z - r;
		v = 2 * z - p;

		if is_zero(u) then
			u = 0;
		elseif (u > 0) then
			u = math.sqrt(u);
		else
			return;
		end
		if is_zero(v) then
			v = 0;
		elseif (v > 0) then
			v = math.sqrt(v);
		else
			return;
		end

		coeffs[2] = z - u;
		coeffs[1] = q < 0 and -v or v;
		coeffs[0] = 1;

		do
			local results = {solve_quadric(coeffs[0], coeffs[1], coeffs[2])};
			num = #results;
			s0, s1 = results[1], results[2];
		end

		coeffs[2] = z + u;
		coeffs[1] = q < 0 and v or -v;
		coeffs[0] = 1;

		if (num == 0) then
			local results = {solve_quadric(coeffs[0], coeffs[1], coeffs[2])};
			num = num + #results;
			s0, s1 = results[1], results[2];
		end
		if (num == 1) then
			local results = {solve_quadric(coeffs[0], coeffs[1], coeffs[2])};
			num = num + #results;
			s1, s2 = results[1], results[2];
		end
		if (num == 2) then
			local results = {solve_quadric(coeffs[0], coeffs[1], coeffs[2])};
			num = num + #results;
			s2, s3 = results[1], results[2];
		end
	end

	sub = 0.25 * a;

	if (num > 0) then s0 = s0 - sub; end
	if (num > 1) then s1 = s1 - sub; end
	if (num > 2) then s2 = s2 - sub; end
	if (num > 3) then s3 = s3 - sub; end

	return {s3, s2, s1, s0};
end

return module;
