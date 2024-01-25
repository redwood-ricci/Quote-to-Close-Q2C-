---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Order Load Script	
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


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------

USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Order_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Order_Load]


Select 
	 CAST('' AS nvarchar(18)) AS [ID],
	CAST('' as nvarchar(2000)) as Error
	,coalesce(Inv.Related_Account__c, Opp.AccountId) as AccountID
	,Inv.Invoice_Status__c as Invoice_Status__c
	,Inv.Invoice_Method__c as Invoice_Method__c
	,Inv.Invoice_Date__c as Invoice_Date__c
	,Inv.InvoiceType__c as InvoiceType__c
	,Inv.Licenses_Sent__c as Licenses_Sent__c
	,Inv.Planned_Invoice_Date__c as Planned_Invoice_Date__c
	,Opp.CloseDate as Opportunity_Close_Date__c

	,'01sQn000000NscPIAS' as Pricebook2Id
	,Inv.Related_Opportunity__c as OpportunityId
	--,Opp.SBQQ__PrimaryQuote__c as SBQQ__Quote__c

 	--,Con.ID as ContractId
	,Con.Id as Contract__c

	,'Single Contract' as SBQQ__ContractingMethod__c --Picklist Single Contract or By Subscription End Date --"By Subscription End Date" creates a separate Contract for each unique Subscription End Date, containing only those Subscriptions. "Single Contract" creates one Contract containing all Subscriptions, regardless of their End Dates.
	,('Draft') as [Status]
	--,'New' as Type -- Valid options are New, Renewal and Re-Quote as picklist values. None are active in the QA sandbox. If build activates this, the first one created from a quote would be new. If it is a renewal quote, it owould be Renewal

--TWIN FIELDS
	,(Con.Annual_Increase_Cap_Percentage__c)  as Annual_Increase_Cap_Percentage__c
	,(Con.Annual_Increase_Cap_Term__c) as Annual_Increase_Cap_Term__c
	/* ADD OTHERS BASED ON BUILD AND ADD THEM HERE*/


-- ADDRESSES
	,(dbo.scrub_address(Acct.[BillingStreet]		)) as BillingStreet
	,(dbo.scrub_address(Acct.[BillingCity]			)) as BillingCity
	,(dbo.scrub_address(Acct.[BillingState]			)) as BillingState
	,(dbo.scrub_address(Acct.[BillingPostalCode]	)) as BillingPostalCode
	,(dbo.scrub_address(Acct.[BillingCountry])) as BillingCountry
	,dbo.scrub_address((Acct.[ShippingStreet]		)) as [ShippingStreet]
	,dbo.scrub_address((Acct.[ShippingCity]		)	) as [ShippingCity]
	,dbo.scrub_address((Acct.[ShippingState]		)) as [ShippingState]
	,dbo.scrub_address((Acct.[ShippingPostalCode])) as [ShippingPostalCode]
	,dbo.scrub_address((Acct.[ShippingCountry]))	 as [ShippingCountry]

	,(Inv.CreatedById) as CreatedById -- Requires a permission set to allow migration user to touch audit fields --https://help.salesforce.com/s/articleView?id=000386875&language=en_US&type=1
	-- do we want the createddate to match the contract or quote?
	,(Inv.CurrencyIsoCode) as CurrencyIsoCode
	--,Inv.CurrencyIsoCode -- this should match the one on the quote?
	
	--,case when Qte.SBQQ__Type__c = 'Amendment' and Qte.SBQQ__StartDate__c is not null then Qte.SBQQ__StartDate__c else Con.[StartDate] end as EffectiveDate
	,Inv.Billing_Period_Start__c as EffectiveDate
	,Inv.Billing_period_end__c as EndDate
	,Coalesce(Con.OwnerId, Inv.OwnerId) as OwnerId
	--,Inv.OwnerId as OwnerId -- Are invoice owners the same as the quote owner or ContractOwner?
	,case when Inv.Payment_Terms__c > 0 then concat('Net ',Inv.Payment_Terms__c) else 'Net 30' end as SBQQ__PaymentTerm__c -- Net 30 is the default value on the order object for this.
	,(Con.SBQQ__RenewalTerm__c) as SBQQ__RenewalTerm__c
	--,(Coalesce(Con.SBQQ__RenewalUpliftRate__c ,Qte.SBQQ__RenewalUpliftRate__c)) as SBQQ__RenewalUpliftRate__c
	,(inv.Workday_Contract_Number__c) as Workday_Contract_Number__c
	,(inv.Workday_Invoice_Id__c) as Workday_Invoice_Id__c
	,(inv.Support_Level__c) as Support_Level__c
	,(inv.RW_Invoice_Number__c) as RW_Invoice_Number__c
 	,(inv.InvoiceType__c) as Invoice_Type__c-- new,renewal,amendment -- need a place to update Type

-- MIGRATION FIELDS 																						
	,(Inv.Id)  as Order_Migration_id__c 

	,Inv.Id as Invoice__c

	into StageQA.dbo.[Order_Load]

	FROM SourceQA.dbo.Invoice__c Inv
	left join SourceQA.dbo.Account Acct
		on Inv.Related_Account__c = Acct.Id
	inner join SourceQA.dbo.Opportunity Opp
		on Inv.Related_Opportunity__c = Opp.Id
	left join SourceQA.dbo.Contract Con
		on Con.Id = Inv.Related_Contract__c
	left join SourceQA.dbo.[Order] Ord
		on Ord.Order_Migration_id__c = inv.Id

	WHERE Inv.Billing_Period_Start__c > '2022-01-01'
	--and Ord.Id is null



ALTER TABLE StageQA.dbo.[Order_Load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY AccountID) AS OrderRowNumber
  FROM StageQA.dbo.[Order_Load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;

select Order_Migration_id__c, count(*)
from StageQA.dbo.[Order_Load]
group by Order_Migration_id__c
having count(*) > 1


update x
set Licenses_Sent__c= 'false'
from StageQA.dbo.[Order_Load] x
where Licenses_Sent__c is null


select *
 from StageQA.dbo.[Order_Load]

 
USE StageQA;

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'UPSERT:bulkapi,batchsize(50)','SANDBOX_QA','Order_Load', 'Id'

select * from Order_Load_Result where error not like '%success%'

Select error, count(*) as num from Order_Load_Result a
where error not like '%success%'
group by error
order by num desc


if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Order_Reload' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.Order_Reload

select * into Order_Reload from Order_Load where Order_Migration_id__c in (
select Order_Migration_id__c from Order_Load_Result
where error not like '%success%'
and error not like '%DUPLICATE_VALUE%')

select Licenses_Sent__c from Order_Reload where Licenses_Sent__c is not null

update x
set Licenses_Sent__c= 'false'
from StageQA.dbo.[Order_Reload] x
where Licenses_Sent__c is null


EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(10)','SANDBOX_QA','Order_Reload'