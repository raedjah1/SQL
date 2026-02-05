-- All distinct warehouses for ADT (ProgramID 10068)
SELECT DISTINCT Warehouse
FROM Plus.pls.PartLocation
WHERE ProgramID = 10068
  AND Warehouse IS NOT NULL
  AND Warehouse != ''
ORDER BY Warehouse;








