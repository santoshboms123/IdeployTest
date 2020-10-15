/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceAllocationTriggerActions {

    public static ResourceOptimizerConfig__c orgConfig = [SELECT Id, Resource_Start_Hours__c, Resource_Start_Minutes__c, 
    Resource_End_Hours__c, Resource_End_Minutes__c,Do_you_allow_Overlay__c FROM ResourceOptimizerConfig__c LIMIT 1];
    public static Id dateUtilizationRecTypeId  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Daily Utilization').getRecordTypeId();


    //throw validation if one resource allocation record is used for multiple connector objects
    //before insert or update
    public static void validateConnectedObject(List<Resource_Allocation__c> resourceAllocationNewList){
     /*   Set<String> connectObjectFields = roResourceOptimizerUtility.getFieldsFromObject('Resource_Allocation__c', 'REFERENCE', true);
        connectObjectFields.remove('Resource__c');// should edit to include namespace when package is created
        for(Resource_Allocation__c resAll :resourceAllocationNewList){
            if(resAll.Resource__c != null){
                boolean parentRecFound = false;
                for(String connectObjectField :connectObjectFields){
                    if(resAll.get(connectObjectField) != null){
                        if(!parentRecFound){
                            parentRecFound = true;
                        }
                        else{
                            resAll.addError('Multiple parent records found for allocation record Id '+resAll.Id);
                        }
                    }
                }
            }
        } */
        
        // Check for Overlay 
        if(orgConfig != null){
            if(orgConfig.Do_you_allow_Overlay__c == false){
                
                // check for existing allocations Only one Allocation happens at once. Below for loop will execute only once for any given transaction 
                 for(Resource_Allocation__c resAll :resourceAllocationNewList){
                     if(resAll.Status__c != 'New' && resAll.Resource__c != null && resAll.Allocated_Start_DateTime__c != null && resAll.Allocated_End_Datetime__c != null){
                         List<Id> resourceavailable  = roResourceSuggestionsController.getAvailableResourcesList(new List<Id>{resAll.Resource__c},resAll.Allocated_Start_DateTime__c,resAll.Allocated_End_Datetime__c);
                         if(resourceavailable.size() == 0){
                             resAll.addError('Resource'+resAll.Resource__r.FullName__c+'is already reserved in this timing');
                         }
                     }
                     }
            }
            
        }
        
    }

    //create or update resource Utilization Records 
    //after insert and after update
    public static void createUpdateResourceUtilization(Map<Id, Resource_Allocation__c> resourceAllocationNewMap, Map<Id, Resource_Allocation__c> resourceAllocationOldMap, boolean isInsert){
        try{  
            List<Resource_Allocation__c> oldAllocationRecords = new List<Resource_Allocation__c>();
            List<Resource_Allocation__c> newAllocationRecords = new List<Resource_Allocation__c>();
            
            //seperate records to remove old time slots and add new time slots
            for(Resource_Allocation__c ra :resourceAllocationNewMap.values()){
                if(resourceAllocationNewMap.get(ra.Id).Allocated_Start_DateTime__c != null &&
                resourceAllocationNewMap.get(ra.Id).Allocated_End_Datetime__c != null && resourceAllocationNewMap.get(ra.Id).Resource__c != null){
                    if(ra.Calculate_Utilization__c){
                        if(isInsert){
                            newAllocationRecords.add(ra);
                        }
                        else{
                            if(resourceAllocationNewMap.get(ra.Id).Resource__c != resourceAllocationOldMap.get(ra.Id).Resource__c && 
                            (resourceAllocationNewMap.get(ra.Id).Allocated_Start_DateTime__c != resourceAllocationOldMap.get(ra.Id).Allocated_Start_DateTime__c || 
                            resourceAllocationNewMap.get(ra.Id).Allocated_End_Datetime__c != resourceAllocationOldMap.get(ra.Id).Allocated_End_Datetime__c)){
                                //dates and resource is changed
                                oldAllocationRecords.add(resourceAllocationOldMap.get(ra.Id));
                                newAllocationRecords.add(ra);
                            }
                            else if(resourceAllocationNewMap.get(ra.Id).Resource__c != resourceAllocationOldMap.get(ra.Id).Resource__c){
                                //only resource is changed
                                oldAllocationRecords.add(resourceAllocationOldMap.get(ra.Id));
                                newAllocationRecords.add(ra);
                            }
                            else if((resourceAllocationNewMap.get(ra.Id).Allocated_Start_DateTime__c != resourceAllocationOldMap.get(ra.Id).Allocated_Start_DateTime__c || 
                            resourceAllocationNewMap.get(ra.Id).Allocated_End_Datetime__c != resourceAllocationOldMap.get(ra.Id).Allocated_End_Datetime__c)){
                                //only hours worked is changed
                                oldAllocationRecords.add(resourceAllocationOldMap.get(ra.Id));
                                newAllocationRecords.add(ra);
                            }
                        }  
                   }
                   else if(!ra.Calculate_Utilization__c && resourceAllocationNewMap.get(ra.Id).Calculate_Utilization__c != resourceAllocationOldMap.get(ra.Id).Calculate_Utilization__c){
                    oldAllocationRecords.add(resourceAllocationOldMap.get(ra.Id));
                   } 
                }
            }

            List<Resource_Utilization__c> UtilizationUpdateforOldRecords = UtilizationRecordsUpdateHelper(oldAllocationRecords, false);
            List<Database.SaveResult> oldEfficeincyRecordsUpdateResult = Database.update(UtilizationUpdateforOldRecords);
            system.debug('oldEfficeincyRecordsUpdateResult '+oldEfficeincyRecordsUpdateResult);

            List<Resource_Utilization__c> UtilizationUpdateforNewRecords = UtilizationRecordsUpdateHelper(newAllocationRecords, true);
            List<Database.UpsertResult> oldNewEfficeincyRecordsUpsertResult = Database.upsert(UtilizationUpdateforNewRecords);
            system.debug('oldNewEfficeincyRecordsUpsertResult '+oldNewEfficeincyRecordsUpsertResult);

        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'create or update resource Utilization records on insert or update of resource allocation records', ex.getStackTraceString());
        }
    }

    public static List<Resource_Utilization__c> UtilizationRecordsUpdateHelper(List<Resource_Allocation__c> resourceAllocationList, boolean newRecords){
        List<Resource_Utilization__c> resourceUtilizationRecords = new List<Resource_Utilization__c>();
        try{
            system.debug('resourceAllocationList '+resourceAllocationList);
            Date minUtilizationDate;
            Date maxUtilizationDate;
            set<Id> resourceIds = new set<Id>();
            Map<Id,Map<Date, Resource_Utilization__c>> existingRefUtilizationRecMap = new Map<Id,Map<Date, Resource_Utilization__c>>();
            Map<Id, Resource__c> resourceAllocationParentMap = new Map<Id, Resource__c>();
            //get min and max date range from the updated records
            for(Resource_Allocation__c ra :resourceAllocationList){
                if(minUtilizationDate == null){
                    minUtilizationDate = ra.Allocated_Start_DateTime__c.dateGMT();
                }
                else if(ra.Allocated_Start_DateTime__c.dateGMT() < minUtilizationDate){
                    minUtilizationDate = ra.Allocated_Start_DateTime__c.dateGMT();
                }

                if(maxUtilizationDate == null){
                    maxUtilizationDate = ra.Allocated_End_Datetime__c.dateGMT();
                }
                else if(maxUtilizationDate < ra.Allocated_End_Datetime__c.dateGMT()){
                    maxUtilizationDate = ra.Allocated_End_Datetime__c.dateGMT();
                }
                resourceIds.add(ra.Resource__c);
            }
            system.debug('minUtilizationDate '+minUtilizationDate);
            system.debug('maxUtilizationDate '+maxUtilizationDate);
            system.debug('resourceIds '+resourceIds);

            resourceAllocationParentMap = new Map<Id, Resource__c>([SELECT Id, Resource_Time_Zone__c FROM Resource__c WHERE Id IN :resourceIds]);
            
            for(Resource_Utilization__c resUtilization :[SELECT Id, Booked_Time_Slots__c, Utilization_Date__c, Resource__c 
                                                FROM Resource_Utilization__c WHERE RecordTypeId = :dateUtilizationRecTypeId AND 
                                                Utilization_Date__c >= :minUtilizationDate AND Utilization_Date__c <= :maxUtilizationDate AND 
                                                Resource__c IN :resourceIds]){
                                system.debug('resUtilization '+resUtilization);
                                Map<Date, Resource_Utilization__c> resDateMap = existingRefUtilizationRecMap.containsKey(resUtilization.Resource__c) ? 
                                existingRefUtilizationRecMap.get(resUtilization.Resource__c) : new Map<Date, Resource_Utilization__c>();
                                resDateMap.put(resUtilization.Utilization_Date__c, resUtilization);
                                system.debug('resDateMap '+resDateMap);
                                existingRefUtilizationRecMap.put(resUtilization.Resource__c, resDateMap);
                                system.debug('existingRefUtilizationRecMap '+existingRefUtilizationRecMap);
            }
            system.debug('existingRefUtilizationRecMap '+existingRefUtilizationRecMap);

            //remove allocations for old dates
            for(Resource_Allocation__c ra :resourceAllocationList){
                List<Resource_Utilization__c> updatedUtilizationRecs = new List<Resource_Utilization__c>();
                if(newRecords){
                    system.debug('ra '+ra+' newRecords '+newRecords);
                    if(existingRefUtilizationRecMap.containsKey(ra.Resource__c)){
                        updatedUtilizationRecs = createUpdateResourceUtilizationHelperForNewRecords(ra,existingRefUtilizationRecMap.get(ra.Resource__c).values(), resourceAllocationParentMap);
                    }
                    else{
                        updatedUtilizationRecs = createUpdateResourceUtilizationHelperForNewRecords(ra,null, resourceAllocationParentMap);
                    }
                    
                }
                else{
                    
                     if(existingRefUtilizationRecMap.containsKey(ra.Resource__c)){
                       updatedUtilizationRecs = UpdateResourceUtilizationHelperForNewOldRecords(ra,existingRefUtilizationRecMap.get(ra.Resource__c).values());
                    }
                    else{
                       //  updatedUtilizationRecs = UpdateResourceUtilizationHelperForNewOldRecords(ra,null);
                    }
                    
                   
                }
                resourceUtilizationRecords.addAll(updatedUtilizationRecs);
            }
            system.debug('resourceUtilizationRecords '+resourceUtilizationRecords);
            return resourceUtilizationRecords;
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'create or update resource Utilization records helper on insert or update of resource allocation records', ex.getStackTraceString());
            return resourceUtilizationRecords;
        }
    }

    public static List<Resource_Utilization__c> createUpdateResourceUtilizationHelperForNewRecords(Resource_Allocation__c resourceAllocation, List<Resource_Utilization__c> existingRefUtilizationRecs, Map<Id, Resource__c> resourceAllocationParentMap){
        List<Resource_Utilization__c> resourceUtilizationList = new List<Resource_Utilization__c>();
        try{
            System.debug('existingRefUtilizationRecs '+existingRefUtilizationRecs);
            Map<string, string> calculatedTimeSlots = calculateTimeSlots(resourceAllocation.Allocated_Start_DateTime__c, resourceAllocation.Allocated_End_Datetime__c);
            System.debug('calculatedTimeSlots '+calculatedTimeSlots);
            List<Date> datesWithNoUtilizationRecord = new List<Date>();
            for(string slotDate :calculatedTimeSlots.keySet()){
                system.debug('slotDate '+slotDate);
                boolean existingRecFound = false;
                if(existingRefUtilizationRecs != null && !existingRefUtilizationRecs.isEmpty()){
                    for(Resource_Utilization__c ref :existingRefUtilizationRecs){
                        system.debug('ref '+ref);
                        if(ref.Utilization_Date__c == Date.valueOf(slotDate)){
                            existingRecFound = true;
                            string newTimeSlots = calculatedTimeSlots.get(slotDate);
                            string finalSlots = '';
                            if(ref.Booked_Time_Slots__c != null){
                                finalSlots = ref.Booked_Time_Slots__c+';'+newTimeSlots;
                            }
                            else{
                                finalSlots = newTimeSlots;
                            }
                            Resource_Utilization__c resEff = new Resource_Utilization__c(Id = ref.Id, 
                                Booked_Time_Slots__c = finalSlots);
                                system.debug('resEff '+resEff);
                            resourceUtilizationList.add(resEff);
                        }
                    } 
                }
                if(!existingRecFound){
                    //create new Utilization record for this date
                    datesWithNoUtilizationRecord.add(Date.valueOf(slotDate));
                }
            }
            if(datesWithNoUtilizationRecord != null && datesWithNoUtilizationRecord.size() > 0){
                system.debug('datesWithNoUtilizationRecord '+datesWithNoUtilizationRecord);
                Date minDate = null;
                Date maxDate = null;
                for(Date dt :datesWithNoUtilizationRecord){
                    system.debug('dt in loop '+dt);
                    if(minDate == null){
                        minDate = dt;
                    }
                    if(maxDate == null){
                        maxDate = dt;
                    }
                    minDate = minDate < dt ? minDate : dt;
                    maxDate = maxDate > dt ? maxDate : dt;
                    system.debug('minDate in loop '+minDate);
                    system.debug('maxDate in loop '+maxDate);
                }
                system.debug('minDate '+minDate);
                system.debug('maxDate '+maxDate);
                Integer i = minDate.daysBetween(maxDate) + 1;
                List<Resource_Utilization__c> resEffList = roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(
                    new set<Id>{resourceAllocation.Resource__c}, minDate, i, false
                );
                for(Resource_Utilization__c resEff :resEffList){
                    for(Date dt :datesWithNoUtilizationRecord){
                        if(resEff.Utilization_Date__c == dt){
                            system.debug('String.valueOf(dt) '+String.valueOf(dt));
                            resEff.Booked_Time_Slots__c = calculatedTimeSlots.get(String.valueOf(dt));
                            system.debug('resEff '+resEff);
                            resourceUtilizationList.add(resEff);
                        }
                    }
                }
            }
            
            system.debug('resourceUtilizationList '+resourceUtilizationList);
            return resourceUtilizationList;
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'create or update resource Utilization helper records on insert or update of new resource allocation records', ex.getStackTraceString());
            return resourceUtilizationList;
        }
    }

    public static List<Resource_Utilization__c> UpdateResourceUtilizationHelperForNewOldRecords(Resource_Allocation__c resourceAllocation, List<Resource_Utilization__c> existingRefUtilizationRecs){
        List<Resource_Utilization__c> resourceUtilizationList = new List<Resource_Utilization__c>();
        try{
            Map<string, string> calculatedTimeSlots = calculateTimeSlots(resourceAllocation.Allocated_Start_DateTime__c, resourceAllocation.Allocated_End_Datetime__c);
            for(string slotDate :calculatedTimeSlots.keySet()){
                for(Resource_Utilization__c ref :existingRefUtilizationRecs){
                    if(ref.Utilization_Date__c == Date.valueOf(slotDate)){
                        string timeSlotToRemove = calculatedTimeSlots.get(slotDate);
                        List<String> updatedTimeSlots = new List<String>();
                        for(String ts :ref.Booked_Time_Slots__c.split(';')){
                            if(timeSlotToRemove != ts){
                                updatedTimeSlots.add(ts);
                            }
                        }
                        Resource_Utilization__c resEff = new Resource_Utilization__c(Id = ref.Id, 
                            Booked_Time_Slots__c = String.join(updatedTimeSlots,';'));
                        resourceUtilizationList.add(resEff);
                    }
                }
            }
            return resourceUtilizationList;
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'update resource Utilization helper records on update of old resource allocation records', ex.getStackTraceString());
            return resourceUtilizationList;
        }
    }

    public static Map<string, string> calculateTimeSlots(Datetime startDateTime, Datetime endDateTime){
        Map<string, string> dividedTimeSlots = new Map<string, string> ();
        try{
            if(startDateTime > endDateTime){
                throw new roResourceOptimiserCustomException('Start date time is greater than End date time');
               
            }
            else{
                if(startDateTime.dateGMT() == endDateTime.dateGMT()){
                    decimal starthours = (startDateTime.hourGMT() * 60) +  startDateTime.minuteGMT();
                    decimal endhours = (endDateTime.hourGMT() * 60) +  endDateTime.minuteGMT();
                    decimal workhours = (endhours - starthours)/60;
                    dividedTimeSlots.put(string.valueOf(startDateTime.dateGMT()), starthours+'-'+endhours);
                }
                else{
                    Date startDate = startDateTime.dateGMT();
                    Date endDate = endDateTime.dateGMT();
                    date currentDate = startDate;
                    while(currentDate <= endDate){
                        System.debug('currentDate '+currentDate);
                        String timeSlot = '';
                        if(currentDate == startDate){
                            timeSlot = string.valueOf((startDateTime.hourGMT() * 60) + startDateTime.minuteGMT())+'-1440';
                            
                        }
                        else if(currentDate == endDate){
                            timeSlot = '0-'+string.valueOf((endDateTime.hourGMT() * 60) + endDateTime.minuteGMT());
                        }
                        else{
                            timeSlot = '0-1440';
                        }
                        dividedTimeSlots.put(String.valueOf(currentDate), timeSlot);
                        currentDate = currentDate.addDays(1);
                    }
                }
                return dividedTimeSlots;
            }
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'calculating time slots spanning multiple days', ex.getStackTraceString());
            return dividedTimeSlots;
        }
    }

}