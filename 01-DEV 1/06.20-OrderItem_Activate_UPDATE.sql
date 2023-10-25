---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: OrderItem HOUSEKEEPING script to activate orderitem rows that native functionality failed to activate when the parent activated
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  Jim Ziller
--- Created Date: 10/6/2024
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. Order Activation Step
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Looks at Order and if the order got set to activated, we update the lines


USE SourceQA;

---------------------------------------------------------------------------------
--- COPY DATA FROM SALESFORCE
---------------------------------------------------------------------------------
EXEC [SourceQA].dbo.SF_Replicate 'SANDBOX_QA', 'Order', 'PkChunk'
EXEC [SourceQA].dbo.SF_Replicate 'SANDBOX_QA', 'OrderItem', 'PkChunk'

---------------------------------------------------------------------------------
--- Drop Staging Table
---------------------------------------------------------------------------------
USE [StageQA];

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OrderItem_Activate_UPDATE' AND TABLE_SCHEMA = 'dbo')
DROP TABLE OrderItem_Activate_UPDATE;

select OI.ID
	,CAST('' AS nvarchar(2000)) AS Error
	,'true' as SBQQ__Activated__c
	,'Activated' as SBQQ__Status__c

	,OI.OrderID as REF_OrderID
	,OI.OrderItem_Migration_id__c as REF_MigratedID
	,O.[Status] as REF_OrderStatus

into [StageQA].dbo.OrderItem_Activate_UPDATE

from [SourceQA].dbo.[OrderItem] OI
Left Join [SourceQA].dbo.[Order] O
	on OI.OrderId  =  O.Id
where O.Order_Migration_id__c is not null
and  O.Status = 'Activated' -- When we activate the order, automation is not kicking in and activating the associated lines
and OI.SBQQ__Status__c = 'Draft'

---------------------------------------------------------------------------------
-- ADD sort column to speed bulk load performance If Necessary
---------------------------------------------------------------------------------
ALTER TABLE [StageQA].dbo.OrderItem_Activate_UPDATE
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_OrderID) AS OrderRowNumber
  FROM [StageQA].dbo.OrderItem_Activate_UPDATE
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;

---------------------------------------------------------------------------------
-- Load Subscription Data To Full Sandbox -- 
---------------------------------------------------------------------------------
EXEC [StageQA].dbo.SF_TableLoader 'UPDATE','SANDBOX_QA','OrderItem_Activate_UPDATE' 


---------------------------------------------------------------------------------
--- ERROR REVIEW
-----------------------------------------------------------------------------------
Select * 
from [StageQA].dbo.OrderItem_Activate_UPDATE_Result
where error not like '%Success%'


