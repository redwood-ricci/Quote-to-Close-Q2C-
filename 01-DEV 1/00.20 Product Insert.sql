---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Product Insert
--- Customer: Redwood
--- Primary Developer: Ajay Santhosh
--- Secondary Developers:  
--- Created Date: 17/11/2023
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

USE [Source_Production_SALESFORCE];

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Product2','PKCHUNK'
---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Product2_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[Product2_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	Prod.*
	,Coalesce(Prod_Prod.Id, Prod.Id) as ProdId
	,RenewalProd.Id as RenewalProductId
	,Prod_Prod.Id as ProductionProductId
	,CAST('' as nvarchar(2000)) as Error
	--,Prod.Id as External_Id__c

INTO Stage_Production_SALESFORCE.dbo.Product2_Load

FROM SourceQA.dbo.Product2 Prod
	left join Source_Production_SALESFORCE.dbo.Product2 Prod_Prod
		on Prod.Id = Prod_Prod.Id
	left join Source_Production_SALESFORCE.dbo.Product2 RenewalProd
		on RenewalProd.External_Id__c = Prod.SBQQ__RenewalProduct__c 
	
---------------------------------------------------------------------------------
--Drop Id from the Column
ALTER TABLE Stage_Production_SALESFORCE.dbo.Product2_Load
DROP COLUMN Id, ExternalId, LastModifiedById, LastModifiedDate, CreatedDate, CreatedById, SBQQ__RenewalProduct__c;

EXEC sp_rename 'Stage_Production_SALESFORCE.dbo.Product2_Load.ProdId', 'Id';
EXEC sp_rename 'Stage_Production_SALESFORCE.dbo.Product2_Load.RenewalProductId', 'SBQQ__RenewalProduct__c';
--ALTER TABLE Stage_Production_SALESFORCE.dbo.Product2_Load
--ADD Id nchar(18);
---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
Select * from Stage_Production_SALESFORCE.dbo.Product2_Load where RenewalProductId is not null


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Stage_Production_SALESFORCE;

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(50)','Production_SALESFORCE','Product2_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
Select error, id, name,SBQQ__RenewalProduct__c  from Product2_Load_Result 
where error not like '%success%'
group by error

