function Test(multi, thread, t)
    multi.print("Testing Connection operators")

    do
        multi.print("Testing: conn1 + conn2")
        local conn1 = multi:newConnection()
        local conn2 = multi:newConnection()
        local conn3 = conn1 + conn2
        local count = 0
        
        conn3(function()
            count = count + 1
        end)

        conn1:Fire()
        t.Equal(1, count)
        conn2:Fire()
        t.Equal(2, count)
    end

    do
        multi.print("Testing: conn1 * conn2")
        local conn1 = multi:newConnection()
        local conn2 = multi:newConnection()
        local conn3 = conn1 * conn2
        local count = 0

        conn3(function()
            count = count + 1
        end)

        conn1:Fire()
        t.Equal(0, count)
        conn2:Fire()
        t.Equal(1, count)
    end

    do
        multi.print("Testing: conn .. function")
        local called = false
        local conn1 = multi:newConnection()
        local conn2 = conn1 .. function() called = true end

        conn1(function()
            t.False(called)
        end)

        conn2:Fire()
        t.True(called)
    end

    do
        multi.print("function .. conn")
        local status = false
        local conn1 = multi:newConnection()
        local conn2 = function(test) return test end .. conn1

        conn1(function()
            status = true
        end)

        conn2:Fire(false)
        t.False(status)
        conn2:Fire(true)
        t.True(status)
    end
end

return {
    Test = Test
}