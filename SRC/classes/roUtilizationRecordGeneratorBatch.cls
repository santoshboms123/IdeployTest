/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
global class roUtilizationRecordGeneratorBatch implements Database.batchable<Resource__c>, Schedulable{
    
    global List<Resource__c> start(Database.BatchableContext bc) {
        return [SELECT Id, Recalculate_Available_hours__c FROM Resource__c WHERE Active__c = true];
    }

    global void execute(Database.BatchableContext BC, List<Resource__c> resourceList){
        ResourceOptimizerConfig__c orgConfig = [SELECT Id, Create_Efficiencies_For_Next_N_Days__c FROM ResourceOptimizerConfig__c 
            LIMIT 1];

        Set<Id> resourceIdSet = new Set<Id>();
        Set<Id> resourceIdSetToRecalAvailableHours = new Set<Id>();
        List<Resource__c> uncheckRecalAvailableHours = new List<Resource__c>();
        for(Resource__c res :resourceList){
            if(res.Recalculate_Available_hours__c){
                resourceIdSetToRecalAvailableHours.add(res.Id);
                uncheckRecalAvailableHours.add(new Resource__c(Id = res.Id, Recalculate_Available_hours__c = false));
            }
            resourceIdSet.add(res.Id);
        }

        if(resourceIdSetToRecalAvailableHours != null && resourceIdSetToRecalAvailableHours.size() > 0){
            Date currentDate = System.Today();
            List<Resource_Available_Hours__c> availableHoursToDelete = [SELECT Id FROM Resource_Available_Hours__c
                WHERE Resource_Utilization__r.Resource__c IN :resourceIdSetToRecalAvailableHours AND Start_time__c >= :currentDate];
            
            if(availableHoursToDelete != null && availableHoursToDelete.size() > 0){
                Database.delete(availableHoursToDelete);
            }
        }

        if(uncheckRecalAvailableHours != null && uncheckRecalAvailableHours.size() > 0){
            Database.update(uncheckRecalAvailableHours);
        }
        
        roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(resourceIdSet, System.today(), 
            Integer.valueOf(orgConfig.Create_Efficiencies_For_Next_N_Days__c), true);

    }

    global void finish(Database.BatchableContext BC){

    }

    global void execute(SchedulableContext sc) {

        roUtilizationRecordGeneratorBatch createRecords = new roUtilizationRecordGeneratorBatch();
        ID batchprocessid = Database.executeBatch(createRecords, 10);           
    }


}