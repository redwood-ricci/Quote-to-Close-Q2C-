---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Order ACTIVATION
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  Jim Ziller
--- Created Date: 10/6/2023
--- Last Deleted: 
--- Change Log: 
--- Prerequisites:
--- 1. 1.10 Order
--- 2. 1.20 Order Item
--- 3. 1.30 Contract
--- 4. 1.40 Subscription
--- 5. 2.10 Order Update
--- 6. 2.20 OrderItem Update
--- 7. 2.30 Contract Activate Update
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

USE SourceQA;

---------------------------------------------------------------------------------
--- COPY DATA FROM SALESFORCE
---------------------------------------------------------------------------------

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Order','PkChunk'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbqq__Quote__c','PKCHUNK'

---------------------------------------------------------------------------------
--- Drop Staging Table
---------------------------------------------------------------------------------
USE [StageQA]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Order_UPDATE]') AND type in (N'U'))
DROP TABLE [StageQA].[dbo].[Order_UPDATE]
GO

---------------------------------------------------------------------------------
--- Create Staging Table
---------------------------------------------------------------------------------
SELECT  
	O.ID as Id,
	CAST('' AS nvarchar(255)) AS Error,
	'Activated' as [Status],
	coalesce(Qte.SBQQ__ContractingMethod__c, 'Single Contract') as SBQQ__ContractingMethod__c 

into StageQA.dbo.Order_UPDATE
FROM  SourceQA.dbo.[Order] O
left join SourceQA.dbo.SBQQ__Quote__c Qte
	on Qte.Id = O.SBQQ__Quote__c
WHERE O.Order_Migration_id__c IS NOT NULL
	and O.Status != 'Activated'



---------------------------------------------------------------------------------
-- ADD sort column to speed bulk load performance If Necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.Order_UPDATE
ADD [Sort] int IDENTITY (1,1)


select * from StageQA.dbo.Order_UPDATE
---------------------------------------------------------------------------------
-- Load Subscription Data To Full Sandbox -- 
---------------------------------------------------------------------------------
EXEC StageQA.dbo.SF_TableLoader 'UPDATE:bulkapi,batchsize(3)','SANDBOX_QA','Order_UPDATE'
---------------------------------------------------------------------------------
--- ERROR REVIEW
---------------------------------------------------------------------------------
Select * from StageQA.dbo.Order_UPDATE_Result where error not like '%Success%'
---------- ^^^^^^^^^^^^^^^ Error sheet https://docs.google.com/spreadsheets/d/13RQYid_LLjGiN16ICKbkwITOvvmd_9LWBcYWktStsn4/edit#gid=528366776
-- Only 15 failed, the same 15 that did not get order items uploaded

Select error, count(*)
from StageQA.dbo.Order_UPDATE_Result
where error not like '%Success%'
group by error



Select *
from Order_UPDATE_Result
where error not like '%Success%'
