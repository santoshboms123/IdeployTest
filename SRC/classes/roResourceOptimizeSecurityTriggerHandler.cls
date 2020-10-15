public with sharing class roResourceOptimizeSecurityTriggerHandler extends roITriggerHandler{
    
    public override void beforeInsert(List<Sobject> newList) {
        roResourceOptimizerSecurityController.ValidateandCreateUniqueID((List<Resource_Optimizer_Security__c>) newList);
    }

    public override void afterInsert(Map<Id, sObject> newMap) {
        roResourceOptimizerSecurityController.AssignResourceAllocationParentSecurity((List<Resource_Optimizer_Security__c>) newMap.values());  
        roResourceOptimizerSecurityController.AssignResourcegroupSecurity((List<Resource_Optimizer_Security__c>) newMap.values());  
        roResourceOptimizerSecurityController.CreateChildResourceOptimizerSecurityrecords((List<Resource_Optimizer_Security__c>) newMap.values());
    }

    public override void beforeUpdate(Map<Id, Sobject> newMap, Map<Id, Sobject> oldMap) {
        roResourceOptimizerSecurityController.UpdateResourceOptimizerSecurityrecords((List<Resource_Optimizer_Security__c>) newMap.values(),(Map<Id, Resource_Optimizer_Security__c>) oldMap);
    }

    public override void beforeDelete(Map<Id, sObject> oldMap){
        roResourceOptimizerSecurityController.DeleteChildResourceOptimizerSecurityrecords((List<Resource_Optimizer_Security__c>) oldMap.values());
        roResourceOptimizerSecurityController.RemoveResourcegroupSecurity((List<Resource_Optimizer_Security__c>) oldMap.values());
    }
     
}