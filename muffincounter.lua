_addon.version = '1.1.0'
_addon.name = 'MuffinCounter'
_addon.author = 'DTR'
_addon.commands = {'mc', 'muffincounter'}

texts = require('texts')
packets = require('packets')
require('luau')

-- Display settings
displaySettings = {pos={x=12,y=-3},text={font='YDGothic 110 Pro',size=11},bg={visible=false}}
displayBox = texts.new(displaySettings)
displayBox:show()

-- Track gallimaufry counts
count = {
	['muffins'] = 0,
	['gained_muffins'] = 0,
}

-- Create display template
function makeDisplay()
	local properties = L{}
    properties:append('${muffins}')
    displayBox:clear()
    displayBox:append(properties:concat('\n'))
end

-- Format number with comma separators
function formatNumber(num)
    local formatted = tostring(num)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Update display with current counts
function updateDisplay()
    local info = {}
    local total = formatNumber(count.muffins+count.gained_muffins)
    local gained = formatNumber(count.gained_muffins)
	info.muffins = "\\cs(255,255,255) Gallimaufry ["..total.." (\\cs(0,255,0)+"..gained.."\\cs(255,255,255)\\)]"
    displayBox:update(info)
    displayBox:show()
end

makeDisplay()
updateDisplay()

-- Register event to get total muffin count from packet
windower.register_event('incoming chunk',function(id,original,modified,injected,blocked)
	if id == 0x118 then
        count.muffins = original:byte(145)+256*original:byte(146)+(256*256*original:byte(147))
        updateDisplay()
	end
end)

-- Register event to track gallimaufry gains from incoming text
windower.register_event('incoming text', function(original, modified, mode)
	if string.find(original,"received %d+ gallimaufry for a total of") then
		local gained = tonumber(original:match("%d+"))
		count.gained_muffins = count.gained_muffins + gained
		updateDisplay()
	end
end)

-- Register addon commands for reporting
windower.register_event('addon command',function(...)
    local args = T{...}
    local command
    if args[1] then command = string.lower(args[1]) end
	if command == 'report' then
		windower.add_to_chat(201,"[MuffinCounter] You gained "..count.gained_muffins..' muffins your last run! Tasty.')
	elseif command == 'party' then
		windower.send_command("input /p We gained "..count.gained_muffins..' muffins! Tasty.')
	elseif command == 'reset' then
		windower.send_command('lua r muffincounter')
	end
end)

-- Request muffin count on load
packets.inject(packets.new('outgoing', 0x115))
