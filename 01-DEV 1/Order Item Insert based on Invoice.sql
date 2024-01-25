---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Order Item Load Script	
--- Customer: Redwood
--- Primary Developer: 
--- Secondary Developers:  
--- Created Date: 25/01/2024
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

-- check this opportunity after running as an example of good output: 0063t000013DARlAAO


---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE [Source_Production_SALESFORCE];

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Account','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Invoice__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','PriceBook2','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','sbqq__Quote__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','SBQQ__Quoteline__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Opportunity','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Contract','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Order','PKCHUNK'


USE SourceQA;
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Order','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Invoice__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Opportunity','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Contract','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Account','PKCHUNK'


USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OrderItem_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.OrderItem_Load


select 
	CAST('' AS nvarchar(18)) AS [ID],
	CAST('' as nvarchar(2000)) as Error
	,Ord.ID as OrderId
	,'01tE1000003ejRJIAY' as Product2Id
	,case	when Ord.currencyisocode = 'USD' 
				then '01uE1000001DYHpIAO'
			when Ord.currencyisocode = 'GBP' 
				then '01uE1000001DYJRIA4'
			when Ord.currencyisocode = 'EUR' 
				then '01uE1000001DYL3IAO'
			when Ord.currencyisocode = 'CHF' 
				then '01uE1000001DYMfIAO'
			when Ord.currencyisocode = 'AUD' 
				then '01uE1000001DYGEIA4'
			end
		as PricebookEntryId
	,ord.EffectiveDate as ServiceDate
	,ord.EndDate as EndDate
	,Ord.CurrencyIsoCode as CurrencyIsoCode
	,inv.Amount__c as UnitPriceForceOverride__c
	,inv.Amount__c as UnitPrice
	,inv.Amount__c as SBQQ__QuotedListPrice__c
	,'1' as SBQQ__OrderedQuantity__c
	,'1' as Quantity
	,inv.id as Order_Item_Migration_id__c

	INTO StageQA.dbo.OrderItem_Load

	FROM SourceQA.dbo.Invoice__c Inv
	inner join SourceQA.dbo.[Order] Ord
		on Ord.Order_Migration_id__c = inv.Id
	left join SourceQA.dbo.Account Acct
		on Inv.Related_Account__c = Acct.Id
	inner join SourceQA.dbo.Opportunity Opp
		on Inv.Related_Opportunity__c = Opp.Id
	left join SourceQA.dbo.Contract Con
		on Con.Id = Inv.Related_Contract__c

	WHERE Inv.Billing_Period_Start__c >= '2022-01-01'


	
select *
 from StageQA.dbo.OrderItem_Load

 

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

USE StageQA;
EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(50)','SANDBOX_QA','OrderItem_Load'


select * from OrderItem_Load_Result where error not like '%success%'

select (inv.Amount__c) as InvoiceAmount, (Ord.TotalAmount) as OrderTotal from SourceQA.dbo.[Order] Ord 
	inner join SourceQA.dbo.Invoice__c inv
		on inv.Id = Ord.Invoice__c 
		and ord.TotalAmount != inv.Amount__c
		
	