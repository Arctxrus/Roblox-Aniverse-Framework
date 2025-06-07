local SplineUtils = {}

function SplineUtils.catmullRom(p0, p1, p2, p3, t)
	local t2 = t * t
	local t3 = t2 * t
	return 0.5 * (
		(2 * p1) +
			(-p0 + p2) * t +
			(2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
			(-p0 + 3 * p1 - 3 * p2 + p3) * t3
	)
end

function SplineUtils.estimateSegmentLength(p0, p1, p2, p3, segments)
	local length = 0
	local previousPoint = p1

	for i = 1, segments do
		local t = i / segments
		local currentPoint = SplineUtils.catmullRom(p0, p1, p2, p3, t)
		length = length + (currentPoint - previousPoint).Magnitude
		previousPoint = currentPoint
	end

	return length
end

function SplineUtils.computeCumulativeLengths(waypoints, segments)
	local lengths = {0}
	local totalLength = 0

	for i = 1, #waypoints - 3 do
		local segmentLength = SplineUtils.estimateSegmentLength(waypoints[i], waypoints[i + 1], waypoints[i + 2], waypoints[i + 3], segments)
		totalLength = totalLength + segmentLength
		table.insert(lengths, totalLength)
	end

	return lengths, totalLength
end

function SplineUtils.getPositionAtDistance(waypoints, lengths, distance)
	for i = 1, #lengths - 1 do
		if distance >= lengths[i] and distance <= lengths[i + 1] then
			local segmentStartDistance = lengths[i]
			local segmentEndDistance = lengths[i + 1]
			local segmentDistance = segmentEndDistance - segmentStartDistance
			local t = (distance - segmentStartDistance) / segmentDistance
			return SplineUtils.catmullRom(waypoints[i], waypoints[i + 1], waypoints[i + 2], waypoints[i + 3], t)
		end
	end
	return waypoints[#waypoints]
end

function SplineUtils.resampleSpline(waypoints, segments, sampleRate)
	local resampledPoints = {}
	local lengths, totalLength = SplineUtils.computeCumulativeLengths(waypoints, segments)

	local stepSize = totalLength / sampleRate
	for i = 0, sampleRate do
		local distance = i * stepSize
		local position = SplineUtils.getPositionAtDistance(waypoints, lengths, distance)
		table.insert(resampledPoints, position)
	end

	return resampledPoints
end

return SplineUtils
