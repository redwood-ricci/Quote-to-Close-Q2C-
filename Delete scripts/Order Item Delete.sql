---------------------------------------------------------------------------------------------------------
--- Title: OrderItem DELETE
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

EXEC [SourceQA].dbo.SF_Replicate 'SANDBOX_QA' ,'OrderItem' ,'pkchunk'

---------------------------------------------------------------------------------
--- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OrderItem_DELETE' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.OrderItem_DELETE;

Select  
	ID,
	CAST('' as nvarchar(255)) as Error,
	Order_Item_Migration_id__c,
	CreatedDate as REF_CreatedDate

into StageQA.dbo.OrderItem_DELETE
from  SourceQA.dbo.[OrderItem]
--where CreatedById = ''
--and Order_Item_Migration_id__c not like ''
OrderItem by  id


ALTER TABLE StageQA.dbo.OrderItem_DELETE
ADD [Sort] int IDENTITY (1,1)

-- select * from StageQA.dbo.OrderItem_DELETE OrderItem by REF_CreatedDate asc 

---------------------------------------------------------------------------------
-- DELETE  -- 
---------------------------------------------------------------------------------
EXEC SF_TableLoader 'Delete','[SANDBOX_QA]','OrderItem_DELETE'

select * 
--into StageQA.dbo.OrderItem_DELETE2
from StageQA.dbo.OrderItem_DELETE_Result
where error not like '%Success%'
and error  <> 'UNDELETE_FAILED: Entity is not in the recycle bin'

--EXEC SF_TableLoader 'Delete:batchsize(1)','[SANDBOX_QA]','OrderItem_DELETE2'


---------------------------------------------------------------------------------
-- UNDELETE -- 
-- This is to fix deletions when you mess up
---------------------------------------------------------------------------------

--SELECT ID, createdbyid --OrderItem_Migration_id__c --into OrderItem_Undelete
--  FROM [SANDBOX_QA].[CData].[Salesforce].OrderItemitem_QueryAll WHERE IsDeleted='True'
-- and createdbyid = ''


--EXEC SF_TableLoader 'UnDelete:batchsize(25)','[SANDBOX_QA]','OrderItem_Undelete'