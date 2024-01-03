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
USE SourceQA

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Product2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','SBQQ__Dimension__c','PKCHUNK'

USE [Source_Production_SALESFORCE];

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Product2','PKCHUNK'
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Dimension__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[SBQQ__Dimension__c_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	CAST('' AS nvarchar(18)) AS [ID] 
	,D.Id as External_Id__c
	,Prod.Id as SBQQ__Product__c
	,D.CurrencyIsoCode as CurrencyIsoCode
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.SBQQ__Dimension__c_Load

FROM SourceQA.dbo.SBQQ__Dimension__c D
	 inner join Source_Production_SALESFORCE.dbo.Product2 Prod
		on Prod.External_Id__c = D.SBQQ__Product__c
	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.SBQQ__Dimension__c_Load where SBQQ__Product__c is not null

Select * from Source_Production_SALESFORCE.dbo.Product2
---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(100)','Production_SALESFORCE','SBQQ__Dimension__c_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
Select error, count(*) as num from SBQQ__Dimension__c_Load_Result a
where error not like '%success%'
group by error
order by num desc



USE SourceQA

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','SBQQ__BlockPrice__c','PKCHUNK'

USE [Source_Production_SALESFORCE];

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__BlockPrice__c','PKCHUNK'

USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__BlockPrice__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.SBQQ__BlockPrice__c_Load

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	CAST('' AS nvarchar(18)) AS [ID] 
	,BP.Name as Name
	,BP.OverageRate__c as OverageRate__c
	,BP.SBQQ__LowerBound__c as SBQQ__LowerBound__c
	,BP.SBQQ__Price__c as SBQQ__Price__c
	,PB.Id as SBQQ__PriceBook2__c
	,BP.SBQQ__UpperBound__c as SBQQ__UpperBound__c
	,Prod.Id as SBQQ__Product__c
	,BP.External_Id__c as External_Id__c
	,CAST('' as nvarchar(2000)) as Error

INTO Stage_Production_SALESFORCE.dbo.SBQQ__BlockPrice__c_Load

FROM SourceQA.dbo.SBQQ__BlockPrice__c BP
	 inner join Source_Production_SALESFORCE.dbo.Product2 Prod
		on Prod.External_Id__c = BP.SBQQ__Product__c
	inner join Source_Production_SALESFORCE.dbo.Pricebook2 PB
		on PB.External_Id__c = BP.SBQQ__PriceBook2__c
	
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.SBQQ__Dimension__c_Load where SBQQ__Product__c is not null

Select * from Stage_Production_SALESFORCE.dbo.SBQQ__BlockPrice__c_Load
---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(100)','Production_SALESFORCE','SBQQ__BlockPrice__c_Load'