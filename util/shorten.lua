return function(Number)
    if Number == 0 then return "0" end

    local Suffixes = {"", "K", "M", "B", "T", "Q", "QN", "S", "SP", "O", "N", "D", "UD", "DD"}
    local Negative = Number < 0
    Number = math.abs(Number)

    local Index = math.floor(math.log10(Number))
    Index = Index - (Index % 3)

    local Suffix = Suffixes[(Index / 3) + 1] or ""
    local NearestMultiple = 10 ^ Index
    local PrecisionMultiple = 10 ^ 2

    local Result = math.floor((Number / NearestMultiple) * PrecisionMultiple) / PrecisionMultiple .. Suffix
    return Negative and "-" .. Result or Result
end
