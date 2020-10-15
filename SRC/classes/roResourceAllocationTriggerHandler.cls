/************************************************************************ 
Author : Ramtej
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceAllocationTriggerHandler extends roITriggerHandler{
    
     
    public override void beforeInsert(List<Sobject> newList) {
        roResourceAllocationTriggerActions.validateConnectedObject((List<Resource_Allocation__c>) newList);
    }
     
    public override void afterInsert(Map<Id, Sobject> newMap) {
        roResourceAllocationTriggerActions.createUpdateResourceUtilization((Map<Id, Resource_Allocation__c>) newMap,(Map<Id, Resource_Allocation__c>) newMap, true);
    }
     
    public override void beforeUpdate(Map<Id, Sobject> newMap, Map<Id, Sobject> oldMap) {
        roResourceAllocationTriggerActions.validateConnectedObject((List<Resource_Allocation__c>) newMap.values());
    }
     
    public override void afterUpdate(Map<Id, Sobject> newMap, Map<Id, Sobject> oldMap) {
        roResourceAllocationTriggerActions.createUpdateResourceUtilization((Map<Id, Resource_Allocation__c>) newMap,(Map<Id, Resource_Allocation__c>) oldMap, false);
    }
     
}