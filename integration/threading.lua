-- We need to detect what enviroment we are running our code in.
return {
    init = function()
        if love then
            return require("multi.integration.loveManager"):init()
        else
            if pcall(require,"lanes") then
                return require("multi.integration.lanesManager"):init()
            end
            return require("multi.integration.pesudoManager"):init()
        end
    end
}