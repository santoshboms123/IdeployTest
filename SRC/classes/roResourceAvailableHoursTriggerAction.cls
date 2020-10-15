/************************************************************************ 
Author : Ramtej
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceAvailableHoursTriggerAction {
    
    //after insert
    public static void updateParentAvailableHoursSlot(Map<Id, Resource_Available_Hours__c> newAvailableHoursMap){
        set<Id> parentUtilizationIds = new set<Id>();
        Map<Id, Resource_Utilization__c> parentUtilizationsToUpdate = new Map<Id, Resource_Utilization__c>();
        for(Resource_Available_Hours__c availableHours :newAvailableHoursMap.values()){
            parentUtilizationIds.add(availableHours.Resource_Utilization__c);
        }

        Map<Id, Resource_Utilization__c> parentUtilizationRecordsMap = new Map<Id, Resource_Utilization__c>([SELECT Id, Name, Available_Hours_Slots__c FROM 
        Resource_Utilization__c WHERE Id IN :parentUtilizationIds]);

        for(Resource_Available_Hours__c availableHours :newAvailableHoursMap.values()){
            Resource_Utilization__c parentRec;
            if(parentUtilizationsToUpdate.containsKey(availableHours.Resource_Utilization__c)){
                parentRec = parentUtilizationsToUpdate.get(availableHours.Resource_Utilization__c);
            }
            else{
                parentRec = parentUtilizationRecordsMap.get(availableHours.Resource_Utilization__c);
            }

            string updatedSlot =  '';
            if(parentRec.Available_Hours_Slots__c != null){
                updatedSlot = parentRec.Available_Hours_Slots__c.endsWith(';') ? parentRec.Available_Hours_Slots__c : parentRec.Available_Hours_Slots__c+';';
            }
            string currentSlot = '';
            system.debug('updatedSlot RRRR 1 '+updatedSlot+' parentRec '+parentRec.Name);
            if(availableHours.Start_Time__c.dateGMT() == availableHours.End_Time__c.dateGMT()){
                currentSlot = string.valueOf((availableHours.Start_Time__c.hourGMT() * 60) + availableHours.Start_Time__c.minuteGMT())+'-'+
                string.valueOf((availableHours.End_Time__c.hourGMT() * 60) + availableHours.End_Time__c.minuteGMT())+';';
                system.debug('currentSlot RRRR 1 '+currentSlot+' parentRec '+parentRec.Name);
                updatedSlot += currentSlot;
                system.debug('updatedSlot RRRR 2 '+updatedSlot+' parentRec '+parentRec.Name);
            }
            else{
                currentSlot = string.valueOf((availableHours.Start_Time__c.hourGMT() * 60) + availableHours.Start_Time__c.minuteGMT())+'-'+
                string.valueOf((availableHours.End_Time__c.hourGMT() * 60) + availableHours.End_Time__c.minuteGMT() + 1440)+';';
                system.debug('currentSlot RRRR 1 '+currentSlot+' parentRec '+parentRec.Name);
                updatedSlot += currentSlot;
                system.debug('updatedSlot RRRR 2 '+updatedSlot+' parentRec '+parentRec.Name);
            }
            
            parentRec.Available_Hours_Slots__c = updatedSlot;
            parentUtilizationsToUpdate.put(parentRec.Id, parentRec);
        }

        Database.update(parentUtilizationsToUpdate.values());

    }
}