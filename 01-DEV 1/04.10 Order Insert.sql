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



---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Order_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.[Order_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------



Select  DISTINCT
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,Con.AccountId as AccountID
	,Con.SBQQ__Opportunity__c as OpportunityId
	,coalesce(Con.PriceBook2__c , Qte.SBQQ__Pricebook__c ) as Pricebook2Id -- STill some nulls. Do we need a default value to coalesce in if nothing is found?
	,con.SBQQ__Quote__c as SBQQ__Quote__c
	,Con.ID as ContractId
	,'True' as SBQQ__Contracted__c
	,'Single Contract' as SBQQ__ContractingMethod__c --Picklist Single Contract or By Subscription End Date --"By Subscription End Date" creates a separate Contract for each unique Subscription End Date, containing only those Subscriptions. "Single Contract" creates one Contract containing all Subscriptions, regardless of their End Dates.
	,'Draft' as [Status]

-- ADDRESSES
	,Coalesce(Qte.SBQQ__BillingStreet__c	,Con.[BillingStreet]		) as BillingStreet
	,Coalesce(Qte.SBQQ__BillingCity__c		,Con.[BillingCity]			) as BillingCity
	,Coalesce(Qte.SBQQ__BillingState__c		,Con.[BillingState]			) as BillingState
	,Coalesce(Qte.SBQQ__BillingPostalCode__c,Con.[BillingPostalCode]	) as BillingPostalCode
	,Coalesce(Qte.SBQQ__BillingCountry__c	,Con.[BillingCountry]		) as BillingCountry
											
	,Acct.BillingStreet as REF_AccountBillingStreet
	,Acct.BillingCity as REF_AccountBillingCity
	,Acct.BillingState as REF_AccountBillingState
	,Acct.BillingPostalCode as REF_AccountBillingPostalCode
	,Acct.BillingCountry as REF_AccountBillingCountry

	,Coalesce(Qte.SBQQ__ShippingStreet__c		,Con.[ShippingStreet]		) as [ShippingStreet]
	,Coalesce(Qte.SBQQ__ShippingCity__c			,Con.[ShippingCity]			) as [ShippingCity]
	,Coalesce(Qte.SBQQ__ShippingState__c		,Con.[ShippingState]		) as [ShippingState]
	,Coalesce(Qte.SBQQ__ShippingPostalCode__c	,Con.[ShippingPostalCode]	) as [ShippingPostalCode]
	,Coalesce(Qte.SBQQ__ShippingCountry__c 		,Con.[ShippingCountry]		) as [ShippingCountry]

	,Con.CreatedById as CreatedById -- Requires a permission set to allow migration user to touch audit fields --https://help.salesforce.com/s/articleView?id=000386875&language=en_US&type=1
	-- do we want the createddate to match the contract or quote?
	,Con.CurrencyIsoCode as CurrencyIsoCode
	--,Inv.CurrencyIsoCode -- this should match the one on the quote?

	,Coalesce(Con.[StartDate],Qte.SBQQ__StartDate__c )as EffectiveDate
	,Coalesce(Con.[EndDate],Qte.SBQQ__EndDate__c )as EndDate
	,Con.OwnerId 
	--,Inv.OwnerId as OwnerId -- Are invoice owners the same as the quote owner or ContractOwner?
	,Coalesce(Qte.SBQQ__PaymentTerms__c,'Net 30') as SBQQ__PaymentTerm__c --Net 30 is the default value on the order object for this.
	,Coalesce(Con.SBQQ__RenewalTerm__c,Qte.SBQQ__RenewalTerm__c )as SBQQ__RenewalTerm__c
	,Coalesce(Con.SBQQ__RenewalUpliftRate__c ,Qte.SBQQ__RenewalUpliftRate__c ) as SBQQ__RenewalUpliftRate__c

-- MIGRATION FIELDS 																						
	,Con.ID  as Ord_Migration_id__c -- needs created on each object. Each object's field should be unique with the object name and migration_id__c at the end to avoid twin field issues. Field should be text, set to unique and external

into StageQA.dbo.[Order_Load]

FROM SourceQA.dbo.[Contract] Con
left join SourceQA.dbo.SBQQ__Quote__c Qte
	on Qte.ID = Con.SBQQ__Quote__c
left join SourceQA.dbo.Opportunity O
	on Con.SBQQ__Opportunity__c = O.ID
left join SourceQA.dbo.Account Acct
	on Con.AccountId = Acct.ID

Where EndDate >= getdate()
and Status = 'Activated'

--Con.ID = '8003t000008D4Z8AAK' --'8003t000008aU32AAE'
-- only things that can amend and renew

order by Con.ID
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


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------



---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(10)','SANDBOX_QA','Order_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from Order_Load_Result a where error not like '%success%'





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

--EXEC StageQA.dbo.SF_Tableloader 'DELETE','SANDBOX_QA','Order_Load_result'
