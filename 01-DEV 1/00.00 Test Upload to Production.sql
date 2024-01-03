---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Testing Test
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE [Source_Production_SALESFORCE];

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Opportunity','PKCHUNK'

select 
	id
-- 	,Name
	,NextStep
	into Source_Production_SALESFORCE.dbo.[Opportunity_Load]
	from Source_Production_SALESFORCE.dbo.Opportunity
	where id = '006Qn000003hNhBIAU'

-- examine results
select * from Source_Production_SALESFORCE.dbo.[Opportunity_Load]

---------------------------------------------------------------------------------
-- Make an update
---------------------------------------------------------------------------------

Update x
Set NextStep = 'DB AMP!'
from Source_Production_SALESFORCE.dbo.[Opportunity_Load] x
where NextStep is null


-- very carefully push the update to production
USE Source_Production_SALESFORCE;
EXEC Source_Production_SALESFORCE.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(1)','Production_SALESFORCE','Opportunity_Load'
