---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Order Load Script	
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  
--- Created Date: 10/11/2023
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
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Account','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','PriceBook2','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','sbqq__Quote__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','SBQQ__Quoteline__c','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Opportunity','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Contract','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Order','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Invoice__c','PKCHUNK'

-- select * from SourceQA.dbo.[Order]

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------

USE Stage_Production_SALESFORCE;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Order_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.[Order_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
-- select primary from SourceQA.dbo.Opportunity where id = '0063t000012TzCQAA0'

DECLARE @RedwoodNewDeal2024 VARCHAR(100); -- Declares a string variable with a maximum length of 100 characters.
DECLARE @RedwoodLegacyDeal VARCHAR(100);
DECLARE @TieredPriceBook2023 VARCHAR(100);

SET @RedwoodNewDeal2024 = '01sQn000000NscQIAS';
SET @RedwoodLegacyDeal = '01sQn000000NscPIAS';
SET @TieredPriceBook2023 = '01s3t000004H01QAAS';

WITH Contract_Subscription_Match as (
--Join Subscription with ContractId and each subscription with the corresponding SegementStartDate if its within the Contract Start or End Date, else use the Contract Start Date
	Select 
		Con.Id as ContractId,
		Sub.Id as SubscriptionId,
		Coalesce(
				(case 
					when(Sub.SBQQ__SegmentStartDate__c < Con.[StartDate] or Sub.SBQQ__SegmentStartDate__c > Con.EndDate) then Con.[StartDate] 
					else Sub.SBQQ__SegmentStartDate__c end), Con.[StartDate]) as SubscriptionStartDate,
		Year(Coalesce(
				(case 
					when(Sub.SBQQ__SegmentStartDate__c < Con.[StartDate] or Sub.SBQQ__SegmentStartDate__c > Con.EndDate) then Con.[StartDate] 
					else Sub.SBQQ__SegmentStartDate__c end), Con.[StartDate])) as SubYear

	from SourceQA.dbo.Sbqq__Subscription__c Sub
		left join SourceQA.dbo.Contract Con
			on Sub.Sbqq__Contract__c = Con.Id
		left join SourceQA.dbo.Account Acct
			on Acct.Id = Con.AccountId
	where EndDate >= '2022-01-01'
		and Status in ('Activated','Expired','Cancelled')
		and Acct.Test_Account__c = 'false' 
		and Con.[SBQQ__Order__c] is null
),
Ranked_Subscription as (
--Partition by ContractId & Year to get distinct records.
--Assuming a 3 year Contract, we need 3 orders.
	Select *, ROW_NUMBER() OVER (PARTITION BY ContractId, SubYear ORDER BY SubscriptionStartDate) as RowNum from Contract_Subscription_Match
),
Yearly_Subscriptions_By_Contract as(
	Select * from Ranked_Subscription where RowNum = 1
)

Select
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,(Con.AccountId) as AccountID
	,case when (coalesce(Qte.SBQQ__Pricebook__c, RO.Pricebook2Id, Con.SBQQ__OpportunityPricebookId__c)) = @TieredPriceBook2023 then @RedwoodNewDeal2024 -- replace tiered pricebook with Redwood New Deals 2024 else Redwood Legacy Deals 2024
		else @RedwoodLegacyDeal end as Pricebook2Id
	, case when (LineQte.Id) IS NOT NULL then (LineQte.SBQQ__Opportunity2__c) else (con.SBQQ__Opportunity__c) end as OpportunityId
	, case when (LineQte.Id) IS NOT NULL then (LineQte.Id) else (con.SBQQ__Quote__c) end as SBQQ__Quote__c

	--,(coalesce(LineQte.Id, con.SBQQ__Quote__c)) as SBQQ__Quote__c
 	,Con.ID as ContractId
	,Con.Id as Contract__c
--	,'True' as SBQQ__Contracted__c
	,(coalesce(Qte.SBQQ__ContractingMethod__c, 'Single Contract')) as SBQQ__ContractingMethod__c --Picklist Single Contract or By Subscription End Date --"By Subscription End Date" creates a separate Contract for each unique Subscription End Date, containing only those Subscriptions. "Single Contract" creates one Contract containing all Subscriptions, regardless of their End Dates.
	,('Draft') as [Status]
	--,'New' as Type -- Valid options are New, Renewal and Re-Quote as picklist values. None are active in the QA sandbox. If build activates this, the first one created from a quote would be new. If it is a renewal quote, it owould be Renewal

--SUBSCRIPTION FIEDS
	-- ,inv.Subscription_Start_Date__c as SubStartDate

--TWIN FIELDS
	,(Con.Annual_Increase_Cap_Percentage__c)  as Annual_Increase_Cap_Percentage__c
	,(Con.Annual_Increase_Cap_Term__c) as Annual_Increase_Cap_Term__c
	/* ADD OTHERS BASED ON BUILD AND ADD THEM HERE*/


-- ADDRESSES
	,(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingStreet__c	,Con.[BillingStreet]		))) as BillingStreet
	,(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingCity__c		,Con.[BillingCity]			))) as BillingCity
	,(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingState__c		,Con.[BillingState]			))) as BillingState
	,(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingPostalCode__c,Con.[BillingPostalCode]	))) as BillingPostalCode
	,(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingCountry__c	,Con.[BillingCountry]))) as BillingCountry
	,(Acct.BillingStreet) as REF_AccountBillingStreet
	,(Acct.BillingCity) as REF_AccountBillingCity
	,(Acct.BillingState) as REF_AccountBillingState
	,(Acct.BillingPostalCode) as REF_AccountBillingPostalCode
	,(Acct.BillingCountry) as REF_AccountBillingCountry

	,dbo.scrub_address((Coalesce(Qte.SBQQ__ShippingStreet__c		,Con.[ShippingStreet]		))) as [ShippingStreet]
	,dbo.scrub_address((Coalesce(Qte.SBQQ__ShippingCity__c			,Con.[ShippingCity]		))	) as [ShippingCity]
	,dbo.scrub_address((Coalesce(Qte.SBQQ__ShippingState__c		,Con.[ShippingState]		))) as [ShippingState]
	,dbo.scrub_address((Coalesce(Qte.SBQQ__ShippingPostalCode__c	,Con.[ShippingPostalCode]))) as [ShippingPostalCode]
	,dbo.scrub_address((Coalesce(Qte.SBQQ__ShippingCountry__c 		,Con.[ShippingCountry]))	) as [ShippingCountry]

	,(Con.CreatedById) as CreatedById -- Requires a permission set to allow migration user to touch audit fields --https://help.salesforce.com/s/articleView?id=000386875&language=en_US&type=1
	-- do we want the createddate to match the contract or quote?
	,(Con.CurrencyIsoCode) as CurrencyIsoCode
	--,Inv.CurrencyIsoCode -- this should match the one on the quote?
	
	--,case when Qte.SBQQ__Type__c = 'Amendment' and Qte.SBQQ__StartDate__c is not null then Qte.SBQQ__StartDate__c else Con.[StartDate] end as EffectiveDate
	,(Coalesce((case when (Sub.SBQQ__SegmentStartDate__c < Con.[StartDate] or Sub.SBQQ__SegmentStartDate__c > Con.EndDate) then Con.[StartDate] else Sub.SBQQ__SegmentStartDate__c end), Con.[StartDate])) as EffectiveDate
	,(Coalesce((case when (Sub.SBQQ__SegmentEndDate__c > Con.[EndDate] or Sub.SBQQ__SegmentEndDate__c is NULL) then Con.[EndDate] else Sub.SBQQ__SegmentEndDate__c end), Qte.SBQQ__EndDate__c)) as EndDate
	,(Con.OwnerId) as OwnerId
	--,Inv.OwnerId as OwnerId -- Are invoice owners the same as the quote owner or ContractOwner?
	,(Coalesce(Qte.SBQQ__PaymentTerms__c,'Net 30')) as SBQQ__PaymentTerm__c -- Net 30 is the default value on the order object for this.
	,(Coalesce(Con.SBQQ__RenewalTerm__c,Qte.SBQQ__RenewalTerm__c)) as SBQQ__RenewalTerm__c
	,(Coalesce(Con.SBQQ__RenewalUpliftRate__c ,Qte.SBQQ__RenewalUpliftRate__c)) as SBQQ__RenewalUpliftRate__c
	,(inv.Workday_Contract_Number__c) as Workday_Contract_Number__c
	,(inv.Workday_Invoice_Id__c) as Workday_Invoice_Id__c
	,(inv.Support_Level__c) as Support_Level__c
	,(inv.RW_Invoice_Number__c) as RW_Invoice_Number__c
 	,(inv.InvoiceType__c) as Invoice_Type__c-- new,renewal,amendment -- need a place to update Type

-- MIGRATION FIELDS 																						
	,concat((Con.ID),' - ',(Sub.Id))  as Order_Migration_id__c -- needs created on each object. Each object's field should be unique with the object name and migration_id__c at the end to avoid twin field issues. Field should be text, set to unique and external

into Stage_Production_SALESFORCE.dbo.[Order_Load]

FROM Yearly_Subscriptions_By_Contract YSC
left join SourceQA.dbo.[Contract] Con
	on YSC.ContractId = Con.Id
inner join SourceQA.dbo.SBQQ__Subscription__c Sub
	on Sub.Id = YSC.SubscriptionId
left join SourceQA.dbo.Invoice__c inv
	on inv.Id = Sub.Invoice__c
left join SourceQA.dbo.SBQQ__Quote__c Qte
	on Con.SBQQ__Quote__c = Qte.ID 
left join SourceQA.dbo.Opportunity O
	on Con.SBQQ__Opportunity__c = O.ID
left join SourceQA.dbo.Opportunity RO -- When Opportunity & Quote are missing on Contract, we are using the Renewal Opportunity to get the PriceBookId
	on Con.SBQQ__RenewalOpportunity__c = RO.ID
left join SourceQA.dbo.Account Acct
	on Con.AccountId = Acct.ID
left join SourceQA.dbo.SBQQ__Quoteline__c qtl
	on Sub.SBQQ__QuoteLine__c = qtl.Id
left join SourceQA.dbo.SBQQ__Quote__c LineQte
	on LineQte.Id = qtl.SBQQ__Quote__c
left join SourceQA.dbo.Opportunity LineOpp
	on LineOpp.SBQQ__PrimaryQuote__c = Qte.Id

Where 
O.StageName = 'Closed Won'
and Con.EndDate >= '2022-01-01'
and Status in ('Activated','Expired','Cancelled')
and Acct.Test_Account__c = 'false' 
and Con.[SBQQ__Order__c] is null
and O.SBQQ__Ordered__c = 'false'

order by Con.ID,
		 EffectiveDate

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE Stage_Production_SALESFORCE.dbo.[Order_Load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY AccountID) AS OrderRowNumber
  FROM Stage_Production_SALESFORCE.dbo.[Order_Load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;

-- SELECT *
-- FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_NAME = 'Order_Load';

-- select * from Stage_Production_SALESFORCE.dbo.[Order_Load]

---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select Order_Migration_id__c, count(*)
from Stage_Production_SALESFORCE.dbo.[Order_Load]
group by Order_Migration_id__c
having count(*) > 1

select *
 from Stage_Production_SALESFORCE.dbo.[Order_Load]

--  select * from Stage_Production_SALESFORCE.dbo.Order_Load_Result where ContractId = '8003t000007wQZiAAM'

---------------------------------------------------------------------------------
-- Scrub
---------------------------------------------------------------------------------

-- select * from Order_Load where OpportunityId = '0063t000013TVp3AAG'

Update x
Set BillingState = Null
from Stage_Production_SALESFORCE.dbo.[Order_Load] x
where BillingState in ('Taichung City')

-- Set billing country equal to account country when the billing state and the account state are the same but the country is null
-- select billingstate, BillingCountry, REF_AccountBillingState, REF_AccountBillingCountry
Update x
Set BillingCountry = REF_AccountBillingCountry
from Stage_Production_SALESFORCE.dbo.[Order_Load] x
where billingcountry is null
and billingstate = REF_AccountBillingState


Update x
Set ShippingState = 'New South Wales'
from Stage_Production_SALESFORCE.dbo.[Order_Load] x
where ShippingState = 'Pennsylvania' and ShippingCountry = 'Australia'

Update x
Set ShippingCountry = 'Australia'
from Stage_Production_SALESFORCE.dbo.[Order_Load] x
where ShippingCity = 'Melbourne' and ShippingCountry = 'United States'

Update x
Set ShippingCountry = 'Canada'
from Stage_Production_SALESFORCE.dbo.[Order_Load] x
where ShippingState in ('Ontario','Quebec') and ShippingCountry = 'United States'

-- Add berkshire as state in united kingdom
-- Add Middlesex as state in united kingdom


-- select * from Stage_Production_SALESFORCE.dbo.[Order_Load]
-- order by sort

USE Stage_Production_SALESFORCE;

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(20)','SANDBOX_QA','Order_Load'
-- Error rows: https://docs.google.com/spreadsheets/d/13RQYid_LLjGiN16ICKbkwITOvvmd_9LWBcYWktStsn4/edit#gid=0
-- one error where subscription start date is after segment end date

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
-- quote a363t000002h7SqAAI and opportunity are in different currencies. The quote has the correct values
Select error, count(*) as num from Order_Load group by error
-- Select * from Order_Load_Result
-- Select error, * from Order_Load_Result a where error not like '%success%'
Select error, count(*) as num from Order_Load_Result a
where error not like '%success%'
group by error
order by num desc

---- check for reloaded when some have duplicate migration ID values
Select error, count(*) as num from Order_Load_Result a
where error not like '%success%'
and error not like '%DUPLICATE_VALUE%'
group by error
order by num desc

Select * from Order_Load_Result a
where error not like '%DUPLICATE_VALUE%' and error not like 'Operation Successful.' and error not like 'UNABLE_TO_LOCK_ROW:unable to obtain exclusive access to this record:--'

------ reload any rows that got bounced because of processing time

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Order_Reload' AND TABLE_SCHEMA = 'dbo')
DROP TABLE Stage_Production_SALESFORCE.dbo.Order_Reload

select * into Order_Reload from Order_Load where Order_Migration_id__c in (
select Order_Migration_id__c from Order_Load_Result
where error not like '%success%'
and error not like '%DUPLICATE_VALUE%'
and error like 'UNABLE_TO_LOCK_ROW:%')
select * from Order_Reload

EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(2)','SANDBOX_QA','Order_Reload'

---- check for errors on reload
Select error, count(*) as num from Order_Reload_Result a
where error not like '%success%'
group by error
order by num desc



Select error, * from Order_Load_Result a where error not like '%success%' and error not like '%UNABLE%'
Select top 100 error, * from Order_Load -- a where error like '%Opportunity must have%'

Select BillingCountry, count(*) from Order_Load_Result a where error like '%a problem with this country, even though it may appear correct%'
group by BillingCountry


/* VIEW LOGS */
SELECT *
  FROM [Stage_Production_SALESFORCE].[dbo].[DBAmp_TableLoader_Perf]
  order by LogTime desc


/********************************************************************/
/* INVOICE FIELDS													*/
/********************************************************************/
/*
	--,INV.Id
	,Inv.A_R_Notes__c
	,Inv.Account_Billing_Address__c
	,Inv.Account_Id__c
	,Inv.Account_Region__c
	,Inv.Account_Shipping_Address__c
	,Inv.Account_Type__c
	,Inv.ACV_Booking_Cohort_Month__c
	--,Inv.Amount__c
	,Inv.ARR_Product__c
	,Inv.Billing_City__c
	,Inv.Billing_Country__c
	,Inv.Billing_Period_1_Amount__c
	,Inv.Billing_Period_1_End__c
	,Inv.Billing_Period_1_Start__c
	,Inv.Billing_Period_2_Amount__c
	,Inv.Billing_Period_2_End__c
	,Inv.Billing_Period_2_Start__c
	,Inv.Billing_Period_3_Amount__c
	,Inv.Billing_Period_3_End__c
	,Inv.Billing_Period_3_Start__c
	,Inv.Billing_Period_4_Amount__c
	,Inv.Billing_Period_4_End__c
	,Inv.Billing_Period_4_Start__c
	,Inv.Billing_Period_5_Amount__c
	,Inv.Billing_Period_5_End__c
	,Inv.Billing_Period_5_Start__c
	,Inv.Billing_Period_6_Amount__c
	,Inv.Billing_Period_6_End__c
	,Inv.Billing_Period_6_Start__c
	,Inv.Billing_Period_End__c
	,Inv.Billing_Period_Start__c
	,Inv.Billing_Postal__c
	,Inv.Billing_State__c
	,Inv.Billing_Street__c
	,Inv.Billing_Term_Close__c

	,Inv.Contact__c
	,Inv.Contract_End_Date__c
	,Inv.Contract_Start_Date__c
	--,Inv.CreatedById -- should this come from Quote or Invoice
	--,Inv.CreatedDate -- should this come from Quote or Invoice

	,Inv.Deployment_Method__c
	--,Inv.Invoice_Date__c
	,Inv.Invoice_Method__c
	,Inv.Invoice_Notes__c
	,Inv.Invoice_Status__c
	,Inv.InvoiceTerm__c
	,Inv.InvoiceType__c
	,Inv.Invoicing_Entity__c
	,Inv.Legacy_Account_Id__c
	,Inv.Legacy_Id__c
	,Inv.Legacy_Instance__c
	,Inv.Legacy_Opportunity__c
	,Inv.Licenses_Sent__c
	--,Inv.Name -- This can't be migrated
	,Inv.Opp_Quote_Number__c
	,Inv.Opportunity_Product__c
	,Inv.Opportunity_Product_Family__c
	,Inv.Opportunity_Type__c
	,Inv.Order_Form_Number__c
	,Inv.Order_Notes__c
	,Inv.OwnerId -- should this come from Quote or Invoice
	,Inv.Partner__c
	,Inv.Payment_Terms__c
	,Inv.Planned_Invoice_Date__c
	,Inv.Primary_Contact__c
	,Inv.Product__c
	,Inv.Purchase_Order_Number__c
	--,Inv.Quote_Number__c  This will come from the Quote
	,Inv.Related_Account__c
	,Inv.Related_Contract__c
	,Inv.Related_Opportunity__c
	,Inv.Related_Opportunity_Id__c
	,Inv.RW_Account_Id__c
	,Inv.RW_Invoice_Number__c
	,Inv.RW_Order_Form_Number__c
	,Inv.Sales_Tax_Amount__c
	,Inv.Sales_Tax_Rate__c
	,Inv.Shipping_City__c
	,Inv.Shipping_Country__c
	,Inv.Shipping_Postal__c
	,Inv.Shipping_State__c
	,Inv.Shipping_Street__c
	,Inv.Subscription_Amount__c
	,Inv.Subscription_Start_Date__c
	,Inv.Subscription_Term__c
	,Inv.Support_Amount__c
	,Inv.Support_Level__c
	,Inv.Test_Account__c
	,Inv.Total__c
	,Inv.Total_Sales_Tax__c
	,Inv.Workday_Contract_Number__c
	,Inv.Workday_Invoice_Id__c
*/
-- AMOUNTS 
	--TotalAmount

/*
	,Qte.SBQQ__BillingFrequency__c
	,Qte.SBQQ__ContractingMethod__c
	,Qte.SBQQ__DeliveryMethod__c
	,Qte.SBQQ__Distributor__c
	,Qte.SBQQ__LineItemsGrouped__c
	,Qte.Legal_Entity_Name__c
	,Qte.SBQQ__MasterContract__c
	,Qte.SBQQ__OrderBy__c
	,Qte.SBQQ__OrderByQuoteLineGroup__c
	,Qte.SBQQ__OrderGroupID__c
	,Qte.SBQQ__Ordered__c
	,Qte.SBQQ__Partner__c
	,Qte.SBQQ__PartnerDiscount__c
	,Qte.SBQQ__PriceBook__c
	,Qte.SBQQ__PrimaryContact__c
	,Qte.SBQQ__Primary__c
	,Qte.SBQQ__ProrationDayOfMonth__c
	,Qte.SBQQ__SalesRep__c
	,Qte.SBQQ__SubscriptionTerm__c
	,Qte.SBQQ__Type__c

	,PoDate
	,
*/

-- EXEC Stage_Production_SALESFORCE.dbo.SF_Tableloader 'DELETE','SANDBOX_QA','Order_Load_result'