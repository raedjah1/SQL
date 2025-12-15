-- Check actual columns in vWOHeader
SELECT TOP 1 * FROM pls.vWOHeader 
WHERE ProgramID IN (SELECT ID FROM PLUS.pls.Program WHERE Site = 'MEMPHIS');
