---------------------------------------------------------------------------------------------------------
--- Title: OrderItem Update Bundle Links
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  
--- Created Date: 27 October 2023
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
USE SourceQA;

EXEC [SourceQA].dbo.SF_Replicate 'SANDBOX_QA','OrderItem','pkchunk'

---------------------------------------------------------------------------------
--- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OrderItem_Bundle_update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.OrderItem_Bundle_update;


With Parent_Sub as (
Select *
from sourceQA.[dbo].[sbqq__Subscription__c] S 
inner join SourceQA.dbo.[Contract] Con
	on Sub.SBQQ__Contract__c = Con.ID


inner join sourceQA.[dbo].[OrderItem] OI
	on  S.ID = OI.Order_Item_Migration_Id__c

where S.ID = S.SBQQ__RootId__c -- This is the parent and everything ties to it
and SBQQ__RequiredById__c is NULL
and SBQQ__Bundle__c = 1
and SBQQ__Contract__c = '8003t000008aTdTAAU'
and Con.EndDate >= getdate()
and Con.Status = 'Activated'
-- Update this if the filters change in 04.50 script
)

-- These are the children to the bundle
Select 
	Par.ID 
	,CAST('' as nvarchar(2000)) as Error

	/* Two bundle related Product Option Lookup fields to link to other Product options at the bundle level (parent)*/
	,Par.OrderItemID as SBQQ__RequiredBy__c 
	,Par.OrderItemID as SBQQ__BundleRoot__c
	--, Child.*

--into StageQA.dbo.OrderItem_Bundle_update
from sourceQA.[dbo].[sbqq__Subscription__c] Child 
inner join SourceQA.dbo.[Contract] Con
	on Sub.SBQQ__Contract__c = Con.ID

inner join sourceQA.[dbo].[OrderItem] OI
	on  S.ID = OI.Order_Item_Migration_Id__c
inner join Parent_Sub Par
	on Child.SBQQ__RequiredById__c = Par.ID

where Child.ID != Child.SBQQ__RootId__c -- This is the parent and everything ties to it
and Child.SBQQ__RequiredById__c is not NULL

and Con.EndDate >= getdate()
and Con.Status = 'Activated'
-- Update this if the filters change in 04.50 script