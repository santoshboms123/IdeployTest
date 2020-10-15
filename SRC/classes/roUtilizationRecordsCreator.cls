/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roUtilizationRecordsCreator {

    public static Id dateUtilizationRecTypeId  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Daily Utilization').getRecordTypeId();
    public static ResourceOptimizerConfig__c orgConfig {get; set;}

    public roUtilizationRecordsCreator() {

    }

    public static List<Resource_Utilization__c> createAvailableHoursAndUtilizationsForResource(set<Id> resourceIds, Date startDate, Integer NumberOfDays, boolean skipWeekOffs){
        try{
            system.debug('resourceIds '+resourceIds);
            orgConfig = [SELECT Id, Resource_Start_Hours__c, Resource_Start_Minutes__c, 
                Resource_End_Hours__c, Resource_End_Minutes__c, Organization_Weekends__c FROM ResourceOptimizerConfig__c LIMIT 1];
            system.debug('orgConfig '+orgConfig);
            set<Date> utilizationRecDates = new set<Date>();
            Map<Id, set<Date>> datesUtilToCreateRecs = new Map<Id, set<Date>>();
            string currentUserTimeZone = string.valueOf(UserInfo.getTimeZone());
            string defaultTimeZone = [SELECT Id, TimeZoneSidKey FROM Organization].TimeZoneSidKey;
            Map<Id, Map<Date, Resource_Utilization__c>> resourceToUtilizationDateMap = new Map<Id, Map<Date, Resource_Utilization__c>>();
            Map<Id, Map<Date, List<Resource_Available_Hours__c>>> availableHoursToCreate = new Map<Id, Map<Date, List<Resource_Available_Hours__c>>>();
            List<Resource_Utilization__c> newUtilRecordsToCreate = new List<Resource_Utilization__c>();
            List<Resource_Available_Hours__c> availableHoursWithParentIdToInsert = new List<Resource_Available_Hours__c>();

            for(Integer i = 0; i < NumberOfDays; i++){
                utilizationRecDates.add(startDate.Adddays(i));
            }

            Map<Id, Resource__c> resourceMap = new Map<Id, Resource__c>([SELECT Id, Resource_Time_Zone__c, Resource_Group__r.Resource_Group_Default_Start_Time__c, 
                Resource_Group__r.Resource_Group_Default_End_Time__c, Resource_Default_Start_Time__c, Resource_Default_End_Time__c, Week_Offs__c FROM Resource__c WHERE Id IN :resourceIds]);

            List<Resource_Utilization__c> resUtilizationList = [SELECT Id, Utilization_Date__c, Resource__c FROM Resource_Utilization__c WHERE Resource__c IN :resourceIds AND 
            Utilization_Date__c IN :utilizationRecDates AND RecordTypeId = :dateUtilizationRecTypeId];
            system.debug('resUtilizationList '+resUtilizationList);

            for(Resource_Utilization__c rut :resUtilizationList){
                Map<Date, Resource_Utilization__c> tempUtilDateMap = resourceToUtilizationDateMap.containsKey(rut.Resource__c) ? resourceToUtilizationDateMap.get(rut.Resource__c) : new Map<Date, Resource_Utilization__c>();
                tempUtilDateMap.put(rut.Utilization_Date__c, rut);
                resourceToUtilizationDateMap.put(rut.Resource__c, tempUtilDateMap);
            }
            system.debug('resourceToUtilizationDateMap '+resourceToUtilizationDateMap);
            
            for(Id resId :resourceIds){
                system.debug('resId '+resId);
                string resourcetimeZone = resourceMap.get(resId).Resource_Time_Zone__c != null ? resourceMap.get(resId).Resource_Time_Zone__c : defaultTimeZone;
                Time defaultStartTime = null;
                Time defaultEndTime = null;
                if(resourceMap.get(resId).Resource_Default_Start_Time__c != null && resourceMap.get(resId).Resource_Default_End_Time__c != null){
                    defaultStartTime = resourceMap.get(resId).Resource_Default_Start_Time__c;
                    defaultEndTime = resourceMap.get(resId).Resource_Default_End_Time__c;
                    system.debug('defaultStartTime from res '+defaultStartTime);
                    system.debug('defaultEndTime from res '+defaultEndTime);
                }
                else if(resourceMap.get(resId).Resource_Group__r.Resource_Group_Default_Start_Time__c != null && resourceMap.get(resId).Resource_Group__r.Resource_Group_Default_End_Time__c != null){
                    defaultStartTime = resourceMap.get(resId).Resource_Group__r.Resource_Group_Default_Start_Time__c;
                    defaultEndTime = resourceMap.get(resId).Resource_Group__r.Resource_Group_Default_End_Time__c;
                    system.debug('defaultStartTime from group '+defaultStartTime);
                    system.debug('defaultEndTime from group '+defaultEndTime);
                }
                else{
                    defaultStartTime = Time.newInstance(Integer.valueOf(orgConfig.Resource_Start_Hours__c), 
                        Integer.valueOf(orgConfig.Resource_Start_Minutes__c), 0, 0);
                    defaultEndTime = Time.newInstance(Integer.valueOf(orgConfig.Resource_End_Hours__c), 
                        Integer.valueOf(orgConfig.Resource_End_Minutes__c), 0, 0);
                    system.debug('defaultStartTime from config '+defaultStartTime);
                    system.debug('defaultEndTime from config '+defaultEndTime);
                }

                set<string> weekOffs = new set<string>();
                if(!string.isBlank(resourceMap.get(resId).Week_Offs__c)){
                    List<string> weekOffList = resourceMap.get(resId).Week_Offs__c.split(';');
                    weekOffs.addAll(weekOffList);
                    system.debug('weekOffs from res '+weekOffs);
                }
                else if(!string.isBlank(orgConfig.Organization_Weekends__c)){
                    List<string> weekOffList = orgConfig.Organization_Weekends__c.split(';');
                    weekOffs.addAll(weekOffList);
                    system.debug('weekOffs from config '+weekOffs);
                }
                
                Map<Date, List<Resource_Available_Hours__c>> existingAvailableHoursinMap = new Map<Date, List<Resource_Available_Hours__c>>();
                if(availableHoursToCreate.containsKey(resId)){
                    existingAvailableHoursinMap = availableHoursToCreate.get(resId);
                }
                for(Date utDate :utilizationRecDates){
                    boolean createUtilization = true;
                    if(skipWeekOffs){
                        Datetime dt = (DateTime)utDate;
                        system.debug('dt '+dt);
                        system.debug('dt format '+dt.format('EEEE'));
                        if(weekOffs.contains(dt.format('EEEE'))){
                            createUtilization = false;
                        }
                    }
                    if(createUtilization){
                        Integer TimeDifference = ((defaultEndTime.hour() * 60) + defaultEndTime.minute()) - ((defaultStartTime.hour() * 60) + defaultStartTime.minute());
                        Datetime startDateTime = Datetime.newInstance(utDate.year(), utDate.month(), utDate.day(), defaultStartTime.hour(), defaultStartTime.minute(), 00);
                        DateTime endDateTime;
                        if(TimeDifference > 0){
                            endDateTime = startDateTime.addMinutes(TimeDifference);
                        }
                        else{
                            endDateTime = Datetime.newInstance(utDate.year(), utDate.month(), utDate.day() + 1, defaultEndTime.hour(), defaultEndTime.minute(), 00);
                        }
                        system.debug('startDateTime '+startDateTime);
                        system.debug('endDateTime '+endDateTime);
                        DateTime startDateTimeFinal = null;
                        DateTime endDateTimeFinal = null;
                        if(!String.isBlank(resourcetimeZone)){
                            Long startBaseGMT = Datetime.valueOf(startDateTime.format('yyyy-MM-dd HH:mm:ss')).getTime();
                            Long endBaseGMT = Datetime.valueOf(endDateTime.format('yyyy-MM-dd HH:mm:ss')).getTime();
                            Long startTargetGMT = Datetime.valueOf(startDateTime.format('yyyy-MM-dd HH:mm:ss', resourcetimeZone)).getTime();
                            Long endTargetGMT = Datetime.valueOf(endDateTime.format('yyyy-MM-dd HH:mm:ss', resourcetimeZone)).getTime();
                            Long startSourceGMT = Datetime.valueOf(startDateTime.format('yyyy-MM-dd HH:mm:ss', currentUserTimeZone)).getTime();
                            Long endSourceGMT = Datetime.valueOf(endDateTime.format('yyyy-MM-dd HH:mm:ss', currentUserTimeZone)).getTime();
                            if(startTargetGMT > startSourceGMT && endTargetGMT > endSourceGMT){
                                Long startDiff = startTargetGMT - startSourceGMT;
                                Long endDiff = endTargetGMT - endSourceGMT;
                                if(startDiff == endDiff){
                                    startBaseGMT = startBaseGMT - startDiff;
                                    endBaseGMT = endBaseGMT - endDiff;
                                }
                            }
                            else if(startTargetGMT < startSourceGMT && endTargetGMT < endSourceGMT){
                                Long startDiff = startSourceGMT - startTargetGMT;
                                Long endDiff = endSourceGMT - endTargetGMT;
                                if(startDiff == endDiff){
                                    startBaseGMT = startBaseGMT + startDiff;
                                    endBaseGMT = endBaseGMT + endDiff;
                                }
                            }
                            startDateTimeFinal = Datetime.valueOf(startBaseGMT);
                            endDateTimeFinal = Datetime.valueOf(endBaseGMT);
                            
                            system.debug('resourcetimeZone '+resourcetimeZone);
                            system.debug('startDateTimeFinal with timezone '+startDateTimeFinal);
                            system.debug('endDateTimeFinal with timezone  '+endDateTimeFinal);
                        }
                        else{
                            startDateTimeFinal = Datetime.valueOf(startDateTime.format('yyyy-MM-dd HH:mm:ss'));
                            endDateTimeFinal = Datetime.valueOf(endDateTime.format('yyyy-MM-dd HH:mm:ss'));
                            system.debug('startDateTimeFinal no timezone '+startDateTimeFinal);
                            system.debug('endDateTimeFinal no timezone '+endDateTimeFinal);
                        }
                        if(startDateTimeFinal.dateGMT() == endDateTimeFinal.dateGMT()){
                            List<Resource_Available_Hours__c> availHours1 = existingAvailableHoursinMap.containsKey(startDateTimeFinal.dateGMT()) ? existingAvailableHoursinMap.get(startDateTimeFinal.dateGMT()) : new List<Resource_Available_Hours__c>();
                            availHours1.add(new Resource_Available_Hours__c(Start_time__c = startDateTimeFinal, End_Time__c = endDateTimeFinal));
                            existingAvailableHoursinMap.put(startDateTimeFinal.dateGMT(), availHours1);

                            if(resourceToUtilizationDateMap.containsKey(resId)){
                                if(!resourceToUtilizationDateMap.get(resId).containsKey(startDateTimeFinal.dateGMT())){
                                    Set<Date> utDateSet = datesUtilToCreateRecs.containsKey(resId) ? datesUtilToCreateRecs.get(resId) : new set<Date>();
                                    utDateSet.add(startDateTimeFinal.dateGMT());
                                    datesUtilToCreateRecs.put(resId, utDateSet);
                                }
                            }
                            else{
                                Set<Date> utDateSet = datesUtilToCreateRecs.containsKey(resId) ? datesUtilToCreateRecs.get(resId) : new set<Date>();
                                    utDateSet.add(startDateTimeFinal.dateGMT());
                                    datesUtilToCreateRecs.put(resId, utDateSet);
                            }
                        }
                        else if(startDateTimeFinal.dateGMT() == endDateTimeFinal.dateGMT() - 1){
                            system.debug('startDateTimeFinal.dateGMT() '+startDateTimeFinal.dateGMT());
                            system.debug('endDateTimeFinal.dateGMT() '+endDateTimeFinal.dateGMT());
                            Time dayStart = Time.newInstance(0, 0, 0, 0);
                            Time dayEnd = Time.newInstance(23, 59, 0, 0);

                            List<Resource_Available_Hours__c> availHours1 = existingAvailableHoursinMap.containsKey(startDateTimeFinal.dateGMT()) ? existingAvailableHoursinMap.get(startDateTimeFinal.dateGMT()) : new List<Resource_Available_Hours__c>();
                            availHours1.add(new Resource_Available_Hours__c(Start_time__c = startDateTimeFinal, 
                                End_Time__c = DateTime.newInstanceGMT(endDateTimeFinal.dateGMT(), dayStart)));
                            existingAvailableHoursinMap.put(startDateTimeFinal.dateGMT(), availHours1);

                            List<Resource_Available_Hours__c> availHours2 = existingAvailableHoursinMap.containsKey(endDateTimeFinal.dateGMT()) ? existingAvailableHoursinMap.get(startDateTimeFinal.dateGMT()) : new List<Resource_Available_Hours__c>();
                            availHours2.add(new Resource_Available_Hours__c(Start_time__c = DateTime.newInstanceGMT(endDateTimeFinal.dateGMT(), dayStart), 
                                End_Time__c = endDateTimeFinal));
                            existingAvailableHoursinMap.put(endDateTimeFinal.dateGMT(), availHours2);

                                if(resourceToUtilizationDateMap.containsKey(resId)){
                                    if(!resourceToUtilizationDateMap.get(resId).containsKey(startDateTimeFinal.dateGMT())){
                                        Set<Date> utDateSet = datesUtilToCreateRecs.containsKey(resId) ? datesUtilToCreateRecs.get(resId) : new set<Date>();
                                        utDateSet.add(startDateTimeFinal.dateGMT());
                                        datesUtilToCreateRecs.put(resId, utDateSet);
                                    }
                                }
                                else{
                                    Set<Date> utDateSet = datesUtilToCreateRecs.containsKey(resId) ? datesUtilToCreateRecs.get(resId) : new set<Date>();
                                        utDateSet.add(startDateTimeFinal.dateGMT());
                                        datesUtilToCreateRecs.put(resId, utDateSet);
                                }

                                if(resourceToUtilizationDateMap.containsKey(resId)){
                                    if(!resourceToUtilizationDateMap.get(resId).containsKey(endDateTimeFinal.dateGMT())){
                                        Set<Date> utDateSet = datesUtilToCreateRecs.containsKey(resId) ? datesUtilToCreateRecs.get(resId) : new set<Date>();
                                        utDateSet.add(endDateTimeFinal.dateGMT());
                                        datesUtilToCreateRecs.put(resId, utDateSet);
                                    }
                                }
                                else{
                                    Set<Date> utDateSet = datesUtilToCreateRecs.containsKey(resId) ? datesUtilToCreateRecs.get(resId) : new set<Date>();
                                        utDateSet.add(endDateTimeFinal.dateGMT());
                                        datesUtilToCreateRecs.put(resId, utDateSet);
                                }
                                system.debug('datesUtilToCreateRecs '+datesUtilToCreateRecs);
                        }
                    }
                    
                }
                availableHoursToCreate.put(resId, existingAvailableHoursinMap);
            }

            system.debug('datesUtilToCreateRecs final '+datesUtilToCreateRecs);
            if(datesUtilToCreateRecs != null && datesUtilToCreateRecs.keySet().size() > 0){
                for(Id resId :datesUtilToCreateRecs.keySet()){
                    if(datesUtilToCreateRecs.get(resId) != null && datesUtilToCreateRecs.get(resId).size() > 0){
                        for(Date utDate : datesUtilToCreateRecs.get(resId)){
                            newUtilRecordsToCreate.add(new Resource_Utilization__c( Resource__c = resId, Utilization_Date__c = utDate, RecordTypeId = dateUtilizationRecTypeId));
                        }
                    }
                }
            }

            system.debug('newUtilRecordsToCreate '+newUtilRecordsToCreate);
            system.debug('resourceToUtilizationDateMap '+resourceToUtilizationDateMap);
            set<id> allUtilizationRecIds = new set<Id>();
            if(newUtilRecordsToCreate != null && newUtilRecordsToCreate.size() > 0){
                Database.insert(newUtilRecordsToCreate);
                for(Resource_Utilization__c rut :newUtilRecordsToCreate){
                    Map<Date, Resource_Utilization__c> tempUtilDateMap = resourceToUtilizationDateMap.containsKey(rut.Resource__c) ? resourceToUtilizationDateMap.get(rut.Resource__c) : new Map<Date, Resource_Utilization__c>();
                    tempUtilDateMap.put(rut.Utilization_Date__c, rut);
                    resourceToUtilizationDateMap.put(rut.Resource__c, tempUtilDateMap);
                }
            }
            system.debug('newUtilRecordsToCreate '+newUtilRecordsToCreate);
            system.debug('resourceToUtilizationDateMap '+resourceToUtilizationDateMap);

            for(Id resId :availableHoursToCreate.keySet()){
                for(Date utDate :availableHoursToCreate.get(resId).keySet()){
                    for(Resource_Available_Hours__c rAv :availableHoursToCreate.get(resId).get(utDate)){
                        Id resUtId = resourceToUtilizationDateMap.get(resId).get(utDate).Id;
                        allUtilizationRecIds.add(resUtId);
                    }
                }
            }
            system.debug('allUtilizationRecIds '+allUtilizationRecIds);
            Map<Id, List<Resource_Available_Hours__c>> existingResourceAvailableHoursMap = new Map<Id, List<Resource_Available_Hours__c>>();
            for(Resource_Available_Hours__c resAv :[SELECT Id, Resource_Utilization__c, Start_Time__c, End_Time__c FROM Resource_Available_Hours__c WHERE Resource_Utilization__c IN :allUtilizationRecIds]){
                List<Resource_Available_Hours__c> tempListAvailHours = existingResourceAvailableHoursMap.containsKey(resAv.Resource_Utilization__c) ? existingResourceAvailableHoursMap.get(resAv.Resource_Utilization__c) :new List<Resource_Available_Hours__c>();
                tempListAvailHours.add(resAv);
                existingResourceAvailableHoursMap.put(resAv.Resource_Utilization__c, tempListAvailHours);
            }
            system.debug('existingResourceAvailableHoursMap '+existingResourceAvailableHoursMap);

            for(Id resId :availableHoursToCreate.keySet()){
                for(Date utDate :availableHoursToCreate.get(resId).keySet()){
                    for(Resource_Available_Hours__c rAv :availableHoursToCreate.get(resId).get(utDate)){
                        Id resUtId = resourceToUtilizationDateMap.get(resId).get(utDate).Id;
                        boolean createRAV = true;
                        if(existingResourceAvailableHoursMap.containsKey(resUtId)){
                            for(Resource_Available_Hours__c existingAvail :existingResourceAvailableHoursMap.get(resUtId)){
                                if(existingAvail.Start_Time__c == rAv.Start_Time__c && existingAvail.End_Time__c == rAv.End_Time__c){
                                    createRAV = false;
                                }
                            }
                        }
                        if(createRAV){
                            rAv.Resource_Utilization__c = resUtId;
                            availableHoursWithParentIdToInsert.add(rAv);
                        }
                    }
                }
            }         
            
            if(availableHoursWithParentIdToInsert != null && availableHoursWithParentIdToInsert.size() > 0){
                Database.insert(availableHoursWithParentIdToInsert);
            }

            List<Resource_Utilization__c> returnList = new List<Resource_Utilization__c>();
            for(Id res :resourceToUtilizationDateMap.keySet()){
                returnList.addAll(resourceToUtilizationDateMap.get(res).values());
            }
            return returnList;
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'Bulk resource vailable times Creator', ex.getStackTraceString());
            return null;
        }
    }
    
}