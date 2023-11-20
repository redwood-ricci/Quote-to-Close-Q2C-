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
USE SourceNeocol

EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL', 'Product2','PKCHUNK'
EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL', 'PriceBook2','PKCHUNK'
EXEC SourceNeocol.dbo.SF_Replicate 'SANDBOX_NEOCOL', 'PriceBookEntry','PKCHUNK'

USE SourceQA

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Product2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBook2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBookEntry','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'PriceBookEntry_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[PriceBookEntry_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE StageQA;

Select
	CAST('' AS nvarchar(18)) AS [ID] 
	,P.Id as Product2Id
	,PBE.IsActive as IsActive
	,coalesce(PB.Id, '01s50000000EG0SAAW') as PriceBook2Id
	,PBE.UnitPrice as UnitPrice
	,PBE.CurrencyIsoCode as CurrencyIsoCode
	,CAST('' as nvarchar(2000)) as Error
	,P.Name as ProdName
	,coalesce(PB.Name, 'Standard Price Book') as PBName

INTO StageQA.dbo.PriceBookEntry_Load

FROM SourceNeocol.dbo.PriceBookEntry PBE
	inner join SourceQA.dbo.Product2 p
		on p.ExternalId = PBE.Product2Id
	left join StageQA.dbo.Pricebook2_Load_Result PB
		on PB.ExternalId = PBE.Pricebook2Id
--WHERE PB.Name LIKE '%Redwood% 2024%' 

Order by PB.Id asc

---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from StageQA.dbo.PriceBookEntry_Load


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(100)','SANDBOX_QA','PriceBookEntry_Load' -- first run will fail because it will only insert the standard pricebook items and then rerun to insert the rest.

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from StageQA.dbo.Account_Load_Result a where error not like '%success%'
