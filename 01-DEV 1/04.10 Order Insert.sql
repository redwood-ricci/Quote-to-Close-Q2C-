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
USE <Source>;

EXEC <source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Account', 'yes'
EXEC <source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'PriceBook2', 'yes'
EXEC <source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'sbqq__Quote__c', 'yes'
EXEC <source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Opportunity', 'yes'
EXEC <source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Contract', 'yes'
EXEC <source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Order', 'yes'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <Staging>;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Order_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <Staging>.dbo.[Order_Load]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------



Select 
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error
	,Qte.SBQQ__Account__c as AccountID
	,Qte.SBQQ__Opportunity2__c as OpportunityId
	,Qte.SBQQ__PricebookId__c as Pricebook2Id
	,Qte.ID as SBQQ__Quote__c
	,Con.ID as ContractId
	,'True' as SBQQ__Contracted__c
	,'' as SBQQ__ContractingMethod__c --Picklist Single Contract or By Subscription End Date --"By Subscription End Date" creates a separate Contract for each unique Subscription End Date, containing only those Subscriptions. "Single Contract" creates one Contract containing all Subscriptions, regardless of their End Dates.
	,'Draft' as [Status]

-- ADDRESSES
	BillToContactId
	,Qte.SBQQ__BillingStreet__c
	,Qte.SBQQ__BillingCity__c
	,Qte.SBQQ__BillingState__c
	,Qte.SBQQ__BillingPostalCode__c
	,Qte.SBQQ__BillingCountry__c

	,ShipToContactId
	,Qte.SBQQ__ShippingStreet__c
	,Qte.SBQQ__ShippingCity__c
	,Qte.SBQQ__ShippingState__c
	,Qte.SBQQ__ShippingPostalCode__c
	,Qte.SBQQ__ShippingCountry__c


	,Qte.CreatedById as CreatedById
	,Qte.CurrencyIsoCode as CurrencyIsoCode
	,Inv.CurrencyIsoCode -- this should match the one on the quote?

	,Qte.SBQQ__StartDate__c as EffectiveDate
	,Qte.SBQQ__EndDate__c as EndDate
	--,Qte.OwnerId 
	,Inv.OwnerId as OwnerId -- Are invoice owners the same as the quote owner or ContractOwner?
	,Qte.SBQQ__PaymentTerms__c as SBQQ__PaymentTerm__c
	,Qte.SBQQ__RenewalTerm__c as SBQQ__RenewalTerm__c
	,Qte.SBQQ__RenewalUpliftRate__c as SBQQ__RenewalUpliftRate__c

/********************************************************************/
/* INVOICE FIELDS													*/
/********************************************************************/
 
	,Inv.A_R_Notes__c
	,Inv.Account_Billing_Address__c
	,Inv.Account_Id__c
	,Inv.Account_Region__c
	,Inv.Account_Shipping_Address__c
	,Inv.Account_Type__c
	,Inv.ACV_Booking_Cohort_Month__c
	,Inv.Amount__c
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
	,Inv.CreatedById -- should this come from Quote or Invoice
	,Inv.CreatedDate -- should this come from Quote or Invoice

	,Inv.Deployment_Method__c
	,Inv.Invoice_Date__c
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
-- MIGRATION FIELDS 																						
	Con.ID as Migration_id__c

FROM <Source>.dbo.SBQQ__Quote__c Qte
inner join <Source>.dbo.[Contract] Con
	on Qte.ID = Con.SBQQ__Quote__c
inner join  <Source>.dbo.Invoice__c Inv
	on Inv.Related_Contract__c = Con.ID
	and Inv.Related_Opportunity__c =Con.SBQQ__Opportunity2__c

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE <Staging>.dbo.[Order_Load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY AccountID) AS OrderRowNumber
  FROM <staging>.dbo.[Order_Load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------



---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC <Staging>.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(10)','INSERT_LINKED_SERVER_NAME','Order_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from Order_Load_Result a where error not like '%success%'