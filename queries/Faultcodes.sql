SELECT *

FROM pls.PartSerial ps

JOIN pls.WOHeader wh ON wh.ID = ps.WOHeaderID

JOIN pls.WOLine wl ON wl.WOHeaderID = wh.ID

JOIN pls.WOUnit wu ON wu.WOLineID = wl.ID

JOIN pls.WOUnitCodes uc ON uc.WOUnitID = wu.ID

JOIN pls.CodeFault cf ON cf.ID = uc.FaultID

WHERE ps.ProgramID = 10053


