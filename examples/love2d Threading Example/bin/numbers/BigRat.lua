require( "bin.numbers.BigNum" ) ;

BigRat = {} ;
BigRat.mt = {} ;
function BigRat.new( num1 , num2 ) --{{{2
   local bigrat = {} ;
   local f ;
   setmetatable(bigrat, BigRat.mt) ;
   if type( num1 ) == "table" then
      if num1.num ~= nil and num1.den ~= nil then
         bigrat.num = BigNum.new( num1.num ) ;
         bigrat.den = BigNum.new( num1.den ) ;
      else
         bigrat.num = BigNum.new( num1 ) ;
         bigrat.den = BigNum.new( "1" ) ;
      end
   elseif num1 ~= nil then
      if num2 == nil then
         bigrat.den = BigNum.new( "1" ) ;
      else
         bigrat.den = BigNum.new( num2 ) ;
      end
      bigrat.num = BigNum.new( num1 ) ;
   else
      bigrat.den = BigNum.new( ) ;
      bigrat.num = BigNum.new( ) ;
   end

   --Update the signals
   if bigrat.den.signal == "-" then
      if bigrat.num.signal == "-" then
         bigrat.num.signal = "+" ;
      else
         bigrat.num.signal = "-" ;
      end
      bigrat.den.signal = "+" ;
   end

   return bigrat ;
end

function BigRat.mt.sub( num1 , num2 )
   local temp = BigRat.new() ;
   local brat1 = BigRat.new( num1 ) ;
   local brat2 = BigRat.new( num2 ) ;
   BigRat.sub( brat1 , brat2 , temp ) ;
   return temp ;
end

function BigRat.mt.add( num1 , num2 )
   local temp = BigRat.new() ;
   local brat1 = BigRat.new( num1 ) ;
   local brat2 = BigRat.new( num2 ) ;
   BigRat.add( brat1 , brat2 , temp ) ;
   return temp ;
end

function BigRat.mt.mul( num1 , num2 )
   local temp = BigRat.new() ;
   local brat1 = BigRat.new( num1 ) ;
   local brat2 = BigRat.new( num2 ) ;
   BigRat.mul( brat1 , brat2 , temp ) ;
   return temp ;
end

function BigRat.mt.div( num1 , num2 )
   local brat1 = BigRat.new( num1 ) ;
   local brat2 = BigRat.new( num2 ) ;
   local brat3 = BigRat.new() ;
   local brat4 = BigRat.new() ;
   BigRat.div( brat1 , brat2 , brat3 , brat4 ) ;
   return brat3 , brat4 ;
end

function BigRat.mt.tostring( brat )
   BigRat.simplify( brat ) ;
   return BigNum.mt.tostring( brat.num ) .. " / " .. BigNum.mt.tostring( brat.den ) ;
end

function BigRat.mt.pow ( num1 , num2 )
   local brat1 = BigRat.new( num1 ) ;
   local brat2 = BigRat.new( num2 ) ;
   return BigRat.pow( brat1 , brat2 )
end

function BigRat.mt.eq ( num1 , num2 )
   return BigRat.eq( num1 , num2 )
end

function BigRat.mt.lt ( num1 , num2 )
   return BigRat.lt( num1 , num2 )
end

function BigRat.mt.le ( num1 , num2 )
   return BigRat.le( num1 , num2 )
end

function BigRat.mt.unm ( num )
   local ret = BigRat.new( num )
   if ret.num.signal == '-' then
      ret.num.signal = '+'
   else
      ret.num.signal = '-'
   end
   return ret
end

BigRat.mt.__metatable = "hidden"
BigRat.mt.__tostring  = BigRat.mt.tostring
BigRat.mt.__add = BigRat.mt.add
BigRat.mt.__sub = BigRat.mt.sub
BigRat.mt.__mul = BigRat.mt.mul
BigRat.mt.__div = BigRat.mt.div
BigRat.mt.__pow = BigRat.mt.pow
BigRat.mt.__unm = BigRat.mt.unm
BigRat.mt.__eq = BigRat.mt.eq
BigRat.mt.__le = BigRat.mt.le
BigRat.mt.__lt = BigRat.mt.lt
setmetatable( BigRat.mt, { __index = "inexistent field", __newindex = "not available", __metatable="hidden" } ) ;
function BigRat.add( brat1 , brat2 , brat3 )
   brat3.den = brat1.den * brat2.den ;
   brat3.num = ( brat1.num * brat2.den ) + ( brat2.num * brat1.den ) ;
   return brat3 ;
end
function BigRat.sub( brat1 , brat2 , brat3 )
   brat3.den = brat1.den * brat2.den ;
   brat3.num = ( brat1.num * brat2.den ) - ( brat2.num * brat1.den ) ;
   return brat3 ;
end

function BigRat.mul( brat1 , brat2 , brat3 )
   brat3.num = brat1.num * brat2.num ;
   brat3.den = brat1.den * brat2.den ;
   return 0 ;
end

function BigRat.div( brat1 , brat2 , brat3 )
   brat3.num = brat1.num * brat2.den ;
   brat3.den = brat1.den * brat2.num ;
   return brat3 ;
end

function BigRat.pow( bnum1 , bnum2 )
   if bnum1 == nil or bnum2 == nil then
      error( "Function BigRat.pow: parameter nil" ) ;
   end
   local x = BigRat.new( "8" ) ;
   local n = BigRat.new( bnum2.den ) ;
   local n2 ;
   local y = BigRat.new( ) ;
   local i ;
   local temp = BigRat.new( ) ;

   BigRat.simplify( bnum2 ) ;
   temp.num = BigNum.exp( bnum1.num , bnum2.num ) ;
   temp.den = BigNum.exp( bnum1.den , bnum2.num ) ;
   n2 = n - 1 ;

   for i = 0 , 4 do
      y.num = x.num ^ n2.num ;
      y.den = x.den ^ n2.num ;
      x = (( temp / y ) + ( n2 * x )) / n ;
   end
   return x ;
end

function BigRat.simplify( brat )
   if brat == nil then
      error( "Function BigRat.simplify: parameter nil" ) ;
   end
   local gcd  = BigNum.new( ) ;
   local temp = BigRat.new( brat ) ;
   local devnull = BigNum.new( ) ;
   local zero = BigNum.new( "0" ) ;
   --Check if numerator is zero
   if BigNum.compareAbs( brat.num , zero ) == 0 then
      brat.den = BigNum.new( "1" ) ;
      return 0 ;
   end
   gcd = BigNum.gcd( brat.num , brat.den ) ;
   BigNum.div( temp.num , gcd , brat.num , devnull ) ;
   BigNum.div( temp.den , gcd , brat.den , devnull ) ;
   --Update the signal
   if brat.num.signal == '-' and brat.den.signal == '-' then
      brat.num.signal = '+' ;
      brat.den.signal = '+' ;
   end
   return 0 ;
end

function BigRat.eq( brat1 , brat2 )
   if BigRat.compare( brat1 , brat2 ) == 0 then
      return true ;
   else
      return false ;
   end
end

function BigRat.lt( brat1 , brat2 )
   if BigRat.compare( brat1 , brat2 ) == 2 then
      return true ;
   else
      return false ;
   end
end

function BigRat.le( brat1 , brat2 )
   local temp = -1 ;
   temp = BigRat.compare( brat1 , brat2 )
   if temp == 0 or temp == 2 then
      return true ;
   else
      return false ;
   end
end

function BigRat.compare( bnum1 , bnum2 )
   local temp ;
   temp = bnum1 - bnum2 ;
   if temp.num[0] == 0 and temp.num.len == 1 then --Check if is zero
      return 0 ;
   elseif temp.num.signal == "-" then
      return 2 ;
   else
      return 1 ;
   end
end
