local GLOBAL, THREAD = require("multi.integration.loveManager.threads"):init()


return {
    init = function(global_channel, console_channel, status_channel)
        return GLOBAL, THREAD
    end
}
