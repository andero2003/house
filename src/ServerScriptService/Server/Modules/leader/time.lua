local tlib = {}

function tlib.GetUTC(offset)
	if not offset then offset = 0 end
	
	--offset = offset + 24 * 60 * 60 + 45 * 60 + 12 * 60 * 60 - 5 * 60
	
	return os.time() + offset
end

function OO(x)
	return string.format("%02i", x)
end

function tlib.GetReplay24Date()
	local utc = tlib.GetUTC()
	local today = tlib.GetDate(utc)
	return today, utc
end

function tlib.GetReplayWDate()
	local utc = tlib.GetUTC() + 3 * 24 * 60 * 60
	utc = utc/7
	local today = tlib.GetDate(utc)
	return today, utc
end

function tlib.timeformat(sec)
	sec = math.floor(sec)
	local m = sec/60
	m = m - m % 1
	sec = sec - m * 60
	
	local h = m / 60
	h = h - h%1
	m = m - h * 60
	
	local d = h/24
	d = d - d%1
	h = h - d * 24
	
	if d > 0 then
		return tostring(d)..":"..OO(h)..":"..OO(m)..":"..OO(sec)
	end
	
	if h > 0 then
		return OO(h)..":"..OO(m)..":"..OO(sec)
	end
	
	if m > 0 then
		return OO(m)..":"..OO(sec)
	end
	
	return OO(sec)
end

function tlib.GetSecondsUntilMidnight(tik, playerTimeOffset, timeOffset)
	if not tik then tik = tlib.GetUTC() end
	if playerTimeOffset then
		tik = tik + playerTimeOffset
	end

	local date = os.date("!*t" , tik)
	local h = date.hour
	local m = date.min
	local s = date.sec
	
	if timeOffset then
		local timenow = s + m * 60 + h * 3600
		if timenow <= timeOffset then
			return timeOffset - timenow
		end
	end
	
	--print("TIME NOW:",h,m,s)
	local secLeft = 60 - s
	local minLeft = 60 - (m+1)
	local hLeft = 24 - (h + 1)
	
	local tickAtMidnight = tik + secLeft + minLeft * 60 + hLeft * 3600
	if timeOffset then
		tickAtMidnight = tickAtMidnight + timeOffset
	end
	--print("TIME LEFT:",hLeft,minLeft,secLeft)
	
	return tickAtMidnight - tik
end

function tlib.GetDate(tik, offset)
	if not tik then tik = tlib.GetUTC() end
	if offset then
		tik = tik + offset
	end
	local date = os.date("!*t" , tik)
	local formatted = date["month"].."."..date["day"].."."..date["year"]
	return formatted
end

return tlib