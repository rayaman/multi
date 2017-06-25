require("net.identity")
net:registerModule("email",{1,0,0})
smtp = require 'socket.smtp'
ssl = require 'ssl'

function net.email.init(from,user,pass)
	net.OnServerCreated:connect(function(s)
		s.from=from
		s.user=user
		s.pass=pass
		function s:sendMessage(subject, body, dTable)
			local msg = {
				headers = {
					from = '<'..dTable.email..'>'
					to = dTable.nick..' <'..dTable.email..'>',
					subject = subject
				},
				body = body
			}
			local ok, err = smtp.send {
				from = '<'..self.from..'>',
				rcpt = '<'..dTable.email..'>',
				source = smtp.message(msg),
				user = self.user,
				password = self.pass,
				server = 'smtp.gmail.com',
				port = 465,
				create = net.sslCreate
			}
			if not ok then
				print("Mail send failed", err) -- better error handling required
			end
		end
	end)
end
function net.sslCreate()
    local sock = socket.tcp()
    return setmetatable({
        connect = function(_, host, port)
            local r, e = sock:connect(host, port)
            if not r then return r, e end
            sock = ssl.wrap(sock, {mode='client', protocol='tlsv1'})
            return sock:dohandshake()
        end
    }, {
        __index = function(t,n)
            return function(_, ...)
                return sock[n](sock, ...)
            end
        end
    })
end

