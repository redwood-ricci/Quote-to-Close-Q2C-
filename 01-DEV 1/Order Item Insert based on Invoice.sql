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

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Order','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Account','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Invoice__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','PriceBook2','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','sbqq__Quote__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','SBQQ__Quoteline__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Opportunity','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE','Contract','PKCHUNK'


USE Source_Production_SALESFORCE;
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'SANDBOX_QA','Order','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'SANDBOX_QA','OrderItem','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'SANDBOX_QA', 'Invoice__c','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'SANDBOX_QA','Opportunity','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'SANDBOX_QA','Contract','PKCHUNK'
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'SANDBOX_QA','Account','PKCHUNK'


USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OrderItem_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.OrderItem_Load


select 
	CAST('' AS nvarchar(18)) AS [ID],
	CAST('' as nvarchar(2000)) as Error
	,Ord.ID as OrderId
	,'01tQn000003Hc0jIAC' as Product2Id
	,case	when Ord.currencyisocode = 'USD' 
				then '01uQn000001llyzIAA'
			when Ord.currencyisocode = 'GBP' 
				then '01uQn000001lm0bIAA'
			when Ord.currencyisocode = 'EUR' 
				then '01uQn000001lm2DIAQ'
			when Ord.currencyisocode = 'CHF' 
				then '01uQn000001lm3pIAA'
			when Ord.currencyisocode = 'AUD' 
				then '01uQn000001lm5RIAQ'
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

	INTO Stage_Production_SALESFORCE.dbo.OrderItem_Load

	FROM Source_Production_SALESFORCE.dbo.Invoice__c Inv
	inner join Source_Production_SALESFORCE.dbo.[Order] Ord
		on Ord.Order_Migration_id__c = inv.Id
	left join Source_Production_SALESFORCE.dbo.Account Acct
		on Inv.Related_Account__c = Acct.Id
	inner join Source_Production_SALESFORCE.dbo.Opportunity Opp
		on Inv.Related_Opportunity__c = Opp.Id
	left join Source_Production_SALESFORCE.dbo.Contract Con
		on Con.Id = Inv.Related_Contract__c
	left join Source_Production_SALESFORCE.dbo.OrderItem OI
		on OI.Order_Item_Migration_id__c = inv.Id

	WHERE Inv.Billing_Period_Start__c >= '2022-01-01'
	and OI.Id is null


	
select *
 from Stage_Production_SALESFORCE.dbo.OrderItem_Load

 

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

USE Stage_Production_SALESFORCE;
EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(50)','Production_SALESFORCE','OrderItem_Load'


select * from OrderItem_Load_Result where error not like '%success%'


Select error, count(*) as num from OrderItem_Load_Result a
where error not like '%success%'
group by error
order by num desc


if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OrderItem_Reload' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.OrderItem_Reload

select * into OrderItem_Reload from OrderItem_Load where Order_Item_Migration_id__c in (
select Order_Item_Migration_id__c from OrderItem_Load_Result
where error not like '%success%'
and error not like '%DUPLICATE_VALUE%')

select count(*) from OrderItem_Reload where Licenses_Sent__c is not null

update x
set Licenses_Sent__c= 'false'
from Stage_Production_SALESFORCE.dbo.OrderItem_Reload x
where Licenses_Sent__c is null


EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(1)','Production_SALESFORCE','OrderItem_Reload'

select * from OrderItem_Reload_Result where  error not like '%success%'


		
	