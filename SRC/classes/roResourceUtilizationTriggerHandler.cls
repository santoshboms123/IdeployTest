/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceUtilizationTriggerHandler extends roITriggerHandler{

    public override void beforeInsert(List<Sobject> newList) {
        roResourceUtilizationTriggerAction.calculateAvailableHours((List<Resource_Utilization__c>) newList);
        roResourceUtilizationTriggerAction.calculateDailyUtilizationPercentage((LIst<Resource_Utilization__c>) newList);
    }
     
    public override void beforeUpdate(Map<Id, Sobject> newMap, Map<Id, Sobject> oldMap) {
        roResourceUtilizationTriggerAction.calculateAvailableHours((List<Resource_Utilization__c>) newMap.values());
        roResourceUtilizationTriggerAction.calculateDailyUtilizationPercentage((Map<Id, Resource_Utilization__c>) newMap, (Map<Id, Resource_Utilization__c>) oldMap);
    }
  
}