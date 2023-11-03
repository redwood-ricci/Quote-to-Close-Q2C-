---------------------------------------------------------------------------------------------------------
--- Title: ORDER DELETE
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  
--- Created Date: 24 October 2023
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
USE SourceQA;

EXEC [SourceQA].dbo.SF_Replicate 'SANDBOX_QA' ,'Order' ,'pkchunk'

---------------------------------------------------------------------------------
--- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Order_DELETE' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.Order_DELETE;

Select  
	ID,
	CAST('' as nvarchar(255)) as Error,
	Order_Migration_id__c,
	CreatedDate as REF_CreatedDate

into StageQA.dbo.Order_DELETE
from  SourceQA.dbo.[Order]
--where CreatedById = ''
--and Order_Migration_id__c not like ''
order by  id


ALTER TABLE StageQA.dbo.Order_DELETE
ADD [Sort] int IDENTITY (1,1)

-- select * from StageQA.dbo.Order_DELETE order by REF_CreatedDate asc 

---------------------------------------------------------------------------------
-- DELETE  -- 
---------------------------------------------------------------------------------
EXEC SF_TableLoader 'Delete','[SANDBOX_QA]','Order_DELETE'

select * 
--into StageQA.dbo.Order_DELETE2
from StageQA.dbo.Order_DELETE_Result
where error not like '%Success%'
-- and error  <> 'UNDELETE_FAILED: Entity is not in the recycle bin'

--EXEC SF_TableLoader 'Delete:batchsize(1)','[SANDBOX_QA]','Order_DELETE2'


---------------------------------------------------------------------------------
-- UNDELETE -- 
-- This is to fix deletions when you mess up
---------------------------------------------------------------------------------

--SELECT ID, createdbyid --Order_Migration_id__c --into Order_Undelete
--  FROM [SANDBOX_QA].[CData].[Salesforce].orderitem_QueryAll WHERE IsDeleted='True'
-- and createdbyid = ''


--EXEC SF_TableLoader 'UnDelete:batchsize(25)','[SANDBOX_QA]','Order_Undelete'

