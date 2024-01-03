---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Account UPDATE Script	
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  Jim Ziller
--- Created Date: 10/11/2023
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
USE [Source_Production_SALESFORCE];

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Product2','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'PriceBook2','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'PriceBookEntry','PKCHUNK'

USE SourceQA

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Product2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBook2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBookEntry','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'PriceBookEntry_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[PriceBookEntry_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

Select
	--CAST('' AS nvarchar(18)) AS [ID] 
	coalesce(ProdPBE.Id, '') AS [ID]
	,PBE.Id as External_Id__c
	,PBE.Product2Id as QAProductId
	,QAProduct.Name as QAProductName
	,Prod.Id as Product2Id
	,PBE.IsActive as IsActive
	,coalesce(PB.Id, '01s50000000EG0SAAW') as PriceBook2Id
	,PBE.UnitPrice as UnitPrice
	,PBE.CurrencyIsoCode as CurrencyIsoCode
	,CAST('' as nvarchar(2000)) as Error
	,Prod.Name as ProdName
	,coalesce(PB.Name, 'Standard Price Book') as PBName

INTO Stage_Production_SALESFORCE.dbo.PriceBookEntry_Load

FROM SourceQA.dbo.PriceBookEntry PBE
	left join Source_Production_SALESFORCE.dbo.PriceBookEntry ProdPBE
		on ProdPBE.External_Id__c = PBE.External_Id__c
	left join SourceQA.dbo.Product2 QAProduct
		on QAProduct.Id = PBE.Product2Id
	left join Source_Production_SALESFORCE.dbo.Product2 Prod
		on Prod.External_Id__c = PBE.Product2Id
	left join Source_Production_SALESFORCE.dbo.Pricebook2 PB
		on PB.External_Id__c = PBE.Pricebook2Id
--WHERE PB.Name LIKE '%Redwood% 2024%' 

Order by PB.Id asc

---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.PriceBookEntry_Load where Product2Id is null
Select * from Source_Production_SALESFORCE.dbo.Product2 where External_Id__c  ='01uO90000000yQoIAI'

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(100)','Production_SALESFORCE','PriceBookEntry_Load' -- first run will fail because it will only insert the standard pricebook items and then rerun to insert the rest.

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

Select error, * from Stage_Production_SALESFORCE.dbo.PriceBookEntry_Load_Result a where error not like '%success%' and error not like '%DUPLICATE_VALUE%' and error not like '%FIELD_INTEGRITY_EXCEPTION:This price definition already exists in this price book%'