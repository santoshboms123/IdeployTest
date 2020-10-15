/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceSkillsTriggerHandler extends roITriggerHandler{
    
    public override void beforeInsert(List<Sobject> newList){
        roResourceSkillsTriggerAction.createUniqueId((List<Resource_Skills__c>) newList);
    }

    public override void afterInsert(Map<Id, Sobject> newMap){
        roResourceSkillsTriggerAction.UpdateResourceSkillsfield((List<Resource_Skills__c>) newMap.values());
    }

}