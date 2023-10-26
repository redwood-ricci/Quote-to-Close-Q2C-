select *
from sourceQA.[dbo].[sbqq__Subscription__c]
where SBQQ__Contract__c = '8003t000008aTdTAAU'
order by SBQQ__Contract__c, SBQQ__RootID__c


select *
from [Contract]
where ID  = '8003t000008aTdTAAU'


SBQQ__RequiredById__c = Subscription lookup

SBQQ__RequiredByProduct__c = Product Lookup

SBQQ__RootId__c = Subscription lookup (matching the root)


SBQQ__Bundle__c	SBQQ__Bundled__c
1	0

SBQQ__Number__c
1

Parent bundle has no requiredby or required by product. THE ID and the Root ID match
a3I3t000002ayByEAI

--replicate OI
-- CTE?
With Parent_Sub as (
Select *
from sourceQA.[dbo].[sbqq__Subscription__c] S 
--inner join sourceQA.[dbo].[OrderItem] OI
--	on  S.ID = OI.Order_Item_Migration_Id__c

where S.ID = S.SBQQ__RootId__c -- This is the parent and everything ties to it
and SBQQ__RequiredById__c is NULL
and SBQQ__Bundle__c = 1
and SBQQ__Contract__c = '8003t000008aTdTAAU'
)

-- These are the children to the bundle
Select 
	Par.ID 
	--,Par.OrderItemID as SBQQ__RequiredBy__c
	--,Par.OrderItemID as SBQQ__BundleRoot__c
	, Child.*
from sourceQA.[dbo].[sbqq__Subscription__c] Child 
--inner join sourceQA.[dbo].[OrderItem] OI
--	on  S.ID = OI.Order_Item_Migration_Id__c
inner join Parent_Sub Par
	on Child.SBQQ__RequiredById__c = Par.ID

where Child.ID != Child.SBQQ__RootId__c -- This is the parent and everything ties to it
and Child.SBQQ__RequiredById__c is not NULL
 
