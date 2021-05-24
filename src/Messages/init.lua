local Messages = {}

for _,messages in ipairs(script:GetChildren()) do
    table.insert(Messages, require(messages))
end

return Messages