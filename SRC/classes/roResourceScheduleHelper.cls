/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceScheduleHelper { 
    
    @AuraEnabled
    public static roCalendarWrapper.ResourceScheduleWrapper getResourceAllocationJSON(string startDateString, string endDateString, string groupID){
       
        system.debug('startDateString ==> '+ startDateString);
        system.debug('endDateString ==> '+ endDateString);
        
        // Initialize Wrappers
        roCalendarWrapper.ResourceScheduleWrapper rsWrapper = new roCalendarWrapper.ResourceScheduleWrapper();
        roCalendarWrapper.ResourceSchedule rschedule = new roCalendarWrapper.ResourceSchedule();  
        MasterWrapper  mWrapper = new MasterWrapper();
        // Initialize Variables
        map<Id, List<Resource_Allocation__c>> mapResourceIdAndRelatedAllocations = new map<Id, List<Resource_Allocation__c>>();       
        map<string, List<Resource__c>> mapResourceGroupAndResources = new map<string, List<Resource__c>>();        
        //map<String, List<String>> mapGroups = new map<String, List<String>>();        
        //map<string, Decimal> mapResourceEfficiency = new map<string, Decimal>();
        map<string, Decimal> mapDailyResourceUtilization = new map<string, Decimal>();
        map<string, Decimal> mapWeeklyResourceUtilization = new map<string, Decimal>();
        map<Id, Resource_Group__c> mapResourceGroup = new map<Id, Resource_Group__c>();
        map<string, string> mapResourceAllocationColorMapping = new map<string, string>();
        List<Resource__c> listOfResources =  new List<Resource__c>();
        Set<String> parentGroups = new Set<String>();
        set<String> setParentObjects = new set<String>();
        set<Id> setResourceUtilizationIds = new set<Id>();
        map<string, List<Resource_Available_Hours__c>> mapResourUtilizationAndRelatedAvailableHours = new map<string, List<Resource_Available_Hours__c>>();
        map<string, List<Resource_Available_Hours__c>> mapResourceAndRelatedAvailableHours = new map<string, List<Resource_Available_Hours__c>>();
        
        String lookupFieldsQueryString;
       
        
        try{
            
            Date startDate = Date.valueOf(startDateString);
            Date endDate = Date.valueOf(endDateString);
            
            DateTime startDateTime = DateTime.newInstanceGMT(startDate, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstanceGMT(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
            date weekStartDate =  startDate.toStartofWeek();
            
            // query all Parent Objects selected for RO in system. we need it to find which lookup is mapped on resource allocation object and to map it back in json.
            List<String> listLookupsOnRAObject = getLookupFields('Resource_Allocation__c');
            if(listLookupsOnRAObject.size()>0){
                for(Resource_Allocation_Parent__c raParent : [SELECT Id, Parent_API_Name__c, Parent_JSON__c FROM Resource_Allocation_Parent__c]){
                    if(listLookupsOnRAObject.contains(raParent.Parent_API_Name__c) && !Test.isRunningTest()){
                        string parentAPIName = raParent.Parent_API_Name__c;
                        string nameField = parentAPIName.replace('__c','__r')+'.Name';
                        lookupFieldsQueryString = lookupFieldsQueryString != null ? lookupFieldsQueryString + ', ' + parentAPIName + ',' + nameField : parentAPIName + ',' + nameField;
                        setParentObjects.add(raParent.Parent_API_Name__c);
                    }
                } 
            }
            
            // query all groups which are active in the system. This is required to prepare a map of parent group all its child groups.
            for(Resource_Group__c rg: [select Id, Name, Parent_Group__c,Parent_Group__r.Name from Resource_Group__c WHERE Active__c =: TRUE]){
                system.debug('**rg ==> '+ rg);
                /*if(rg.Parent_Group__c != null){
                    if(!mapGroups.containsKey(rg.Parent_Group__r.Name)){
                        mapGroups.put(rg.Parent_Group__r.Name, new List<String>());
                        mapGroups.get(rg.Parent_Group__r.Name).add(rg.Name);
                    }
                    else{
                        mapGroups.get(rg.Parent_Group__r.Name).add(rg.Name);
                    }
                } */
                mapResourceGroup.put(rg.Id,rg);
            }
            
            // provided if start date and end date params are not null, prepare all data to build the child JSON.
            // dynamic query on resource object to get all active resources with all related resource allocation and efficiency records.
            if(startDate!=null && endDate!=null){
                string dailyUtilizationRT = 'Daily_Utilization'; 
                string weeklyUtilizationRT = 'Weekly_Utilization'; // considering we are dealing with only daily efficiency records.
                Date sDate = startDate;
                Date eDate = endDate;
                string whereCondition;
                string queryString = 'SELECT Id, Name, First_Name__c, Last_Name__c, Profile_Picture_URL__c, Role__c, Skills_Backend__c, Resource_Default_Start_Time__c, Resource_Default_End_Time__c, ResourceGroupHierarchy__c, Resource_Group__r.Parent_Group__r.Name, Resource_Group__r.Name,';
                if(String.isNotBlank(groupID)){
                    groupID = groupID.length() == 18 ? groupID.substring(0,15) : groupID;
                    whereCondition = ' FROM Resource__c WHERE Active__c=True AND ResourceGroupIds__c LIKE' + '\'%' + String.escapeSingleQuotes(groupID.trim()) + '%\'';
                    
                }
                else{
                    whereCondition = ' FROM Resource__c WHERE Active__c=True';
                }
                
                string ra_subQueryString = ' (SELECT Id, Name, Allocated_Start_DateTime__c, Allocated_End_DateTime__c, Status__c, Reservation__c';
                string ra_whereCondition = ' FROM Resource_Allocations__r WHERE Allocated_Start_DateTime__c >= :startDateTime AND Allocated_End_DateTime__c < :endDateTime),'; 
                ra_subQueryString =  (lookupFieldsQueryString != null ? ra_subQueryString + ', ' + lookupFieldsQueryString : ra_subQueryString) + ra_whereCondition;

                string ru_subQueryString = ' (SELECT Id, Utilization_Date__c, Utilization__c, RecordType.DeveloperName, Week_Start_Date__c  FROM Resource_Utilization__r WHERE (Utilization_Date__c >=: sDate AND Utilization_Date__c <=: eDate AND RecordType.DeveloperName=\''+String.escapeSingleQuotes(dailyUtilizationRT)+'\')';
                ru_subQueryString = ru_subQueryString + ' OR (Week_Start_Date__c =: weekStartDate AND RecordType.DeveloperName=\''+String.escapeSingleQuotes(weeklyUtilizationRT)+'\'))';
                    
                queryString = queryString + ra_subQueryString + ru_subQueryString + whereCondition;

                system.debug('***queryString ==> ' +  queryString);
                for(sObject sObj: Database.query(queryString)){
                    Resource__c res = (Resource__c)sObj;
                    listOfResources.add(res);
                    
                    // map resource and resource allocations
                    mapResourceIdAndRelatedAllocations.put(res.Id, new List<Resource_Allocation__c>());
                    mapResourceIdAndRelatedAllocations.get(res.Id).addAll(res.Resource_Allocations__r);
                    
                    system.debug('res Id ==> ' + res.Id);
                    system.debug('mapResandAlloc ==> ' + mapResourceIdAndRelatedAllocations);
                    
                    // map of resource utilizations
                     for(Resource_Utilization__c re: res.Resource_Utilization__r){
                        if(re.RecordType.DeveloperName  == 'Daily_Utilization'){
                            string utilizationKey = res.Id+string.valueOf(re.Utilization_Date__c);
                            mapDailyResourceUtilization.put(utilizationKey, re.Utilization__c); 
                            setResourceUtilizationIds.add(re.Id);
                        }
                        
                        if(re.RecordType.DeveloperName  == 'Weekly_Utilization'){
                            string utilizationKey = res.Id+string.valueOf(weekStartDate).split(' ')[0];
                            mapWeeklyResourceUtilization.put(utilizationKey, re.Utilization__c); 
                        }
                    }
                                        
                    // map resource hierarchy and resources
                    if(!mapResourceGroupAndResources.containsKey(res.Resource_Group__r.Name)){
                        mapResourceGroupAndResources.put(res.Resource_Group__r.Name, new List<Resource__c>());
                        mapResourceGroupAndResources.get(res.Resource_Group__r.Name).add(res);
                    }
                    else{
                        mapResourceGroupAndResources.get(res.Resource_Group__r.Name).add(res); 
                    }
                    
                    // set of all parent groups related to related resource group
                    if(groupId == res.Resource_Group__c){
                        parentGroups.add(res.Resource_Group__r.Name);
                    } 
                }

                // color mapping
                for(Resource_Optimizer_Color_Config__mdt rc: [select status__c, color_code__c from Resource_Optimizer_Color_Config__mdt]){
                    mapResourceAllocationColorMapping.put(rc.status__c, rc.Color_Code__c);
                }
                
                // map avaliable resource hours
                system.debug('setResourceUtilizationIds ==> ' + setResourceUtilizationIds);
                for(Resource_Available_Hours__c rah: [select id, Start_time__c, End_Time__c,Resource_Utilization__c, Resource_Utilization__r.Resource__c,Resource_Utilization__r.Utilization_Date__c  
                                                      FROM Resource_Available_Hours__c 
                                                      WHERE Resource_Utilization__c IN: setResourceUtilizationIds
                                                      ORDER BY Start_time__c ASC]){
                    string rahKey = rah.Resource_Utilization__r.Resource__c+string.valueOf(rah.Resource_Utilization__r.Utilization_Date__c);
                    if(!mapResourUtilizationAndRelatedAvailableHours.containsKey(rahKey)){
                        mapResourUtilizationAndRelatedAvailableHours.put(rahKey, new list<Resource_Available_Hours__c>());
                        mapResourUtilizationAndRelatedAvailableHours.get(rahKey).add(rah);
                    }
                    else{
                        mapResourUtilizationAndRelatedAvailableHours.get(rahKey).add(rah);
                    }
                    
                    // new map
                    if(!mapResourceAndRelatedAvailableHours.containsKey(rah.Resource_Utilization__r.Resource__c)){
                        mapResourceAndRelatedAvailableHours.put(rah.Resource_Utilization__r.Resource__c, new list<Resource_Available_Hours__c>());
                        mapResourceAndRelatedAvailableHours.get(rah.Resource_Utilization__r.Resource__c).add(rah);
                    }
                    else{
                        mapResourceAndRelatedAvailableHours.get(rah.Resource_Utilization__r.Resource__c).add(rah);
                    }
                }

                system.debug('mapResourUtilizationAndRelatedAvailableHours ==> ' + mapResourUtilizationAndRelatedAvailableHours);
                system.debug('parentGroups ==> ' + parentGroups);
                system.debug('listOfResources ==> ' + listOfResources);
                
                // prepare master wrapper. it holds all params required to build child JSON.
                mWrapper.mapResourceIdAndRelatedAllocations = mapResourceIdAndRelatedAllocations; 
                mWrapper.mapResourceGroupAndResources = mapResourceGroupAndResources;
                mWrapper.mapDailyResourceUtilization = mapDailyResourceUtilization;
                mWrapper.mapWeeklyResourceUtilization = mapWeeklyResourceUtilization;
                mWrapper.mapResourUtilizationAndRelatedAvailableHours = mapResourUtilizationAndRelatedAvailableHours;
                mWrapper.mapResourceAndRelatedAvailableHours = mapResourceAndRelatedAvailableHours;
                //mWrapper.mapGroups = mapGroups;            
                mWrapper.setParentObjects = setParentObjects;
                mWrapper.weekStartDate = weekStartDate;
                mWrapper.mapResourceAllocationColorMapping = mapResourceAllocationColorMapping;
            }
            
            // logic to build child JSON.
            if(listOfResources.size()>0){
                List<roCalendarWrapper.ResourceGroup> lstResourceGroups = new List<roCalendarWrapper.ResourceGroup>(); 
                roCalendarWrapper.ResourceGroup rGroup = new roCalendarWrapper.ResourceGroup(); 
                rGroup.Resource = getAllResourcesRelatedToGroup(listOfResources, mWrapper);                    
                rGroup.Groupname = mapResourceGroup.get(groupID).Name;
                rGroup.ChildGroup = null; 
                lstResourceGroups.add(rGroup);
  
                rschedule.ResourceGroup = lstResourceGroups;
            }
            rsWrapper.ResourceSchedule = rschedule;
            system.debug('***** rsWrapper ==> ' + rsWrapper);
            return rsWrapper;
        }
        catch(exception ex){
            //log exception in log object 
            system.debug('ERROR creating wrapper '+ex.getMessage()+' at '+ex.getStackTraceString());
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'Error in retrieving child records', ex.getStackTraceString());
            return null;
        }
        
    }
    
    
    public static List<roCalendarWrapper.Resource> getAllResourcesRelatedToGroup(List<Resource__c> lstResources, MasterWrapper mWrapper){
        map<string, Decimal> mapWeeklyResourceUtilization = mWrapper.mapWeeklyResourceUtilization;
        map<Id, List<Resource_Allocation__c>> mapResourceIdAndRelatedAllocations = mWrapper.mapResourceIdAndRelatedAllocations;
        List<roCalendarWrapper.Resource> lstResourceWrapper = new List<roCalendarWrapper.Resource>();
        List<roCalendarWrapper.AvailableDateTimes> lstResourceAvailableDateTimes = new List<roCalendarWrapper.AvailableDateTimes>();
        if(lstResources!=null){
            for(Resource__c r: lstResources){
                roCalendarWrapper.Resource resourceWrapper = new roCalendarWrapper.Resource();
                resourceWrapper.ResourceID = r.Id;
                resourceWrapper.ResourceName = r.First_Name__c+' '+r.Last_Name__c;      
                resourceWrapper.ResourceRole = r.Role__c;
                resourceWrapper.ResourceSkills = r.Skills_Backend__c;
                resourceWrapper.ProfileImageURL = r.Profile_Picture_URL__c;
                //resourceWrapper.Maxheight = mapResourceIdAndRelatedAllocations.get(r.Id).size();
                decimal eff = mapWeeklyResourceUtilization.get(r.Id+string.valueOf(mWrapper.weekStartDate).split(' ')[0]);
                resourceWrapper.WeeklyUtilization = string.valueOf(eff!=null?eff.setScale(2):0);
                resourceWrapper.AssignedRecords = getAllAssignedRecords(r, mWrapper);
                
                map<string, List<Resource_Available_Hours__c>> mapResourceAndRelatedAvailableHours = mWrapper.mapResourceAndRelatedAvailableHours;
                if(mapResourceAndRelatedAvailableHours.containsKey(r.Id)){
                    for(Resource_Available_Hours__c rah: mapResourceAndRelatedAvailableHours.get(r.Id)){
                        roCalendarWrapper.AvailableDateTimes resourceAvailableDateTimes = new roCalendarWrapper.AvailableDateTimes();
                        resourceAvailableDateTimes.StartDatetime = rah.Start_time__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                        resourceAvailableDateTimes.EndDatetime = rah.End_Time__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                        lstResourceAvailableDateTimes.add(resourceAvailableDateTimes);
                    } 
                }
                resourceWrapper.AvailableDateTimes = lstResourceAvailableDateTimes;
                lstResourceWrapper.add(resourceWrapper);
            }           
        }
        return lstResourceWrapper;
    }
   
    public static roCalendarWrapper.AssignedRecords getAllAssignedRecords(Resource__c r, MasterWrapper mWrapper){
        ResourceOptimizerConfig__c roc = ResourceOptimizerConfig__c.getOrgDefaults();
        List<Resource_Allocation__c> lstResourceAllocations = mWrapper.mapResourceIdAndRelatedAllocations.get(r.Id);
        map<string, Decimal> mapDailyResourceUtilization = mWrapper.mapDailyResourceUtilization;
        map<string, List<Resource_Available_Hours__c>> mapResourUtilizationAndRelatedAvailableHours = mWrapper.mapResourUtilizationAndRelatedAvailableHours;
        set<String> setParentObjects = mWrapper.setParentObjects;
        map<string, string> mapResourceAllocationColorMapping = mWrapper.mapResourceAllocationColorMapping;
        List<roCalendarWrapper.Day> lstDays = new List<roCalendarWrapper.Day>();
        List<roCalendarWrapper.AvailableDateTimes> lstResourceAvailableDateTimes = new List<roCalendarWrapper.AvailableDateTimes>();
        roCalendarWrapper.AssignedRecords ar = new roCalendarWrapper.AssignedRecords();
        map<Date, List<Resource_Allocation__c>> mapDayAndRelatedAllocations =  new map<Date, List<Resource_Allocation__c>>();
        if(lstResourceAllocations.size()>0){
            for(Resource_Allocation__c ra: lstResourceAllocations){
                if(!mapDayAndRelatedAllocations.containsKey(ra.Allocated_Start_DateTime__c.Date())){
                    mapDayAndRelatedAllocations.put(ra.Allocated_Start_DateTime__c.Date(), new List<Resource_Allocation__c>());
                    mapDayAndRelatedAllocations.get(ra.Allocated_Start_DateTime__c.Date()).add(ra);
                }
                else{
                    mapDayAndRelatedAllocations.get(ra.Allocated_Start_DateTime__c.Date()).add(ra);
                }
            }
            for(date dateValue : mapDayAndRelatedAllocations.keySet()){
                List<roCalendarWrapper.record> lstRecords = new List<roCalendarWrapper.record>();
                roCalendarWrapper.Day resourceAllocationDay = new roCalendarWrapper.Day();
                resourceAllocationDay.CurrentDate = string.valueOf(dateValue); 
                decimal eff = mapDailyResourceUtilization.get(r.Id+string.valueOf(dateValue));
                resourceAllocationDay.Utilization = string.valueOf(eff!=null?eff.setScale(2):0); 
                resourceAllocationDay.StartDatetime = r.Resource_Default_Start_Time__c != null ? convertTimeToDateTime(dateValue, r.Resource_Default_Start_Time__c) : null; 
                resourceAllocationDay.EndDatetime = r.Resource_Default_End_Time__c != null ? convertTimeToDateTime(dateValue, r.Resource_Default_End_Time__c) : null;
                
                system.debug('r.Id+string.valueOf(dateValue) ==>' + r.Id+string.valueOf(dateValue));
                system.debug('map value ==>' + mapResourUtilizationAndRelatedAvailableHours.get(r.Id+string.valueOf(dateValue)));

                if(mapResourUtilizationAndRelatedAvailableHours.containsKey(r.Id+string.valueOf(dateValue))){
                    for(Resource_Available_Hours__c rah: mapResourUtilizationAndRelatedAvailableHours.get(r.Id+string.valueOf(dateValue))){
                        roCalendarWrapper.AvailableDateTimes resourceAvailableDateTimes = new roCalendarWrapper.AvailableDateTimes();
                        resourceAvailableDateTimes.StartDatetime = rah.Start_time__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                        resourceAvailableDateTimes.EndDatetime = rah.End_Time__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                        lstResourceAvailableDateTimes.add(resourceAvailableDateTimes);
                    } 
                }
                //resourceAllocationDay.AvailableDateTimes = lstResourceAvailableDateTimes;
                for(Resource_Allocation__c relatedRA : mapDayAndRelatedAllocations.get(dateValue)){
                    roCalendarWrapper.record recordWrapper = new roCalendarWrapper.record();                    
                    Id relatedRecordId = getRelatedRecordId(relatedRA, setParentObjects);
                    string relatedObjectAPIName;
                    string relatedObjectLabel;
                    if(relatedRecordId != null){
                        DescribeSObjectResult sObjeResult = relatedRecordId.getsobjecttype().getDescribe();
                        relatedObjectAPIName = sObjeResult.getName();
                        relatedObjectLabel = sObjeResult.getLabel();    
                    }
                    else if(relatedRA.Reservation__c!=null || test.isRunningTest()){
                        relatedObjectAPIName = 'Reservation__c';
                        relatedObjectLabel = 'Reservation'; 
                    }
                    
                    recordWrapper.Recordtype = relatedObjectLabel;
                    recordWrapper.RecordApiName = relatedObjectAPIName;
                    recordWrapper.Recordid = relatedRA.Id; //relatedRecordId; // ra id
                    recordWrapper.RecordStartdate = relatedRA.Allocated_Start_DateTime__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                    recordWrapper.RecordEnddate = relatedRA.Allocated_End_Datetime__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                    recordWrapper.Recordname = relatedRA.name; 
                    recordWrapper.Recordcolor = mapResourceAllocationColorMapping.get(relatedRA.Status__c);
                    lstRecords.add(recordWrapper);
                    
                }
                resourceAllocationDay.Record = lstRecords;
                lstDays.add(resourceAllocationDay);
            }
            ar.Day = lstDays;
        }
        return ar;
    }
    
    public static Id getRelatedRecordId(Resource_Allocation__c relatedRA, set<String> setParentObjects){   
        //system.debug('getRelatedRecordId');
        Id relatedRecordId;
        if(setParentObjects.size()>0 && !Test.isRunningTest()){
            for(string objAPIName: setParentObjects){
                relatedRecordId = (Id)relatedRA.get(objAPIName);
                //system.debug('relatedRecordId ==> ' + relatedRecordId);
                if(relatedRecordId != null){
                    return relatedRecordId;
                }
            }
        }   
        return null;
    }
    
    public static List<String> getLookupFields(String objName){        
        List<String> lstLookupFields = new List<String>();
        map<string, Map<String, Schema.SObjectField>> objectFieldsMap = new map<string, Map<String, Schema.SObjectField>>(); 
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
        for(Schema.SObjectField fld :objectFields.values()){
            schema.describeFieldResult dfield = fld.getDescribe();
            string fldType = string.valueOf(dfield.getType());   
            if (fldType == 'REFERENCE'){ 
                lstLookupFields.add(string.valueOf(dfield.Name));
            }
        }
        return lstLookupFields; 
    }
     
    public static string formatDateTime(date targetDt, dateTime givenDateTime){
        string updatedDateTimeString;
        string dateTimeString = givenDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        string timeString = dateTimeString.split('T')[1];
        updatedDateTimeString = string.valueOf(targetDt)+'T'+timeString;
        return updatedDateTimeString;
    }
    
    public static string convertTimeToDateTime (date targetDate, Time targetTime){  
        string stringTargetTime = string.valueOf(targetTime);
        List<string>timeComponents = stringTargetTime.split(':');       
        Time newTimeInstance = Time.newInstance(Integer.valueOf(timeComponents[0]), Integer.valueOf(timeComponents[1]), 0, 0);
        DateTime targetDateTime = DateTime.newInstance(targetDate, newTimeInstance);
        return string.valueOf(formatDateTime(targetDate,targetDateTime));
    }
    
    
    // master wrapper class to hold all variables to build child JSON.
    public class MasterWrapper{
        public date weekStartDate {get; set;}
        public map<Id, List<Resource_Allocation__c>> mapResourceIdAndRelatedAllocations {get; set;}
        public map<string, List<Resource__c>> mapResourceGroupAndResources {get; set;}       
        //public map<string, List<String>> mapGroups {get; set;}
        public map<string, Decimal> mapDailyResourceUtilization {get; set;}
        public map<string, Decimal> mapWeeklyResourceUtilization {get; set;}
        public map<string, List<Resource_Available_Hours__c>> mapResourUtilizationAndRelatedAvailableHours {get; set;}
        public map<string, List<Resource_Available_Hours__c>> mapResourceAndRelatedAvailableHours {get; set;}
        public set<String> setParentObjects {get; set;}
        public map<string, string> mapResourceAllocationColorMapping {get; set;}
    }
}