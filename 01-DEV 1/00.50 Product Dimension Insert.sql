---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Dimensions Insert
--- Customer: Redwood
--- Primary Developer: Ajay Santhosh
--- Secondary Developers:  
--- Created Date: 20/11/2023
--- Last Updated: 
--- Change Log: 
--- 	
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE SourceNeocol

EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','Product2','PKCHUNK'
EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL','SBQQ__Dimension__c','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Dimension__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[SBQQ__Dimension__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	CAST('' AS nvarchar(18)) AS [ID] 
	,Prod.Id as SBQQ__Product__c
	,D.Id as ExternalId
	,D.CurrencyIsoCode as CurrencyIsoCode
	,CAST('' as nvarchar(2000)) as Error

INTO StageQA.dbo.SBQQ__Dimension__c_Load

FROM SourceNeocol.dbo.SBQQ__Dimension__c D
	 inner join StageQA.dbo.Product2_Load_Result Prod
		on Prod.ExternalId = D.SBQQ__Product__c

WHERE --Prod.CreatedDate >= DATEADD(day,-90, GETDATE())
	 Prod.IsActive = 'true'
	and Prod.Name not in ('Test Bundle', 'Test Product')
	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from StageQA.dbo.SBQQ__Dimension__c_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(100)','SANDBOX_QA','SBQQ__Dimension__c_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
Select error, count(*) as num from SBQQ__Dimension__c_Load_Result a
where error not like '%success%'
group by error
order by num desc
