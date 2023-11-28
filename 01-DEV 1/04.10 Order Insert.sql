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
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Opportunity','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Contract','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Order','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','Invoice__c','PKCHUNK'

-- select * from SourceQA.dbo.[Order]

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Order_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Order_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
-- select primary from SourceQA.dbo.Opportunity where id = '0063t000012TzCQAA0'
DECLARE @RedwoodNewDeal2024 VARCHAR(100); -- Declares a string variable with a maximum length of 100 characters.
DECLARE @RedwoodLegacyDeal VARCHAR(100);
DECLARE @TieredPriceBook2023 VARCHAR(100);

SET @RedwoodNewDeal2024 = '01sO90000008D4xIAE';
SET @RedwoodLegacyDeal = '01sO90000008D4yIAE';
SET @TieredPriceBook2023 = '01s3t000004H01QAAS';

Select
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,MIN(Con.AccountId) as AccountID
	,MIN(Con.SBQQ__Opportunity__c) as OpportunityId
	--,MAX(coalesce(Qte.SBQQ__Pricebook__c, RO.Pricebook2Id, Con.SBQQ__OpportunityPricebookId__c)) as Pricebook2Id -- STill some nulls. Do we need a default value to coalesce in if nothing is found?
	,case when MAX(coalesce(Qte.SBQQ__Pricebook__c, RO.Pricebook2Id, Con.SBQQ__OpportunityPricebookId__c)) = @TieredPriceBook2023 then @RedwoodNewDeal2024 -- replace tiered pricebook with Redwood New Deals 2024 else Redwood Legacy Deals 2024
		else @RedwoodLegacyDeal end as Pricebook2Id

	,MIN(con.SBQQ__Quote__c) as SBQQ__Quote__c
	,Con.ID as ContractId
--	,'True' as SBQQ__Contracted__c
	,MIN('Single Contract') as SBQQ__ContractingMethod__c --Picklist Single Contract or By Subscription End Date --"By Subscription End Date" creates a separate Contract for each unique Subscription End Date, containing only those Subscriptions. "Single Contract" creates one Contract containing all Subscriptions, regardless of their End Dates.
	,MIN('Draft') as [Status]
	--,'New' as Type -- Valid options are New, Renewal and Re-Quote as picklist values. None are active in the QA sandbox. If build activates this, the first one created from a quote would be new. If it is a renewal quote, it owould be Renewal

--SUBSCRIPTION FIEDS
	-- ,inv.Subscription_Start_Date__c as SubStartDate

--TWIN FIELDS
	,MIN(Con.Annual_Increase_Cap_Percentage__c)  as Annual_Increase_Cap_Percentage__c
	,MIN(Con.Annual_Increase_Cap_Term__c) as Annual_Increase_Cap_Term__c
	/* ADD OTHERS BASED ON BUILD AND ADD THEM HERE*/


-- ADDRESSES
	,MIN(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingStreet__c	,Con.[BillingStreet]		))) as BillingStreet
	,MIN(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingCity__c		,Con.[BillingCity]			))) as BillingCity
	,MIN(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingState__c		,Con.[BillingState]			))) as BillingState
	,MIN(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingPostalCode__c,Con.[BillingPostalCode]	))) as BillingPostalCode
	,MIN(dbo.scrub_address(Coalesce(Qte.SBQQ__BillingCountry__c	,Con.[BillingCountry]))) as BillingCountry
	,MIN(Acct.BillingStreet) as REF_AccountBillingStreet
	,MIN(Acct.BillingCity) as REF_AccountBillingCity
	,MIN(Acct.BillingState) as REF_AccountBillingState
	,MIN(Acct.BillingPostalCode) as REF_AccountBillingPostalCode
	,MIN(Acct.BillingCountry) as REF_AccountBillingCountry

	,dbo.scrub_address(MIN(Coalesce(Qte.SBQQ__ShippingStreet__c		,Con.[ShippingStreet]		))) as [ShippingStreet]
	,dbo.scrub_address(MIN(Coalesce(Qte.SBQQ__ShippingCity__c			,Con.[ShippingCity]		))	) as [ShippingCity]
	,dbo.scrub_address(MIN(Coalesce(Qte.SBQQ__ShippingState__c		,Con.[ShippingState]		))) as [ShippingState]
	,dbo.scrub_address(MIN(Coalesce(Qte.SBQQ__ShippingPostalCode__c	,Con.[ShippingPostalCode]))) as [ShippingPostalCode]
	,dbo.scrub_address(MIN(Coalesce(Qte.SBQQ__ShippingCountry__c 		,Con.[ShippingCountry]))	) as [ShippingCountry]

	,MIN(Con.CreatedById) as CreatedById -- Requires a permission set to allow migration user to touch audit fields --https://help.salesforce.com/s/articleView?id=000386875&language=en_US&type=1
	-- do we want the createddate to match the contract or quote?
	,MIN(Con.CurrencyIsoCode) as CurrencyIsoCode
	--,Inv.CurrencyIsoCode -- this should match the one on the quote?
	
	--,case when Qte.SBQQ__Type__c = 'Amendment' and Qte.SBQQ__StartDate__c is not null then Qte.SBQQ__StartDate__c else Con.[StartDate] end as EffectiveDate
	,MIN(Coalesce((case when (inv.Billing_Period_Start__c < Con.[StartDate] or inv.Billing_Period_Start__c > Con.EndDate) then Con.[StartDate] else inv.Billing_Period_Start__c end), Con.[StartDate])) as EffectiveDate
	,MAX(Coalesce((case when (inv.Billing_Period_End__c > Con.[EndDate] or inv.Billing_Period_End__c = NULL) then Con.[EndDate] else inv.Billing_Period_End__c end), Qte.SBQQ__EndDate__c)) as EndDate
	,MIN(Con.OwnerId) as OwnerId
	--,Inv.OwnerId as OwnerId -- Are invoice owners the same as the quote owner or ContractOwner?
	,MIN(Coalesce(Qte.SBQQ__PaymentTerms__c,'Net 30')) as SBQQ__PaymentTerm__c -- Net 30 is the default value on the order object for this.
	,MIN(Coalesce(Con.SBQQ__RenewalTerm__c,Qte.SBQQ__RenewalTerm__c)) as SBQQ__RenewalTerm__c
	,MIN(Coalesce(Con.SBQQ__RenewalUpliftRate__c ,Qte.SBQQ__RenewalUpliftRate__c)) as SBQQ__RenewalUpliftRate__c

-- MIGRATION FIELDS 																						
	,concat(MIN(Con.ID),' - ',MIN(inv.Id))  as Order_Migration_id__c -- needs created on each object. Each object's field should be unique with the object name and migration_id__c at the end to avoid twin field issues. Field should be text, set to unique and external

into StageQA.dbo.[Order_Load]

FROM SourceQA.dbo.[Contract] Con
left join SourceQA.dbo.Invoice__c inv
	on inv.Related_Contract__c = Con.Id
left join SourceQA.dbo.SBQQ__Subscription__c Sub
	on Sub.SBQQ__Contract__c = Con.Id
left join SourceQA.dbo.SBQQ__Quote__c Qte
	on Qte.ID = Con.SBQQ__Quote__c 
--	or Qte.ID = 
left join SourceQA.dbo.Opportunity O
	on Con.SBQQ__Opportunity__c = O.ID
left join SourceQA.dbo.Opportunity RO -- When Opportunity & Quote are missing on Contract, we are using the Renewal Opportunity to get the PriceBookId
	on Con.SBQQ__RenewalOpportunity__c = RO.ID
left join SourceQA.dbo.Account Acct
	on Con.AccountId = Acct.ID

Where EndDate >= getdate()
and Status = 'Activated'
and Acct.Test_Account__c = 'false'
and coalesce(Qte.SBQQ__Pricebook__c, RO.Pricebook2Id, Con.SBQQ__OpportunityPricebookId__c) != @RedwoodNewDeal2024
and coalesce(Qte.SBQQ__Pricebook__c, RO.Pricebook2Id, Con.SBQQ__OpportunityPricebookId__c) != @RedwoodLegacyDeal

group by Con.ID, 
		Coalesce((case when inv.Billing_Period_Start__c < Con.[StartDate] then Con.[StartDate] else inv.Billing_Period_Start__c end), Con.[StartDate])

--Con.ID = '8003t000008D4Z8AAK' --'8003t000008aU32AAE' 
-- only things that can amend and renew
order by Con.ID,
		EffectiveDate


---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.[Order_Load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY AccountID) AS OrderRowNumber
  FROM StageQA.dbo.[Order_Load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Order_Load';


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select Order_Migration_id__c, count(*)
from StageQA.dbo.[Order_Load]
group by Order_Migration_id__c
having count(*) > 1

select *
 from StageQA.dbo.[Order_Load]

 select * from StageQA.dbo.Order_Load_Result where ContractId = '8003t000007wQZiAAM'

---------------------------------------------------------------------------------
-- Scrub
---------------------------------------------------------------------------------

-- select * from Order_Load where OpportunityId = '0063t000013TVp3AAG'

Update x
Set BillingState = Null
from StageQA.dbo.[Order_Load] x
where BillingState in ('Taichung City')

-- Set billing country equal to account country when the billing state and the account state are the same but the country is null
-- select billingstate, BillingCountry, REF_AccountBillingState, REF_AccountBillingCountry
Update x
Set BillingCountry = REF_AccountBillingCountry
from StageQA.dbo.[Order_Load] x
where billingcountry is null
and billingstate = REF_AccountBillingState


Update x
Set ShippingState = 'New South Wales'
from StageQA.dbo.[Order_Load] x
where ShippingState = 'Pennsylvania' and ShippingCountry = 'Australia'

Update x
Set ShippingCountry = 'Australia'
from StageQA.dbo.[Order_Load] x
where ShippingCity = 'Melbourne' and ShippingCountry = 'United States'

Update x
Set ShippingCountry = 'Canada'
from StageQA.dbo.[Order_Load] x
where ShippingState in ('Ontario','Quebec') and ShippingCountry = 'United States'

-- Add berkshire as state in united kingdom
-- Add Middlesex as state in united kingdom


-- select * from StageQA.dbo.[Order_Load]
-- order by sort

USE StageQA;

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(50)','SANDBOX_QA','Order_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------
-- quote a363t000002h7SqAAI and opportunity are in different currencies. The quote has the correct values
Select error, count(*) as num from Order_Load_Result
-- Select * from Order_Load_Result
-- Select error, * from Order_Load_Result a where error not like '%success%'
Select error, count(*) as num from Order_Load_Result a
where error not like '%success%'
group by error
order by num desc

Select error, * from Order_Load_Result a where error not like '%success%'
Select top 100 error, * from Order_Load -- a where error like '%Opportunity must have%'

Select BillingCountry, count(*) from Order_Load_Result a where error like '%a problem with this country, even though it may appear correct%'
group by BillingCountry


/* VIEW LOGS */
SELECT *
  FROM [StageQA].[dbo].[DBAmp_TableLoader_Perf]
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

-- EXEC StageQA.dbo.SF_Tableloader 'DELETE','SANDBOX_QA','Order_Load_result'