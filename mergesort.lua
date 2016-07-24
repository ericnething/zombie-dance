local M = {}

function M.mergesort (array, compare)
   compare = compare or function(a,b) return a < b end
   local subarrays = {}

   for i=1, #array do
      table.insert (subarrays, {array[i]})
   end

   local function go (xs, cmp)
      if #xs == 1 then return xs[1] end
      local temp = {}
      
      for i=1, #xs, 2 do
         if xs[i+1] then
            table.insert (temp, merge (xs[i], xs[i+1], cmp))
         else
            table.insert (temp, xs[i])
         end
      end
      return go (temp, cmp)
   end

   return go (subarrays, compare)
   
end

function merge (xs, ys, compare)
   local result = {}
   local i_x, i_y = 1, 1
   while not (i_x > #xs and i_y > #ys) do

      if i_x > #xs then
         for i=i_y, #ys do table.insert (result, ys[i]) end
         break
      end
      
      if i_y > #ys then
         for i=i_x, #xs do table.insert (result, xs[i]) end
         break
      end
      
      if compare (xs[i_x], ys[i_y]) then
         table.insert (result, xs[i_x])
         i_x = i_x + 1
      else
         table.insert (result, ys[i_y])
         i_y = i_y + 1
      end
   end
   return result
end

function printArray (array)
   for i,v in ipairs (array) do
      print (i, v)
   end
end

return M
