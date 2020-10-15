/************************************************************************ 
Author : Santosh Rao Bompally 
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roAppointmentBookerController {

    public static Id dateUtilizationRecTypeId  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Daily Utilization').getRecordTypeId();
    public static ResourceOptimizerConfig__c orgConfig = [SELECT Id, Resource_Start_Hours__c, Resource_Start_Minutes__c, 
    Resource_End_Hours__c, Resource_End_Minutes__c, Organization_Weekends__c FROM ResourceOptimizerConfig__c LIMIT 1];

    @AuraEnabled
    public static List<resourceAvailableJson> getAvailableSlotsD(List<Id> resourceIds, String allocationDateString, string selectedTimezone){
        System.debug('Inputparams-'+resourceIds);
        System.debug('Inputparams-'+allocationDateString+'-'+selectedTimezone);
        string currentUserTimeZone = string.valueOf(UserInfo.getTimeZone());
        Date allocationDate = Date.valueOf(allocationDateString);
        Datetime startDateTime = Datetime.newInstance(allocationDate, Time.newInstance(0, 0, 0, 0));
        system.debug('SDT'+startDateTime);
        Long startBaseGMT = Datetime.valueOf(startDateTime.format('yyyy-MM-dd HH:mm:ss')).getTime();
        system.debug('X'+startBaseGMT);
        Long startTargetGMT = Datetime.valueOf(startDateTime.format('yyyy-MM-dd HH:mm:ss', selectedTimezone)).getTime();
        system.debug('X+8'+startTargetGMT);
        Long startSourceGMT = Datetime.valueOf(startDateTime.format('yyyy-MM-dd HH:mm:ss', currentUserTimeZone)).getTime();
        system.debug('X+12'+startSourceGMT);
        if(startTargetGMT > startSourceGMT){
            
            Long startDiff = startTargetGMT - startSourceGMT;
            startBaseGMT = startBaseGMT - startDiff;
            system.debug('A-1'+startBaseGMT);
        }
        else if(startTargetGMT < startSourceGMT){
            Long startDiff = startSourceGMT - startTargetGMT;
            startBaseGMT = startBaseGMT + startDiff;
            system.debug('A-2'+startBaseGMT);
        }
        
        system.debug('A'+startBaseGMT);
        DateTime startDateTimeFinal = Datetime.valueOf(startBaseGMT);
        DateTime endDateTimeFinal = startDateTimeFinal.addHours(24);
        
        System.debug('datecheck'+startDateTimeFinal);
        System.debug('datecheckend'+endDateTimeFinal);
        System.debug('datecheckend'+string.valueOf(startDateTimeFinal));
        System.debug('datecheckend'+string.valueOf(endDateTimeFinal));
        //system.debug('startdatetimecheck'+startDateTimeFinal.formatGMT('yyyy-mm-dd HH:MM:SS') );
        

        return getAvailableSlots(resourceIds, string.valueOf(startDateTimeFinal), string.valueOf(endDateTimeFinal), selectedTimezone);
    }


    @AuraEnabled
    public static List<resourceAvailableJson> getAvailableSlots(List<Id> resourceIds, String startDateTimeFinalString, String endDateTimeFinalString, string selectedTimezone){
        try{
            Map<Id, List<Resource_Available_Hours__c>> resourceAvailMap = new Map<Id, List<Resource_Available_Hours__c>>();
            Map<Id, DateTime> resourceStartTime = new Map<Id, DateTime>();
            Map<Id, DateTime> resourceEndTime = new Map<Id, DateTime>();
            Map<Id, List<string>> resourceAvailableSlotsMap = new Map<Id, List<string>>();
            List<resourceAvailableJson> resouceAvailableJSONList = new List<resourceAvailableJson>();
			system.debug('startDateTimeFinal '+startDateTimeFinalString);
            system.debug('endDateTimeFinal '+endDateTimeFinalString);
            Datetime startDateTimeFinal = Datetime.valueOf(startDateTimeFinalString);
            Datetime endDateTimeFinal = Datetime.valueOf(endDateTimeFinalString);
            system.debug('startDateTimeFinal '+startDateTimeFinal);
            system.debug('endDateTimeFinal '+endDateTimeFinal);
            system.debug('resourceIds '+resourceIds);
           
            system.debug('Santoshcheckstring2'+[SELECT Id, Start_time__c, End_Time__c, Resource_Utilization__c, 
                Resource_Utilization__r.Resource__c, Resource_Utilization__r.Resource__r.First_Name__c, 
                Resource_Utilization__r.Resource__r.Last_Name__c, Resource_Utilization__r.Booked_Time_Slots__c, Resource_Utilization__r.Utilization_Date__c 
                FROM Resource_Available_Hours__c ]);
        /* List<Resource_Available_Hours__c> availableHours = [SELECT Id, Start_time__c, End_Time__c, Resource_Utilization__c, 
                Resource_Utilization__r.Resource__c, Resource_Utilization__r.Resource__r.First_Name__c, 
                Resource_Utilization__r.Resource__r.Last_Name__c, Resource_Utilization__r.Booked_Time_Slots__c, Resource_Utilization__r.Utilization_Date__c 
                FROM Resource_Available_Hours__c WHERE Resource_Utilization__r.Resource__c IN :resourceIds  
                AND Start_time__c >=  :startDateTimeFinal AND End_Time__c <= :endDateTimeFinal]; */
            List<Resource_Available_Hours__c> availableHours = [SELECT Id, Start_time__c, End_Time__c, Resource_Utilization__c, 
                Resource_Utilization__r.Resource__c, Resource_Utilization__r.Resource__r.First_Name__c, 
                Resource_Utilization__r.Resource__r.Last_Name__c, Resource_Utilization__r.Booked_Time_Slots__c, Resource_Utilization__r.Utilization_Date__c 
                FROM Resource_Available_Hours__c WHERE Resource_Utilization__r.Resource__c IN :resourceIds  
                AND ((Start_time__c >=  :startDateTimeFinal AND End_Time__c <= :endDateTimeFinal) OR (Start_time__c <=  :startDateTimeFinal AND End_Time__c >= :startDateTimeFinal ) OR (Start_time__c <=  :endDateTimeFinal AND End_Time__c >= :endDateTimeFinal))
                Order By Resource_Utilization__r.Resource__r.First_Name__c ASC];
          system.debug('availableHours '+availableHours);
           
            for(Resource_Available_Hours__c availHours :availableHours){
                List<Resource_Available_Hours__c> availHoursTemp = resourceAvailMap.containsKey(availHours.Resource_Utilization__r.Resource__c) ? resourceAvailMap.get(availHours.Resource_Utilization__r.Resource__c) : new List<Resource_Available_Hours__c>();
                availHoursTemp.add(availHours);
                resourceAvailMap.put(availHours.Resource_Utilization__r.Resource__c, availHoursTemp);
                DateTime startTime = startDateTimeFinal > availHours.Start_time__c ? startDateTimeFinal : availHours.Start_time__c;
                if(resourceStartTime.containsKey(availHours.Resource_Utilization__r.Resource__c)){
                    startTime = startTime < resourceStartTime.get(availHours.Resource_Utilization__r.Resource__c) ? startTime : resourceStartTime.get(availHours.Resource_Utilization__r.Resource__c);
                }
                resourceStartTime.put(availHours.Resource_Utilization__r.Resource__c, startTime);

                DateTime endTime = endDateTimeFinal < availHours.End_Time__c ? endDateTimeFinal : availHours.End_Time__c;
                if(resourceEndTime.containsKey(availHours.Resource_Utilization__r.Resource__c)){
                    endTime = endTime > resourceEndTime.get(availHours.Resource_Utilization__r.Resource__c) ? endTime : resourceEndTime.get(availHours.Resource_Utilization__r.Resource__c);
                }
                resourceEndTime.put(availHours.Resource_Utilization__r.Resource__c, endTime);

            }
            system.debug('resourceAvailMap '+resourceAvailMap);
            system.debug('resourceStartTime '+resourceStartTime);
            system.debug('resourceEndTime '+resourceEndTime);
            Map<Id, Resource__c> resourceMap = new Map<Id, Resource__c>([SELECT Id, First_Name__c, Last_Name__c, FullName__c 
                FROM Resource__c WHERE Id IN :resourceAvailMap.keySet()]);

            for(Id resId :resourceAvailMap.keySet()){
                set<Id> processedResource = new set<Id>();
                //from Utilization get actual start and end time also get booked time slots
                if(resourceAvailMap.containsKey(resId)){
                    List<slot> slots = new List<slot>();
                    for(Resource_Available_Hours__c resAvail :resourceAvailMap.get(resId)){
                       
                           
                            system.debug('resAvail '+resAvail);
                            List<string> BookedSlotList = new List<string>();
                            string bookedSlot = resAvail.Resource_Utilization__r.Booked_Time_Slots__c;     
                            system.debug('bookedSlot '+bookedSlot);      
                            Integer startTimeCompare = 0;
                            Integer endTimeCompare = 1440;
                            DateTime resourceStartTimeCompareDateTime = resourceStartTime.get(resId);
                            DateTime resourceEndTimeCompareDateTime = resourceEndTime.get(resId);
                            system.debug('resourceStartTimeCompareDateTime '+resourceStartTimeCompareDateTime);
                            system.debug('resourceEndTimeCompareDateTime '+resourceEndTimeCompareDateTime);
                            system.debug('resAvail.Resource_Utilization__r.Utilization_Date__c '+resAvail.Resource_Utilization__r.Utilization_Date__c);
                         
                        system.debug('santoshdebug'+resourceStartTime.get(resId).dateGMT());
                        system.debug('santoshdebug'+resourceEndTime.get(resId).dateGMT());
                        
                        if(resAvail.Start_time__c.dateGMT() == resAvail.End_Time__c.dateGMT()){
                             if(resAvail.Start_time__c >= resourceStartTimeCompareDateTime){
                                startTimeCompare = resAvail.Start_time__c.hourGMT() * 60+ resAvail.Start_time__c.minuteGmt();
                            }else{
                                startTimeCompare = resourceStartTimeCompareDateTime.hourGMT() * 60 + resourceStartTimeCompareDateTime.minuteGmt();
                            }
                            
                            if(resAvail.End_Time__c <= resourceEndTimeCompareDateTime){
                                endTimeCompare = resAvail.End_Time__c.hourGMT() * 60+ resAvail.End_Time__c.minuteGmt();
                            }else{
                                endTimeCompare = resourceEndTimeCompareDateTime.hourGMT() * 60 + resourceEndTimeCompareDateTime.minuteGmt();
                            }
                           
                        }else if(resAvail.Resource_Utilization__r.Utilization_Date__c == resourceStartTime.get(resId).dateGMT()){
                            resourceEndTimeCompareDateTime = DateTime.newInstanceGMT(resourceStartTime.get(resId).dateGmt().addDays(1), Time.newInstance(0, 0, 0, 0));
                            
                             if(resAvail.Start_time__c >= resourceStartTimeCompareDateTime){
                                startTimeCompare = resAvail.Start_time__c.hourGMT() * 60+ resAvail.Start_time__c.minuteGmt();
                            }else{
                                startTimeCompare = resourceStartTimeCompareDateTime.hourGMT() * 60 + resourceStartTimeCompareDateTime.minuteGmt();
                            }
                            
                            
                                endTimeCompare = 1440;
                            
                            
                            
                          } else if(resAvail.Resource_Utilization__r.Utilization_Date__c == resourceEndTime.get(resId).dateGMT()){
                             resourceStartTimeCompareDateTime = DateTime.newInstanceGMT(resourceStartTime.get(resId).dateGmt(), Time.newInstance(0, 0, 0, 0));
                              
                              
                                startTimeCompare = 0;
                            
                            
                            if(resAvail.End_Time__c <= resourceEndTimeCompareDateTime){
                                endTimeCompare = resAvail.End_Time__c.hourGMT() * 60+ resAvail.End_Time__c.minuteGmt();
                            }else{
                                endTimeCompare = resourceEndTimeCompareDateTime.hourGMT() * 60 + resourceEndTimeCompareDateTime.minuteGmt();
                            }
                        }
                        
                        
                        
                        
                        
                      
                        
                            system.debug('startTimeCompare '+startTimeCompare);
                            system.debug('endTimeCompare '+endTimeCompare);
                            system.debug('resourceStartTimeCompareDateTime '+resourceStartTimeCompareDateTime);
                            system.debug('resourceEndTimeCompareDateTime '+resourceEndTimeCompareDateTime);            
                            if(bookedSlot != null && bookedSlot != ''){
                                for(string slot :bookedSlot.split(';')){
                                    Integer startSlot = Integer.valueOf(slot.split('-')[0]);
                                    Integer endSlot = Integer.valueOf(slot.split('-')[1]);
                                    if(startSlot >= startTimeCompare && endSlot <= endTimeCompare){
									BookedSlotList.add(String.valueOf(startSlot)+'-'+String.valueOf(endSlot));
								
								}else if(startSlot < startTimeCompare && endSlot > startTimeCompare){
									startSlot = startTimeCompare;
									BookedSlotList.add(String.valueOf(startSlot)+'-'+String.valueOf(endSlot));
								
								}else if(startSlot < endTimeCompare && endSlot > endTimeCompare){
									endSlot = endTimeCompare;
									BookedSlotList.add(String.valueOf(startSlot)+'-'+String.valueOf(endSlot));
								
								}
                                }
                                
                            }
                                system.debug('BookedSlotList '+BookedSlotList);
               // Still to Verify 
                        if(BookedSlotList.size()>0){    
                                List<Integer> startSlotsList = new List<Integer>();
                                List<Integer> endSlotsList = new List<Integer>();
                                for(string slot :BookedSlotList){
                                    startSlotsList.add(Integer.valueOf(slot.split('-')[0]));
                                    endSlotsList.add(Integer.valueOf(slot.split('-')[1]));
                                }
                                startSlotsList.sort();
                                endSlotsList.sort();
                                system.debug('startTimeCompare '+startTimeCompare);
                                system.debug('startSlotsList '+startSlotsList);
                                system.debug('endSlotsList '+endSlotsList);
                                system.debug('endTimeCompare '+endTimeCompare);
                                
                                if(startSlotsList.size()>0 && endSlotsList.size()>0){
                                    
                                    Integer startSlot = startTimeCompare;
                                    Integer endSlot = endTimeCompare;
                                    boolean slotidentified = false;
                                    for(Integer idx = 0; idx <= startSlotsList.size(); idx++){
                                  //  system.debug('idx '+idx+' startSlotsList[idx] '+startSlotsList[idx]+' endSlotsList[idx] '+endSlotsList[idx]);
                                    system.debug('got in '+idx);
                                        slotidentified = false;
                                        if(idx == 0){
                                            system.debug('got in '+startSlotsList[idx] +'-'+startTimeCompare); 
                                            if(startSlotsList[idx] > startTimeCompare){
                                               
                                                startSlot = startTimeCompare;
                                                endSlot = startSlotsList[idx];
                                                slotidentified = true;
                                            }
                                            
                                        }else if(idx < startSlotsList.size()){
                                            
                                            if(startSlotsList[idx] > endSlotsList[idx-1] ){
                                                startSlot = endSlotsList[idx-1];
                                                endSlot = startSlotsList[idx];
                                                slotidentified = true;
                                            }
                                            
                                        }else{
                                            if(endSlotsList[idx-1] < endTimeCompare){
                                                startSlot = endSlotsList[idx-1];
                                                endSlot = endTimeCompare;
                                                slotidentified = true;
                                            }
                                            
                                        }
                                        
                                       // startSlot = endSlotsList[idx] < startTimeCompare ? startTimeCompare : endSlotsList[idx];
                                      //  endSlot = (idx == startSlotsList.size() - 1 || endTimeCompare < startSlotsList[idx + 1]) ? endTimeCompare : startSlotsList[idx + 1];
                                        if(slotidentified) { 
                                        //start slot
                                        Integer startHour = startSlot/60;
                                        Integer startMinute = Math.mod(startSlot,60);
                                       
                                        Datetime startSlotDateTime = Datetime.newInstanceGmt(resAvail.Resource_Utilization__r.Utilization_Date__c, Time.newInstance(startHour, startMinute, 0, 0));

                                        //end slot
                                        Integer endHour = endSlot/60;
                                        Integer endMinute = Math.mod(endSlot,60);
                                        system.debug('endslot '+endslot+'endHour'+endHour+'endMinute'+endMinute);
                                        Datetime endSlotDateTime = endslot <> 1440 ? Datetime.newInstanceGmt(resAvail.Resource_Utilization__r.Utilization_Date__c, Time.newInstance(endHour, endMinute, 0, 0)):Datetime.newInstanceGmt(resAvail.Resource_Utilization__r.Utilization_Date__c.adddays(1), Time.newInstance(0, 0, 0, 0));
                                        system.debug('startSlotDateTime '+startSlotDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\''));
                                        system.debug('endSlotDateTime '+endSlotDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\''));
                                        slots.add(new slot(startSlotDateTime, endSlotDateTime,startSlotDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\'',selectedTimezone), endSlotDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\'',selectedTimezone)));
                                            
                                        }
                                    
                                }
                                }
                                
                                system.debug('slots '+slots);
                            }
                            else{
                                		Integer startSlot = startTimeCompare;
                                        Integer endSlot = endTimeCompare;
                                
                                        Integer startHour = startSlot/60;
                                        Integer startMinute = Math.mod(startSlot,60);
                                       
                                        Datetime startSlotDateTime = Datetime.newInstanceGmt(resAvail.Resource_Utilization__r.Utilization_Date__c, Time.newInstance(startHour, startMinute, 0, 0));

                                        //end slot
                                        Integer endHour = endSlot/60;
                                        Integer endMinute = Math.mod(endSlot,60);
                                        system.debug('endslot '+endslot+'endHour'+endHour+'endMinute'+endMinute);
                                        Datetime endSlotDateTime = endslot <> 1440 ? Datetime.newInstanceGmt(resAvail.Resource_Utilization__r.Utilization_Date__c, Time.newInstance(endHour, endMinute, 0, 0)):Datetime.newInstanceGmt(resAvail.Resource_Utilization__r.Utilization_Date__c.adddays(1), Time.newInstance(0, 0, 0, 0));
                                        system.debug('startSlotDateTime '+startSlotDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\''));
                                        system.debug('endSlotDateTime '+endSlotDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\''));
                                        slots.add(new slot(startSlotDateTime, endSlotDateTime,startSlotDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\'',selectedTimezone), endSlotDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\'',selectedTimezone)));
                               
                                system.debug('slots '+slots);
                            }
                        }
                        slots.sort();
                        resouceAvailableJSONList.add(new resourceAvailableJson(resourceMap.get(resId), slots));
                }
            }
            system.debug('resouceAvailableJSONList '+resouceAvailableJSONList);
            return resouceAvailableJSONList;
        }
        catch(exception ex){
            system.debug('Appointment booking: Get available slots error '+ex.getMessage()+' at '+ex.getStackTraceString());
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'Appointment booking: Get available slots error', ex.getStackTraceString());
            return null;
        }
    }

    public class resourceAvailableJson{
        public resourceAvailableJson(Resource__c resource, List<slot> slots){
            this.resource = resource;
            this.slots = slots;
        }
        @AuraEnabled
        public Resource__c resource {get; set;}
        @AuraEnabled
        public List<slot> slots {get; set;}
        
        
    }

    public class slot implements Comparable{
        public slot(datetime startdatetime, datetime enddatetime,string startdatetimeTZ, string enddatetimeTZ){
            this.startdatetime = startdatetime;
            this.enddatetime = enddatetime;
            this.startdatetimeGMT = startdatetime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\'');
            this.enddatetimeGMT = enddatetime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\'');
            this.startdatetimeTZ =  startdatetimeTZ;
            this.enddatetimeTZ = enddatetimeTZ;
            this.starttimeTZ = this.startdatetimeTZ.substring(11,16);
            this.endtimeTZ = this.enddatetimeTZ.substring(11,16);
          //  Integer somt =  Integer.valueOf((enddatetime-startdatetime)*24*60) ;
           }
        @AuraEnabled
        public datetime startdatetime {get; set;}
        @AuraEnabled
        public datetime enddatetime {get; set;}
        @AuraEnabled
        public string startdatetimeGMT {get; set;}
        @AuraEnabled
        public string enddatetimeGMT {get; set;}
        @AuraEnabled
        public string startdatetimeTZ {get; set;}
        @AuraEnabled
        public string enddatetimeTZ {get; set;}
        @AuraEnabled
        public string starttimeTZ {get; set;}
        @AuraEnabled
        public string endtimeTZ {get; set;}
         @AuraEnabled
        public Integer slottime {get; set;}
        
         public Integer compareTo(Object compareTo){
         	 slot otherslot = (slot)compareTo;
         
             if(startdatetime == otherslot.startdatetime){
                  return 0;
                } else if(startdatetime < otherslot.startdatetime){
                  return -1;
                } else {
                  return 1;
                }
    		 } 
    }
    
}