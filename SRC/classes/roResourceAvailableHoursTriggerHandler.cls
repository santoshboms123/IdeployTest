/************************************************************************ 
Author : Ramtej
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceAvailableHoursTriggerHandler extends roITriggerHandler {    
     
    public override void afterInsert(Map<Id, Sobject> newMap) {
        roResourceAvailableHoursTriggerAction.updateParentAvailableHoursSlot((Map<Id, Resource_Available_Hours__c>) newMap);
    }
    
}