/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceUtilizationTriggerAction {
    public static Id dailyUtilizationRecTypeId  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Daily Utilization').getRecordTypeId();
    public static Id weeklyUtilizationRecTypeId  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Weekly Utilization').getRecordTypeId();
    public static Id monthlyUtilizationRecTypeId  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Monthly Utilization').getRecordTypeId();
    public static Id quarterlyUtilizationRecTypeId  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Quarterly Utilization').getRecordTypeId();
    public static ResourceOptimizerConfig__c orgConfig = [SELECT Id, Break_Time_For_Each_Resource_In_Minutes__c FROM ResourceOptimizerConfig__c LIMIT 1];

    public roResourceUtilizationTriggerAction() {

    }

    public static void calculateAvailableHours(List<Resource_Utilization__c> resourceUtilizationNewList){
        try{
            List<Resource_Utilization__c> sendForParentUtilizationCalculation = new List<Resource_Utilization__c>();
            for(Resource_Utilization__c ref :resourceUtilizationNewList){
                if(ref.RecordTypeId == dailyUtilizationRecTypeId){
                    if(!String.isBlank(ref.Available_Hours_Slots__c)){
                        List<String> compareSlots = ref.Available_Hours_Slots__c.split(';');
                        decimal totalWorkHours = 0;
                        system.debug('ref.Available_Hours_Slots__c '+ref.Available_Hours_Slots__c);
                        boolean nextIterationRequired = true;
                        while(nextIterationRequired){
                            if(compareSlots.size() == 1){
                                Integer currExistingSlotStart = Integer.valueOf(compareSlots[0].split('-')[0]);
                                Integer currExistingSlotEnd = Integer.valueOf(compareSlots[0].split('-')[1]);
                                totalWorkHours = (currExistingSlotEnd - currExistingSlotStart)/60.0;
                                nextIterationRequired = false;
                            }
                            else{
                                Set<String> nextIterationCompareSlots = new Set<String>();
                                for(integer i = 0; i < compareSlots.size() - 1; i++){
                                    string compareSlot = compareSlots[i];
                                    Integer compareSlotStart = Integer.valueOf(compareSlot.split('-')[0]);
                                    Integer compareSlotEnd = Integer.valueOf(compareSlot.split('-')[1]);
                                    for(integer j = i+1; j < compareSlots.size(); j++){
                                        string loopSlot = compareSlots[j];
                                        Integer loopSlotStart = Integer.valueOf(loopSlot.split('-')[0]);
                                        Integer loopSlotEnd = Integer.valueOf(loopSlot.split('-')[1]);
                                        system.debug('i '+i+' compareSlot '+compareSlot);
                                        system.debug('j '+j+' loopSlot '+loopSlot);
                                        //if duplicate slots
                                        if(compareSlotStart == loopSlotStart && compareSlotEnd == loopSlotEnd){
                                            //slot already exists
                                            //nextIterationRequired = false;
                                            system.debug('dupliacte slot loop');
                                            nextIterationCompareSlots.add(loopSlot);
                                            system.debug('loop 1 ref Id '+ref.Id+' compareSlotStart '+compareSlotStart+' compareSlotEnd '+compareSlotEnd+'loopSlotStart '+loopSlotStart+'loopSlotEnd '+loopSlotEnd);
                                        }
                                        //if consecutive slots
                                        else if(compareSlotStart == loopSlotEnd || compareSlotEnd == loopSlotStart){
                                            //get earliest start point and latest end point
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            if(compareSlotEnd > loopSlotStart){
                                                system.debug('consecutive slot loop 1');
                                                nextIterationCompareSlots.add(loopSlotStart+'-'+compareSlotEnd);
                                            }
                                            else if(loopSlotEnd > compareSlotStart){
                                                system.debug('consecutive slot loop 2');
                                                nextIterationCompareSlots.add(compareSlotStart+'-'+loopSlotEnd);
                                            }
                                        }
                                        //if slot starts at same time
                                        else if(compareSlotStart == loopSlotStart){
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            //get latest end point
                                            if(compareSlotEnd > loopSlotEnd){
                                                system.debug('matching start slot loop 1');
                                                nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            else if(loopSlotEnd > compareSlotEnd){
                                                system.debug('matching start slot loop 2');
                                                nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                        }
                                        //if slot ends at same time
                                        else if(compareSlotEnd == loopSlotEnd){
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            //get earliest start point
                                            if(compareSlotStart < loopSlotStart){
                                                system.debug('matching end slot loop 1');
                                                nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            else if(loopSlotStart < compareSlotStart){
                                                system.debug('matching end slot loop 2');
                                                nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                        }
                                        //check if start or end is overlapping 
                                        else if(compareSlotStart < loopSlotStart && compareSlotEnd < loopSlotEnd && loopSlotStart < compareSlotEnd){
                                            //get earliest start and latest end
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            system.debug('overlapping slot loop 1');
                                            nextIterationCompareSlots.add(compareSlotStart+'-'+loopSlotEnd);
                                        }
                                        //check if start or end is overlapping
                                        else if(loopSlotStart < compareSlotStart && loopSlotEnd < compareSlotEnd && compareSlotStart < loopSlotEnd){
                                            //get earliest start and latest end
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            system.debug('overlapping slot loop 2');
                                            nextIterationCompareSlots.add(loopSlotStart+'-'+compareSlotEnd);
                                        }
                                        //check if slots are completely independent
                                        else if(compareSlotStart < loopSlotStart && compareSlotEnd < loopSlotEnd){
                                            //add both to the slot and add total workhours
                                            system.debug('independent slot loop 1');
                                            nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                            nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                        }
                                        //check if slots are completely independent
                                        else if(compareSlotStart > loopSlotStart && compareSlotEnd > loopSlotEnd){
                                            //add both to the slot and add total workhours
                                            system.debug('independent slot loop 2');
                                            nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                            nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                        }
                                        //check slot is subset of other
                                        else if(compareSlotStart < loopSlotStart && compareSlotEnd > loopSlotEnd){
                                            //get earliest start and latest end
                                            system.debug('subset slot loop 1');
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                        }
                                        //check slot is subset of other
                                        else if(compareSlotStart > loopSlotStart && compareSlotEnd < loopSlotEnd){
                                            //get earliest start and latest end
                                            system.debug('subset slot loop 2');
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                        }
                                        system.debug('nextIterationCompareSlots after element '+j+' '+nextIterationCompareSlots);
                                    }
                                }
                                system.debug('nextIterationCompareSlots '+nextIterationCompareSlots+' compareSlots '+compareSlots);
                                if(nextIterationCompareSlots.size() == compareSlots.size()){
                                    nextIterationRequired = false;
                                }
                                else{
                                    nextIterationRequired = true;
                                    compareSlots.clear();
                                    compareSlots.addAll(nextIterationCompareSlots);
                                }
                                totalWorkHours = 0;
                                for(string slot :compareSlots){
                                    Integer slotStart = Integer.valueOf(slot.split('-')[0]);
                                    Integer slotEnd = Integer.valueOf(slot.split('-')[1]);
                                    totalWorkHours += (slotEnd - slotStart)/60.0;
                                }
                            }
                        }
                        ref.Available_Hours__c = totalWorkHours;
                        system.debug('before assignment  ref.Available_Hours_Slots__c '+ref.Available_Hours_Slots__c);
                        ref.Available_Hours_Slots__c = String.join(compareSlots, ';');
                        system.debug('after assignment  ref.Available_Hours_Slots__c '+ref.Available_Hours_Slots__c);
                        //ref.Utilization__c = (totalWorkHours/actualTotalWorkHours) * 100;                    
                        //sendForParentUtilizationCalculation.add(ref);
                    }
                }
            }            
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'Available hours calculation ', ex.getStackTraceString());
        }
    }

    public static void calculateDailyUtilizationPercentage(Map<Id, Resource_Utilization__c> resourceUtilizationNewMap, Map<Id, Resource_Utilization__c> resourceUtilizationOldMap){
        List<Resource_Utilization__c> UtilizationRecsToCalculateDailyUtilization = new List<Resource_Utilization__c>();
        for(Resource_Utilization__c ref :resourceUtilizationNewMap.values()){
            if(ref.RecordTypeId == dailyUtilizationRecTypeId && ref.Booked_Time_Slots__c != resourceUtilizationOldMap.get(ref.Id).Booked_Time_Slots__c){
                UtilizationRecsToCalculateDailyUtilization.add(ref);
            }
        }
        if(!UtilizationRecsToCalculateDailyUtilization.isEmpty()){
            calculateDailyUtilizationPercentage(UtilizationRecsToCalculateDailyUtilization);
        }
    }

    //before insert or before update
    public static void calculateDailyUtilizationPercentage(List<Resource_Utilization__c> resourceUtilizationNewList){
        try{
            List<Resource_Utilization__c> sendForParentUtilizationCalculation = new List<Resource_Utilization__c>();
            for(Resource_Utilization__c ref :resourceUtilizationNewList){
                if(ref.RecordTypeId == dailyUtilizationRecTypeId){
                    if(!String.isBlank(ref.Booked_Time_Slots__c)){
                        List<String> compareSlots = ref.Booked_Time_Slots__c.split(';');
                        decimal totalWorkHours = 0;
                        system.debug('ref.Booked_Time_Slots__c '+ref.Booked_Time_Slots__c);
                        boolean nextIterationRequired = true;
                        while(nextIterationRequired){
                            if(compareSlots.size() == 1){
                                Integer currExistingSlotStart = Integer.valueOf(compareSlots[0].split('-')[0]);
                                Integer currExistingSlotEnd = Integer.valueOf(compareSlots[0].split('-')[1]);
                                totalWorkHours = (currExistingSlotEnd - currExistingSlotStart)/60.0;
                                nextIterationRequired = false;
                            }
                            else{
                                Set<String> nextIterationCompareSlots = new Set<String>();
                                for(integer i = 0; i < compareSlots.size() - 1; i++){
                                    string compareSlot = compareSlots[i];
                                    Integer compareSlotStart = Integer.valueOf(compareSlot.split('-')[0]);
                                    Integer compareSlotEnd = Integer.valueOf(compareSlot.split('-')[1]);
                                    for(integer j = i+1; j < compareSlots.size(); j++){
                                        string loopSlot = compareSlots[j];
                                        Integer loopSlotStart = Integer.valueOf(loopSlot.split('-')[0]);
                                        Integer loopSlotEnd = Integer.valueOf(loopSlot.split('-')[1]);
                                        system.debug('i '+i+' compareSlot '+compareSlot);
                                        system.debug('j '+j+' loopSlot '+loopSlot);
                                        //if duplicate slots
                                        if(compareSlotStart == loopSlotStart && compareSlotEnd == loopSlotEnd){
                                            //slot already exists
                                            //nextIterationRequired = false;
                                            system.debug('dupliacte slot loop');
                                            nextIterationCompareSlots.add(loopSlot);
                                            system.debug('loop 1 ref Id '+ref.Id+' compareSlotStart '+compareSlotStart+' compareSlotEnd '+compareSlotEnd+'loopSlotStart '+loopSlotStart+'loopSlotEnd '+loopSlotEnd);
                                        }
                                        //if consecutive slots
                                        else if(compareSlotStart == loopSlotEnd || compareSlotEnd == loopSlotStart){
                                            //get earliest start point and latest end point
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            if(compareSlotEnd > loopSlotStart){
                                                system.debug('consecutive slot loop 1');
                                                nextIterationCompareSlots.add(loopSlotStart+'-'+compareSlotEnd);
                                            }
                                            else if(loopSlotEnd > compareSlotStart){
                                                system.debug('consecutive slot loop 2');
                                                nextIterationCompareSlots.add(compareSlotStart+'-'+loopSlotEnd);
                                            }
                                        }
                                        //if slot starts at same time
                                        else if(compareSlotStart == loopSlotStart){
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            //get latest end point
                                            if(compareSlotEnd > loopSlotEnd){
                                                system.debug('matching start slot loop 1');
                                                nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            else if(loopSlotEnd > compareSlotEnd){
                                                system.debug('matching start slot loop 2');
                                                nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                        }
                                        //if slot ends at same time
                                        else if(compareSlotEnd == loopSlotEnd){
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            //get earliest start point
                                            if(compareSlotStart < loopSlotStart){
                                                system.debug('matching end slot loop 1');
                                                nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            else if(loopSlotStart < compareSlotStart){
                                                system.debug('matching end slot loop 2');
                                                nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                        }
                                        //check if start or end is overlapping 
                                        else if(compareSlotStart < loopSlotStart && compareSlotEnd < loopSlotEnd && loopSlotStart < compareSlotEnd){
                                            //get earliest start and latest end
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            system.debug('overlapping slot loop 1');
                                            nextIterationCompareSlots.add(compareSlotStart+'-'+loopSlotEnd);
                                        }
                                        //check if start or end is overlapping
                                        else if(loopSlotStart < compareSlotStart && loopSlotEnd < compareSlotEnd && compareSlotStart < loopSlotEnd){
                                            //get earliest start and latest end
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            system.debug('overlapping slot loop 2');
                                            nextIterationCompareSlots.add(loopSlotStart+'-'+compareSlotEnd);
                                        }
                                        //check if slots are completely independent
                                        else if(compareSlotStart < loopSlotStart && compareSlotEnd < loopSlotEnd){
                                            //add both to the slot and add total workhours
                                            system.debug('independent slot loop 1');
                                            nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                            nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                        }
                                        //check if slots are completely independent
                                        else if(compareSlotStart > loopSlotStart && compareSlotEnd > loopSlotEnd){
                                            //add both to the slot and add total workhours
                                            system.debug('independent slot loop 2');
                                            nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                            nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                        }
                                        //check slot is subset of other
                                        else if(compareSlotStart < loopSlotStart && compareSlotEnd > loopSlotEnd){
                                            //get earliest start and latest end
                                            system.debug('subset slot loop 1');
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            nextIterationCompareSlots.add(compareSlotStart+'-'+compareSlotEnd);
                                        }
                                        //check slot is subset of other
                                        else if(compareSlotStart > loopSlotStart && compareSlotEnd < loopSlotEnd){
                                            //get earliest start and latest end
                                            system.debug('subset slot loop 2');
                                            if(nextIterationCompareSlots.contains(loopSlotStart+'-'+loopSlotEnd)){
                                                nextIterationCompareSlots.remove(loopSlotStart+'-'+loopSlotEnd);
                                            }
                                            if(nextIterationCompareSlots.contains(compareSlotStart+'-'+compareSlotEnd)){
                                                nextIterationCompareSlots.remove(compareSlotStart+'-'+compareSlotEnd);
                                            }
                                            nextIterationCompareSlots.add(loopSlotStart+'-'+loopSlotEnd);
                                        }
                                        system.debug('nextIterationCompareSlots after element '+j+' '+nextIterationCompareSlots);
                                    }
                                }
                                system.debug('nextIterationCompareSlots '+nextIterationCompareSlots+' compareSlots '+compareSlots);
                                if(nextIterationCompareSlots.size() == compareSlots.size()){
                                    nextIterationRequired = false;
                                }
                                else{
                                    nextIterationRequired = true;
                                    compareSlots.clear();
                                    compareSlots.addAll(nextIterationCompareSlots);
                                }
                                totalWorkHours = 0;
                                for(string slot :compareSlots){
                                    Integer slotStart = Integer.valueOf(slot.split('-')[0]);
                                    Integer slotEnd = Integer.valueOf(slot.split('-')[1]);
                                    totalWorkHours += (slotEnd - slotStart)/60.0;
                                }
                            }
                        }
                        ref.Worked_Hours__c = totalWorkHours;
                        system.debug('before assignment  ref.Booked_Time_Slots__c '+ref.Booked_Time_Slots__c);
                        ref.Booked_Time_Slots__c = String.join(compareSlots, ';');
                        system.debug('after assignment  ref.Booked_Time_Slots__c '+ref.Booked_Time_Slots__c);
                        ref.Utilization__c = (totalWorkHours/ref.Available_Hours__c) * 100;                    
                        sendForParentUtilizationCalculation.add(ref);
                    }
                    else{
                        ref.Worked_Hours__c = 0;
                        ref.Utilization__c = 0;
                        sendForParentUtilizationCalculation.add(ref);
                    }
                }
            }
            //calculate and assign parent Utilization records
            Map<String, Resource_Utilization__c> weekUtilizationMap = calculateWeeklyUtilizationPercentage(sendForParentUtilizationCalculation);
            Map<String, Resource_Utilization__c> monthUtilizationMap = calculateMonthlyUtilizationPercentage(sendForParentUtilizationCalculation);
            Map<String, Resource_Utilization__c> querterUtilizationMap = calculateQuarterlyUtilizationPercentage(sendForParentUtilizationCalculation);
            system.debug('santynew1'+ weekUtilizationMap);
            

            for(Resource_Utilization__c ref :sendForParentUtilizationCalculation){
                system.debug('santynew2-'+ ref.Resource__c+'-'+string.valueOf(ref.Utilization_Date__c.toStartOfWeek()));
                ref.Parent_Week__c = weekUtilizationMap.get(ref.Resource__c+'-'+string.valueOf(ref.Utilization_Date__c.toStartOfWeek())).Id;
                ref.Parent_Month__c = monthUtilizationMap.get(ref.Resource__c+'-'+string.valueOf(ref.Utilization_Date__c.Month())+'-'+string.valueOf(ref.Utilization_Date__c.Year())).Id;
                
                String mapKey = ref.Resource__c+'-';
                if(ref.Utilization_Date__c.month() <= 3){
                    mapKey += 'Q1 - '+string.valueOf(ref.Utilization_Date__c.year());
                }
                else if(ref.Utilization_Date__c.month() <= 6){
                    mapKey += 'Q2 - '+string.valueOf(ref.Utilization_Date__c.year());
                }
                else if(ref.Utilization_Date__c.month() <= 9){
                    mapKey += 'Q3 - '+string.valueOf(ref.Utilization_Date__c.year());
                }
                else if(ref.Utilization_Date__c.month() <= 12){
                    mapKey += 'Q4 - '+string.valueOf(ref.Utilization_Date__c.year());
                }
                ref.Parent_Quarter__c = querterUtilizationMap.get(mapKey).Id;
            }
            
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'daily Utilization calculation ', ex.getStackTraceString());
        }
    }

    public static Map<String, Resource_Utilization__c> calculateWeeklyUtilizationPercentage(List<Resource_Utilization__c> resourceUtilizationNewList){
        Map<String, Resource_Utilization__c> weekUtilizationMap = new Map<String, Resource_Utilization__c>();
        List<Id> ResourceIds = new List<Id>();
        try{
            List<Date> weekStartDates = new List<Date>();
            for(Resource_Utilization__c ref :resourceUtilizationNewList){
                weekStartDates.add(ref.Utilization_Date__c.toStartOfWeek());
                ResourceIds.add(ref.Resource__c);
            }
            Map<String, Resource_Utilization__c> existingParentUtilizationRecords = new Map<String, Resource_Utilization__c>();
            for(Resource_Utilization__c weekParent :[SELECT Id, Week_Start_Date__c, Utilization__c, Resource__c, 
                            (SELECT Id, Available_Hours__c, Worked_Hours__c, Utilization__c FROM Resource_Utilization__r WHERE 
                            RecordTypeId = :dailyUtilizationRecTypeId) FROM Resource_Utilization__c
                            WHERE Week_Start_Date__c IN :weekStartDates AND Resource__c IN :ResourceIds AND RecordTypeId = :weeklyUtilizationRecTypeId]){
                                existingParentUtilizationRecords.put(weekParent.Resource__c+'-'+string.valueOf(weekParent.Week_Start_Date__c), weekParent);
            }
            system.debug('existingParentUtilizationRecords '+existingParentUtilizationRecords);
            
            for(Resource_Utilization__c ref :resourceUtilizationNewList){
                system.debug('ref '+ref);
                string mapKey = ref.Resource__c+'-'+string.valueOf(ref.Utilization_Date__c.toStartOfWeek());
                system.debug('mapKey '+mapKey);
                //update existing Utilization recs
                if(existingParentUtilizationRecords.containsKey(mapKey)){
                    Resource_Utilization__c existingUtilizationRec = existingParentUtilizationRecords.get(mapKey);
                    Decimal totalUtilization = 0;
                    Decimal totalAvailablehours = 0;
                    Decimal totalworkedhours = 0; 
                    if(ref.Id == null){
                        totalUtilization += ref.Utilization__c;
                        totalAvailablehours += ref.Available_Hours__c == null ? 0 : ref.Available_Hours__c;
                        totalworkedhours += ref.Worked_Hours__c;
                    }
                    for(Resource_Utilization__c dailyUtilizationRec :existingUtilizationRec.Resource_Utilization__r){
                        if(ref.Id == dailyUtilizationRec.Id){
                            totalUtilization += ref.Utilization__c;
                            totalAvailablehours += ref.Available_Hours__c;
                       		 totalworkedhours += ref.Worked_Hours__c;
                        }
                        else{
                            totalUtilization += dailyUtilizationRec.Utilization__c;
                            totalAvailablehours += dailyUtilizationRec.Available_Hours__c;
                       	    totalworkedhours += dailyUtilizationRec.Worked_Hours__c;
                        }
                    }
                    Integer totalRecords = ref.Id == null ? existingUtilizationRec.Resource_Utilization__r.size() + 1 : existingUtilizationRec.Resource_Utilization__r.size();
                    system.debug('WEEK totalUtilization '+totalUtilization+' totalRecords '+totalRecords);
                  //  existingUtilizationRec.Utilization__c = totalUtilization/totalRecords;
                    if(totalAvailablehours > 0){existingUtilizationRec.Utilization__c = totalworkedhours/totalAvailablehours;}else{existingUtilizationRec.Utilization__c = 0;}  
                    weekUtilizationMap.put(mapKey, existingUtilizationRec);
                }
                else{
                    Resource_Utilization__c newWeekUtilization = new Resource_Utilization__c();
                    newWeekUtilization.RecordTypeId = weeklyUtilizationRecTypeId;
                    newWeekUtilization.Week_Start_Date__c = ref.Utilization_Date__c.toStartOfWeek();
                    newWeekUtilization.Utilization__c = ref.Utilization__c;
                    newWeekUtilization.Year__c = ref.Utilization_Date__c.year();
                    newWeekUtilization.Resource__c = ref.Resource__c;
                    weekUtilizationMap.put(mapKey, newWeekUtilization);
                }
            }

            Database.upsert(weekUtilizationMap.values());
            return weekUtilizationMap;
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'weekly Utilization calculation ', ex.getStackTraceString());
            return weekUtilizationMap;
        }
    }

    public static Map<String, Resource_Utilization__c> calculateMonthlyUtilizationPercentage(List<Resource_Utilization__c> resourceUtilizationNewList){
        Map<String, Resource_Utilization__c> monthUtilizationMap = new Map<String, Resource_Utilization__c>();
        try{
            List<Integer> monthNumber = new List<Integer>();
            List<Integer> Year = new List<Integer>();
            List<Id> ResourceIds = new List<Id>();
            for(Resource_Utilization__c ref :resourceUtilizationNewList){
                if(ref.RecordTypeId == dailyUtilizationRecTypeId){
                    monthNumber.add(ref.Utilization_Date__c.month());
                    Year.add(ref.Utilization_Date__c.year());
                    ResourceIds.add(ref.Resource__c);
                }
            }
            Map<String, Resource_Utilization__c> existingParentUtilizationRecords = new Map<String, Resource_Utilization__c>();
            for(Resource_Utilization__c monthParent :[SELECT Id, Utilization__c, Resource__c, Year__c, Month_Number__c, 
				(SELECT Id, Available_Hours__c, Worked_Hours__c, Utilization__c FROM Resource_Utilization1__r WHERE 
				RecordTypeId = :dailyUtilizationRecTypeId) FROM Resource_Utilization__c
                WHERE Month_Number__c IN :monthNumber AND Year__c IN :Year AND Resource__c IN :ResourceIds AND 
                RecordTypeId = :monthlyUtilizationRecTypeId]){
					existingParentUtilizationRecords.put(monthParent.Resource__c+'-'+string.valueOf(monthParent.Month_Number__c)+'-'+string.valueOf(monthParent.Year__c), monthParent);
            }

            for(Resource_Utilization__c ref :resourceUtilizationNewList){
                String mapKey = ref.Resource__c+'-'+string.valueOf(ref.Utilization_Date__c.Month())+'-'+string.valueOf(ref.Utilization_Date__c.Year());
                //update existing Utilization recs
                if(existingParentUtilizationRecords.containsKey(mapKey)){
                    Resource_Utilization__c existingUtilizationRec = existingParentUtilizationRecords.get(mapKey);
                    Decimal totalUtilization = 0;
                    Decimal totalAvailablehours = 0;
                    Decimal totalworkedhours = 0; 
                    if(ref.Id == null){
                        totalUtilization += ref.Utilization__c;
                        totalAvailablehours += ref.Available_Hours__c == null ? 0 : ref.Available_Hours__c;
                        totalworkedhours += ref.Worked_Hours__c;
                    }
                    for(Resource_Utilization__c dailyUtilizationRec :existingUtilizationRec.Resource_Utilization1__r){
                        if(ref.Id == dailyUtilizationRec.Id){
                            totalUtilization += ref.Utilization__c;
                            totalAvailablehours += ref.Available_Hours__c;
                       		 totalworkedhours += ref.Worked_Hours__c;
                        }
                        else{
                            totalUtilization += dailyUtilizationRec.Utilization__c;
                            totalAvailablehours += dailyUtilizationRec.Available_Hours__c;
                       	    totalworkedhours += dailyUtilizationRec.Worked_Hours__c;	
                        }
                    }
                    Integer totalRecords = ref.Id == null ? existingUtilizationRec.Resource_Utilization1__r.size() + 1 : existingUtilizationRec.Resource_Utilization1__r.size();
                    system.debug('MONTH totalUtilization '+totalUtilization+' totalRecords '+totalRecords);
                  //  existingUtilizationRec.Utilization__c = totalUtilization/totalRecords;
                     if(totalAvailablehours > 0){existingUtilizationRec.Utilization__c = totalworkedhours/totalAvailablehours;}else{existingUtilizationRec.Utilization__c = 0;} 
                    monthUtilizationMap.put(mapKey, existingUtilizationRec);
                }
                else{
                    Resource_Utilization__c newMonthUtilization = new Resource_Utilization__c();
                    newMonthUtilization.RecordTypeId = monthlyUtilizationRecTypeId;
                    newMonthUtilization.Utilization__c = ref.Utilization__c;
                    newMonthUtilization.Year__c = ref.Utilization_Date__c.Year();
                    newMonthUtilization.Month_Number__c = ref.Utilization_Date__c.Month();
                    newMonthUtilization.Resource__c = ref.Resource__c;
                    monthUtilizationMap.put(mapKey, newMonthUtilization);
                }
            }

            Database.upsert(monthUtilizationMap.values());
            return monthUtilizationMap;
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'monthly Utilization calculation ', ex.getStackTraceString());
            return monthUtilizationMap;
        }
    }

    public static Map<String, Resource_Utilization__c> calculateQuarterlyUtilizationPercentage(List<Resource_Utilization__c> resourceUtilizationNewList){
        Map<String, Resource_Utilization__c> quarterUtilizationMap = new Map<String, Resource_Utilization__c>();
        try{
            List<Id> ResourceIds = new List<Id>();
            Set<String> QuarterNameSet = new Set<String>();
            for(Resource_Utilization__c ref :resourceUtilizationNewList){
                if(ref.RecordTypeId == dailyUtilizationRecTypeId){
                    ResourceIds.add(ref.Resource__c);
                    if(ref.Utilization_Date__c.month() <= 3){
                        QuarterNameSet.add('Q1 - '+string.valueOf(ref.Utilization_Date__c.year()));
                    }
                    else if(ref.Utilization_Date__c.month() <= 6){
                        QuarterNameSet.add('Q2 - '+string.valueOf(ref.Utilization_Date__c.year()));
                    }
                    else if(ref.Utilization_Date__c.month() <= 9){
                        QuarterNameSet.add('Q3 - '+string.valueOf(ref.Utilization_Date__c.year()));
                    }
                    else if(ref.Utilization_Date__c.month() <= 12){
                        QuarterNameSet.add('Q4 - '+string.valueOf(ref.Utilization_Date__c.year()));
                    }
                }
            }

            Map<String, Resource_Utilization__c> existingParentUtilizationRecords = new Map<String, Resource_Utilization__c>();
            for(Resource_Utilization__c quarterParent :[SELECT Id, Utilization__c, Resource__c, Year__c, Quarter_Name__c, 
                (SELECT Id, Available_Hours__c, Worked_Hours__c, Utilization__c FROM Resource_Utilization2__r WHERE 
                RecordTypeId = :dailyUtilizationRecTypeId) FROM Resource_Utilization__c
                WHERE Quarter_Name__c IN :QuarterNameSet AND Resource__c IN :ResourceIds AND RecordTypeId = :quarterlyUtilizationRecTypeId]){
                    existingParentUtilizationRecords.put(quarterParent.Resource__c+'-'+quarterParent.Quarter_Name__c, quarterParent);
            }

            for(Resource_Utilization__c ref :resourceUtilizationNewList){
                String mapKey = ref.Resource__c+'-';
                string quarterName = '';
                if(ref.Utilization_Date__c.month() <= 3){
                    quarterName = 'Q1 - '+string.valueOf(ref.Utilization_Date__c.year());
                }
                else if(ref.Utilization_Date__c.month() <= 6){
                    quarterName = 'Q2 - '+string.valueOf(ref.Utilization_Date__c.year());
                }
                else if(ref.Utilization_Date__c.month() <= 9){
                    quarterName = 'Q3 - '+string.valueOf(ref.Utilization_Date__c.year());
                }
                else if(ref.Utilization_Date__c.month() <= 12){
                    quarterName = 'Q4 - '+string.valueOf(ref.Utilization_Date__c.year());
                }
                mapKey += quarterName;
                //update existing Utilization recs
                if(existingParentUtilizationRecords.containsKey(mapKey)){
                    Resource_Utilization__c existingUtilizationRec = existingParentUtilizationRecords.get(mapKey);
                    Decimal totalUtilization = 0;
                    Decimal totalAvailablehours = 0;
                    Decimal totalworkedhours = 0; 
                    if(ref.Id == null){
                        totalUtilization += ref.Utilization__c;
                        totalAvailablehours += ref.Available_Hours__c == null ? 0 : ref.Available_Hours__c;
                        totalworkedhours += ref.Worked_Hours__c;
                    }
                    for(Resource_Utilization__c dailyUtilizationRec :existingUtilizationRec.Resource_Utilization2__r){
                        if(ref.Id == dailyUtilizationRec.Id){
                            totalUtilization += ref.Utilization__c;
                            totalAvailablehours += ref.Available_Hours__c;
                        totalworkedhours += ref.Worked_Hours__c;
                        }
                        else{
                            totalUtilization += dailyUtilizationRec.Utilization__c;
                            totalAvailablehours += dailyUtilizationRec.Available_Hours__c;
                       	    totalworkedhours += dailyUtilizationRec.Worked_Hours__c;	
                        }
                    }
                    Integer totalRecords = ref.Id == null ? existingUtilizationRec.Resource_Utilization2__r.size() + 1 : existingUtilizationRec.Resource_Utilization2__r.size();
                    system.debug('QUARTER totalUtilization '+totalUtilization+' totalRecords '+totalRecords);
                  //  existingUtilizationRec.Utilization__c = totalUtilization/totalRecords;
                   	if(totalAvailablehours > 0){existingUtilizationRec.Utilization__c = totalworkedhours/totalAvailablehours;}else{existingUtilizationRec.Utilization__c = 0;} 
                    quarterUtilizationMap.put(mapKey, existingUtilizationRec);
                }
                else{
                    Resource_Utilization__c newQuarterUtilization = new Resource_Utilization__c();
                    newQuarterUtilization.RecordTypeId = quarterlyUtilizationRecTypeId;
                    newQuarterUtilization.Utilization__c = ref.Utilization__c;
                    newQuarterUtilization.Year__c = ref.Utilization_Date__c.Year();
                    newQuarterUtilization.Quarter_Name__c = quarterName;
                    newQuarterUtilization.Resource__c = ref.Resource__c;
                    quarterUtilizationMap.put(mapKey, newQuarterUtilization);
                }
            }

            Database.upsert(quarterUtilizationMap.values());
            return quarterUtilizationMap;
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'qurterly Utilization calculation ', ex.getStackTraceString());
            return quarterUtilizationMap;
        }
    }
}