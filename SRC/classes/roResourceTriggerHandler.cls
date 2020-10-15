/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceTriggerHandler extends roITriggerHandler{

    public override void beforeInsert(List<Sobject> newList) {
        roResourceTriggerAction.populateResourceOwner((List<Resource__c>) newList);
    }
     
    public override void beforeUpdate(Map<Id, Sobject> newMap, Map<Id, Sobject> oldMap) {
        roResourceTriggerAction.populateResourceOwner((List<Resource__c>) newMap.values());
        roResourceTriggerAction.recalculateAvailableHours((Map<Id, Resource__c>) newMap, (Map<Id, Resource__c>) oldMap);
    }
     
}