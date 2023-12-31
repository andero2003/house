local Semaphore = {}
Semaphore.__index = Semaphore

function Semaphore.new(limit)
	local self = setmetatable({}, Semaphore)
	self.limit = limit or 1
	self.count = 0
	return self
end

function Semaphore:acquire()
	while self.count >= self.limit do
		warn('Waiting to acquire semaphore...')
		wait() 
	end
	self.count = self.count + 1
end

function Semaphore:release()
	self.count = self.count - 1
end

return Semaphore