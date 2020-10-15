/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceTriggerAction {
    public roResourceTriggerAction() {

    }

    //before insert and before update
    public static void populateResourceOwner(List<Resource__c> resourceList){
        try{
            for(Resource__c res :resourceList){
                if(res.User__c != null){
                    //res.ownerId = res.User__c;
                }
            }
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'Populate resource owner ', ex.getStackTraceString());
        }
    }

    //before update
    public static void recalculateAvailableHours(Map<Id, Resource__c> newResourceMap, Map<Id, Resource__c> oldResourceMap){
        try{
            for(Resource__c res :newResourceMap.values()){
                if((res.Resource_Default_Start_Time__c != oldResourceMap.get(res.Id).Resource_Default_Start_Time__c) || (res.Resource_Default_End_Time__c != oldResourceMap.get(res.Id).Resource_Default_End_Time__c)){
                    res.Recalculate_Available_hours__c = true;
                }
            }
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'Recalculate available hours', ex.getStackTraceString());
        }
    }

    //before update
}