/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roUtilizationViewController {
    private static final map<string, string> defaultHeadersColumns = new map<string, string>{'Rhead'=>'Resource', 'RRole'=>'Role'};
    private static final map<Integer, list<Integer>> mapQuarterToMonths = new map<Integer, list<Integer>> { 1 => new list<Integer>{1,2,3}, 
        																						   2 => new list<Integer>{4,5,6}, 
                                                                                                   3 => new list<Integer>{7,8,9}, 
                                                                                                   4 => new list<Integer>{10,11,12}};
    private static final map<integer, integer> fiscalQuartersMap = new map<integer, integer>{1=>1, 2=>1, 3=>1, 4=>2, 5=>2, 6=>2, 7=>3, 8=>3, 9=>3, 10=>4, 11=>4, 12=>4};
        private static final map<integer, String> mapMonths = new map<integer, string>{1=>'JAN', 2=>'FEB', 3=>'MAR', 4=>'APR', 5=>'MAY', 6=>'JUN', 7=>'JUL', 
            																			8=>'AUG', 9=>'SEP', 10=>'OCT', 11=>'NOV', 12=>'DEC'};
        
    public roUtilizationViewController() {
    }
    
    @AuraEnabled
    public static List<resource_group__c> getgroups(){
      return [select id,name from resource_group__c] ;
    }
    
    @AuraEnabled
    public static List<Skills__c> getskills(){      
      return [select id,name from Skills__c] ;
    }
        
    @AuraEnabled
    public static string getUtilizationdata(string day, string month, string year, string filter1, string filter2, string groupId){        
        /*
         * scenario 1: 02,01,2020,day,15days,null - on a given day, show 7 previous dates and 7 future dates
         * scenario 2: 02,01,2020,day,month,null - for a given month, show 31 days of the month
         * scenario 3: 02,01,2020,week,month,null - for a given month, show 4 weeks of the month
         * scenario 4: 02,01,2020,week,quarter,null - for a given quarter, show 12 weeks of the quarter
         * scenario 5: 02,01,2020,month,Year,null - for a given year, show 12 months of the year
         * */
        system.debug(day+'-'+month+'-'+year+'-'+filter1+'-'+filter2+'-'+groupId);
        map<Id, List<Resource_Utilization__c>> mapResourceIdAndResourceEfficiencies = new map<Id, List<Resource_Utilization__c>>();
        map<Id, Resource__c> mapResources = new map<Id, Resource__c>(); 
        groupId = groupId.length() == 18 ? groupId.substring(0,15) : groupId;
        date givenDate = date.newInstance(Integer.valueOf(year), Integer.valueOf(month), Integer.valueOf(day));
        date startDate, endDate;
        string queryString;
        string recordTypeName = 'Daily_Utilization';
        List<Resource_Utilization__c> lstResourceEfficiencies = new List<Resource_Utilization__c>();
        roEfficiencyWrapper rew = new roEfficiencyWrapper();
        if(filter1=='day' && filter2 == 'month'){
            startDate = givenDate.toStartOfMonth();
            endDate = givenDate.addMonths(1).toStartofMonth().addDays(-1);
            recordTypeName = 'Daily_Utilization';            
        }
        else if(filter1=='day' && filter2=='15days'){
            startDate = givenDate.addDays(-7);
            endDate = givenDate.addDays(7);
            recordTypeName = 'Daily_Utilization';            
        }
        else if(filter1=='week' && filter2=='month'){
            startDate = givenDate.toStartOfMonth();
            endDate = givenDate.addMonths(1).toStartofMonth().addDays(-1);
            recordTypeName = 'Weekly_Utilization';            
        }
        else if(filter1=='week' && filter2=='quarter'){
            Integer currentMonth = givenDate.month();
            Integer currentQuarter = fiscalQuartersMap.get(currentMonth);              
            Integer beginingMonthOfQuarter = currentQuarter == 1 ? 1 : (currentQuarter == 2 ? 4 : (currentQuarter == 3 ? 7 : 10 )); 
           
            startDate = date.newInstance(givenDate.year(), beginingMonthOfQuarter, 1);
            endDate = startDate.addMonths(3).toStartofMonth().addDays(-1);
           
            recordTypeName = 'Weekly_Utilization';            
        }
        else if(filter1=='month' && filter2=='quarter'){
            Integer currentMonth = givenDate.month();
            Integer currentQuarter = fiscalQuartersMap.get(currentMonth);
            Integer beginingMonthOfQuarter = currentQuarter == 1 ? 1 : (currentQuarter == 2 ? 4 : (currentQuarter == 3 ? 7 : 10 ));
            startDate = date.newInstance(givenDate.year(), beginingMonthOfQuarter, 1);
            endDate = startDate.addMonths(3).toStartofMonth().addDays(-1);            
            recordTypeName = 'Monthly_Utilization';       
        }
        else if(filter1=='month' && filter2=='year'){
            Integer currentMonth = givenDate.month();
            startDate = date.newInstance(givenDate.year(),1, 1);
            endDate = startDate.addMonths(12).toStartofMonth().addDays(-1);
            recordTypeName = 'Monthly_Utilization';            
        }
        Integer currentYear = givenDate.year();
        for(sObject sObj: Database.query(getDynamicQueryString(startDate, endDate, groupId, recordTypeName, currentYear))){
            Resource__c res = (Resource__c)sObj;
            mapResources.put(res.Id, res);
            mapResourceIdAndResourceEfficiencies.put(res.Id, new List<Resource_Utilization__c>());
            mapResourceIdAndResourceEfficiencies.get(res.Id).addAll(res.Resource_Utilization__r);
            for(Resource_Utilization__c re: res.Resource_Utilization__r){
                lstResourceEfficiencies.add(re);
            }
        }

        rew = getUtilizationWrapper(mapResourceIdAndResourceEfficiencies, mapResources ,givenDate,startDate, endDate, filter1,filter2);
        system.debug('rew ==> ' + JSON.serialize(rew));
        return JSON.serialize(rew);
    }
    
    public static string getDynamicQueryString(date startDate, date endDate, string groupId, string recordTypeName, Integer currentYear ){ 
        string dynamicQueryString = 'SELECT Id, fullName__c, Role__c, ResourceGroupHierarchy__c, ResourceGroupIds__c,';      
        string whereCondition = ' FROM Resource__c WHERE Active__c=True AND ResourceGroupIds__c LIKE' + '\'%' + String.escapeSingleQuotes(groupId.trim()) + '%\'';
        
        string effQueryString = ' (SELECT Id, Resource__c, Month_Number__c, Resource__r.fullName__c, Resource__r.Role__c, Utilization_Date__c, Utilization__c, RecordType.DeveloperName, Week_Start_Date__c  FROM Resource_Utilization__r';
        if(recordTypeName == 'Weekly_Utilization'){
            effQueryString +=' WHERE (Week_Start_Date__c >=: startDate AND Week_Start_Date__c <=: endDate)';
        }
        else if(recordTypeName == 'Monthly_Utilization'){           
            effQueryString +=' WHERE Year__c =: currentYear'; 
        }
        else{
            effQueryString +=' WHERE (Utilization_Date__c >=: startDate AND Utilization_Date__c <=: endDate)'; 
        }      
        effQueryString +=' AND RecordType.DeveloperName=\''+String.escapeSingleQuotes(recordTypeName)+'\')';
        
        dynamicQueryString = dynamicQueryString + effQueryString + whereCondition;
        system.debug('dynamicQueryString ==> ' + dynamicQueryString);
        return dynamicQueryString;
    }
    
    public static roEfficiencyWrapper getUtilizationWrapper(map<Id, List<Resource_Utilization__c>> mapResourceAndResourceEfficiencies, map<Id, Resource__c> mapResources, date currentDate, date startDate, date endDate, string filter1, string filter2){
        string strPad = '0';
        Integer numberOfDaysInCurrentMonth;
        roEfficiencyWrapper rWrapper = new roEfficiencyWrapper();
        roEfficiencyWrapper.Etable rEtable = new roEfficiencyWrapper.Etable();
        List<roEfficiencyWrapper.Header> listHeaders = new List<roEfficiencyWrapper.Header>();
        map<string, string> mapHeaders = new map<string, string>();
        List<map<string, string>> listBody = new List<map<string, string>>();        
        map<Id, string> mapResource = new map<Id, String>();
       
        
        // default header values                
        for(string hKey: defaultHeadersColumns.keyset()){
            roEfficiencyWrapper.Header rHeader = new roEfficiencyWrapper.Header();
            rHeader.key = hKey;
            rHeader.value = defaultHeadersColumns.get(hKey);
            rHeader.Childheader = new List<roEfficiencyWrapper.Childheader>();
            listHeaders.add(rHeader);
        }
        // body attribute
        if(filter1 == 'day' && filter2 == 'month'){
            Integer currentMonth = currentDate.month();
            numberOfDaysInCurrentMonth = date.daysInMonth(currentDate.Year(), currentMonth);
            for(integer i=1; i<=numberOfDaysInCurrentMonth; i++){
                roEfficiencyWrapper.Header rHeader = new roEfficiencyWrapper.Header();
                string strCurrentMonth = string.valueOf(currentMonth).leftPad(2,strPad);
                rHeader.key = string.valueOf(i).leftPad(2,strPad); //strCurrentMonth;
                rHeader.value = strCurrentMonth +'/'+ string.valueOf(i).leftPad(2,strPad);
                rHeader.Childheader = new List<roEfficiencyWrapper.Childheader>();
                listHeaders.add(rHeader);
            }
            // prepare map of resource and resource efficiencies                       
            if(mapResourceAndResourceEfficiencies.size()>0){               
                for(Id resourceId: mapResourceAndResourceEfficiencies.keySet()){
                    map<string, string> mapBodyValues = new map<string, string>();
                   
                    mapBodyValues.put('Rhead', mapResources.get(resourceId).fullName__c);
                    mapBodyValues.put('RRole', mapResources.get(resourceId).Role__c);
                    List<Resource_Utilization__c> lstEfficiencies = mapResourceAndResourceEfficiencies.get(resourceId);
                    system.debug('lstEfficiencies size() ==> ' +  lstEfficiencies);
                    if(lstEfficiencies.size()>0){
                        map<string,string> mapEfficiencies = new map<string, string>();
                        for(Resource_Utilization__c re: lstEfficiencies){
                            
                            //mapBodyValues.put(string.valueOf(re.Utilization_Date__c.day()).leftPad(2,strPad), string.valueOf(re.Utilization__c.setScale(2))+'%'); 
                            string eff = re.Utilization__c != null ? string.valueOf(re.Utilization__c.setScale(2))+'%' : '0%';
                            mapEfficiencies.put(string.valueOf(re.Utilization_Date__c.day()).leftPad(2,strPad), eff);
                             for(integer i=1; i<=numberOfDaysInCurrentMonth; i++){
                                 if(mapEfficiencies.containsKey(string.valueOf(i).leftPad(2,strPad))){
                                    mapBodyValues.put(string.valueOf(re.Utilization_Date__c.day()).leftPad(2,strPad), eff);  
                                 }
                                 else{
                                    mapBodyValues.put(string.valueOf(i).leftPad(2,strPad), '0%');  
                                 }                                 
                             }
                        }
                    }
                    else{
                       system.debug('not geater than zero');
                       for(integer i=1; i<=numberOfDaysInCurrentMonth; i++){
                           mapBodyValues.put(string.valueOf(i).leftPad(2,strPad), '0%');  
                       } 
                       system.debug(mapBodyValues);
                    }
                    
                    listBody.add(mapBodyValues);
                }                
            }
        }
        
        if(filter1 == 'day' && filter2 == '15days'){
            system.debug('15 days');
            //integer startDay = startDate.day();
            //integer endDay = endDate.day();
            
            system.debug('startDate ==> '+ startDate);
            system.debug('endDate ==> '+ endDate);
            Integer currentMonth = currentDate.month();
            Date startDateToCompare = startDate;
            Date endDateToCompare = endDate;
            while(startDateToCompare <= endDateToCompare){
                integer i = startDateToCompare.day();
                roEfficiencyWrapper.Header rHeader = new roEfficiencyWrapper.Header();
                string strCurrentMonth = string.valueOf(startDateToCompare.month()).leftPad(2,strPad);
                rHeader.key = string.valueOf(i).leftPad(2,strPad); //strCurrentMonth;
                rHeader.value = strCurrentMonth +'/'+ string.valueOf(i).leftPad(2,strPad);
                rHeader.Childheader = new List<roEfficiencyWrapper.Childheader>();
                listHeaders.add(rHeader);
                startDateToCompare = startDateToCompare.addDays(1);
                system.debug('startDateToCompare ==> '+ startDateToCompare);
            }
            
            
            
            
           /* for(integer i=startDay; i<=endDay; i++){
                roUtilizationWrapper.Header rHeader = new roUtilizationWrapper.Header();
                string strCurrentMonth = string.valueOf(currentMonth).leftPad(2,strPad);
                rHeader.key = string.valueOf(i).leftPad(2,strPad); //strCurrentMonth;
                rHeader.value = strCurrentMonth +'/'+ string.valueOf(i).leftPad(2,strPad);
                rHeader.Childheader = new List<roUtilizationWrapper.Childheader>();
                listHeaders.add(rHeader);
            }*/
            if(mapResourceAndResourceEfficiencies.size()>0){               
                for(Id resourceId: mapResourceAndResourceEfficiencies.keySet()){
                    map<string, string> mapBodyValues = new map<string, string>();
                  
                    mapBodyValues.put('Rhead', mapResources.get(resourceId).fullName__c);
                    mapBodyValues.put('RRole', mapResources.get(resourceId).Role__c);
                    List<Resource_Utilization__c> lstEfficiencies = mapResourceAndResourceEfficiencies.get(resourceId);
                    system.debug('lstEfficiencies size() ==> ' +  lstEfficiencies);
                    if(lstEfficiencies.size()>0){
                        map<string,string> mapEfficiencies = new map<string, string>();
                        for(Resource_Utilization__c re: lstEfficiencies){
                            
                            //mapBodyValues.put(string.valueOf(re.Utilization_Date__c.day()).leftPad(2,strPad), string.valueOf(re.Utilization__c.setScale(2))+'%'); 
                            string eff = re.Utilization__c != null ? string.valueOf(re.Utilization__c.setScale(2))+'%' : '0%';
                            mapEfficiencies.put(string.valueOf(re.Utilization_Date__c.day()).leftPad(2,strPad), eff);
                            startDateToCompare = startDate;
            				endDateToCompare = endDate;
            				while(startDateToCompare <= endDateToCompare){
                            	integer i = startDateToCompare.day();
                                if(mapEfficiencies.containsKey(string.valueOf(i).leftPad(2,strPad))){
                                    mapBodyValues.put(string.valueOf(re.Utilization_Date__c.day()).leftPad(2,strPad), eff);  
                                 }
                                 else{
                                    mapBodyValues.put(string.valueOf(i).leftPad(2,strPad), '0%');  
                                 }  
                            	  startDateToCompare = startDateToCompare.addDays(1);
                            }
                            /* for(integer i=startDay; i<=endDay; i++){
                                 if(mapEfficiencies.containsKey(string.valueOf(i).leftPad(2,strPad))){
                                    mapBodyValues.put(string.valueOf(re.Utilization_Date__c.day()).leftPad(2,strPad), eff);  
                                 }
                                 else{
                                    mapBodyValues.put(string.valueOf(i).leftPad(2,strPad), '0%');  
                                 }                                 
                             }*/
                        }
                    }
                    else{
                       system.debug('not geater than zero');
                        startDateToCompare = startDate;
                        endDateToCompare = endDate;
                        while(startDateToCompare <= endDateToCompare){
                            integer i = startDateToCompare.day(); 
                            mapBodyValues.put(string.valueOf(i).leftPad(2,strPad), '0%');  
                            startDateToCompare = startDateToCompare.addDays(1);
                        }
                        
                       /* 
                       for(integer i=startDay; i<=endDay; i++){
                           mapBodyValues.put(string.valueOf(i).leftPad(2,strPad), '0%');  
                       } */
                       
                    }
                    
                    listBody.add(mapBodyValues);
                }  
                system.debug('listBody ==>' + listBody);
            }  
        }        
        
               
        if(filter1=='week' && filter2=='month'){
            Integer currentMonth = currentDate.month();                      
            roEfficiencyWrapper.Header rHeader = new roEfficiencyWrapper.Header();
            List<roEfficiencyWrapper.Childheader> lstChildHeaders = new List<roEfficiencyWrapper.Childheader>();
            Integer daysInAMonth = Date.daysInMonth(currentDate.year(), currentDate.month());
            Integer weeksInAMonth = daysInAMonth / 7 ;
            if(math.mod(daysInAMonth,7)>0){
                weeksInAMonth = weeksInAMonth + 1;
            }
            system.debug('weeksInAMonth ==> ' + weeksInAMonth);
            string strCurrentMonth = string.valueOf(currentMonth).leftPad(2,strPad);
            dateTime currentDateTime = (dateTime) currentDate;
            string currentMonthLabel = currentDateTime.format('dd MMM,yyyy').split(',')[0].split(' ')[1];
            rHeader.key = strCurrentMonth;
            rHeader.value = currentMonthLabel.toUpperCase();
             Date startDateOfTheMonth = currentDate.toStartOfMonth();
             Date startDateOfTheWeek = startDateOfTheMonth.toStartOfWeek();
            for(integer i=1; i<=weeksInAMonth; i++){                 
                 roEfficiencyWrapper.Childheader roChildHeader = new roEfficiencyWrapper.Childheader();
                 roChildHeader.key = string.valueOf(currentMonth).leftPad(2,strPad)+'W'+ string.valueOf(i);
                 roChildHeader.value = startDateOfTheWeek.month() +'/'+ string.valueOf(startDateOfTheWeek.day()).leftPad(2,strPad);
                 startDateOfTheWeek  = startDateOfTheWeek.addDays(7).toStartOfWeek();
                lstChildHeaders.add(roChildHeader);
            }
            rHeader.Childheader = lstChildHeaders;
            listHeaders.add(rHeader);
            
            if(mapResourceAndResourceEfficiencies.size()>0){               
                for(Id resourceId: mapResourceAndResourceEfficiencies.keySet()){
                    map<string, string> mapBodyValues = new map<string, string>();
                   
                    mapBodyValues.put('Rhead', mapResources.get(resourceId).fullName__c);
                    mapBodyValues.put('RRole', mapResources.get(resourceId).Role__c);
                    List<Resource_Utilization__c> lstEfficiencies = mapResourceAndResourceEfficiencies.get(resourceId);
                    if(lstEfficiencies.size()>0){
                        map<string,string> mapEfficiencies = new map<string, string>();
                        for(Resource_Utilization__c re: lstEfficiencies){                            
                            string eff = re.Utilization__c != null ? string.valueOf(re.Utilization__c.setScale(2))+'%' : '0%';
                            string strWeekOfMonth = string.valueOf(re.Week_Start_Date__c.month()).leftPad(2,strPad) +'W'+ weekOfMonth(re.Week_Start_Date__c);
                            mapEfficiencies.put(strWeekOfMonth, eff);                            
                            for(integer i=1; i<=weeksInAMonth; i++){
                                if(mapEfficiencies.containsKey(string.valueOf(currentMonth).leftPad(2,strPad)+'W'+ string.valueOf(i))){
                                    mapBodyValues.put(strWeekOfMonth, eff);  
                                }
                                else{
                                    mapBodyValues.put(string.valueOf(currentMonth).leftPad(2,strPad)+'W'+ string.valueOf(i), '0%');  
                                }                            
                            }
                           // mapBodyValues.put(strWeekOfMonth, string.valueOf(re.Utilization__c.setScale(2))+'%'); 
                        }
                    }
                    else{
                        for(integer i=1; i<=weeksInAMonth; i++){
                           mapBodyValues.put(string.valueOf(currentMonth).leftPad(2,strPad)+'W'+ string.valueOf(i), '0%');  
                       } 
                    }
                    
                    listBody.add(mapBodyValues);
                }                
            }
            
        }
        if(filter1=='week' && filter2=='quarter'){
           
           Integer startDateMonth = startDate.month();
           Integer currentQuarter = fiscalQuartersMap.get(startDateMonth);
           List<Integer> monthsInCurrentQuarter = mapQuarterToMonths.get(currentQuarter);           
           Date previousStartDateOfTheWeek;
            for(integer i=0; i<=monthsInCurrentQuarter.size()-1; i++){  
                 List<roEfficiencyWrapper.Childheader> lstChildHeaders = new List<roEfficiencyWrapper.Childheader>();
                roEfficiencyWrapper.Header rHeader = new roEfficiencyWrapper.Header();
                string strCurrentMonth = string.valueOf(monthsInCurrentQuarter[i]).leftPad(2,strPad);         
                rHeader.key = strCurrentMonth;
                rHeader.value = mapMonths.get(monthsInCurrentQuarter[i]);
                
                Date startDateOfTheMonth = date.newInstance(currentDate.year(), integer.valueOf(strCurrentMonth), 1);
                Date startDateOfTheWeek = startDateOfTheMonth.toStartOfWeek();
                Integer daysInAMonth = Date.daysInMonth(currentDate.year(), integer.valueOf(strCurrentMonth));
                Integer weeksInAMonth = daysInAMonth / 7 ;
                if(math.mod(daysInAMonth,7)>0){
                    weeksInAMonth = weeksInAMonth + 1;
                } 
                
                for(integer j=1; j<=weeksInAMonth; j++){                 
                    if(previousStartDateOfTheWeek != startDateOfTheWeek || previousStartDateOfTheWeek == null){
                        roEfficiencyWrapper.Childheader roChildHeader = new roEfficiencyWrapper.Childheader();
                        roChildHeader.key = string.valueOf(strCurrentMonth).leftPad(2,strPad)+'W'+ string.valueOf(j);
                        roChildHeader.value = string.valueOf(startDateOfTheWeek.month()).leftPad(2,strPad) +'/'+ string.valueOf(startDateOfTheWeek.day()).leftPad(2,strPad);
                        
                        lstChildHeaders.add(roChildHeader);
                    }
                    previousStartDateOfTheWeek = startDateOfTheWeek;
                    startDateOfTheWeek  = startDateOfTheWeek.addDays(7).toStartOfWeek();
                }
                
                rHeader.Childheader = lstChildHeaders;
                listHeaders.add(rHeader);
            }

            if(mapResourceAndResourceEfficiencies.size()>0){               
                for(Id resourceId: mapResourceAndResourceEfficiencies.keySet()){
                    map<string, string> mapBodyValues = new map<string, string>();
                  
                    mapBodyValues.put('Rhead', mapResources.get(resourceId).fullName__c);
                    mapBodyValues.put('RRole', mapResources.get(resourceId).Role__c);
                    List<Resource_Utilization__c> lstEfficiencies = mapResourceAndResourceEfficiencies.get(resourceId);
                    if(lstEfficiencies.size()>0){
                        map<string,string> mapEfficiencies = new map<string, string>();
                        for(Resource_Utilization__c re: lstEfficiencies){
                            string eff = re.Utilization__c != null ? string.valueOf(re.Utilization__c.setScale(2))+'%' : '0%';
                            string strWeekOfMonth = string.valueOf(re.Week_Start_Date__c.month()).leftPad(2,strPad) +'W'+ weekOfMonth(re.Week_Start_Date__c);
                            mapEfficiencies.put(strWeekOfMonth, eff);
                            for(integer i=0; i<=monthsInCurrentQuarter.size()-1; i++){ 
                                 string strCurrentMonth = string.valueOf(monthsInCurrentQuarter[i]).leftPad(2,strPad); 
                                Integer daysInAMonth = Date.daysInMonth(currentDate.year(), integer.valueOf(strCurrentMonth));
                                Integer weeksInAMonth = daysInAMonth / 7 ;
                                if(math.mod(daysInAMonth,7)>0){
                                    weeksInAMonth = weeksInAMonth + 1;
                                } 
                                for(integer j=1; j<=weeksInAMonth; j++){
                                    if(mapEfficiencies.containsKey(string.valueOf(strCurrentMonth).leftPad(2,strPad)+'W'+ string.valueOf(j))){
                                        mapBodyValues.put(strWeekOfMonth, eff);  
                                    }
                                    else{
                                        mapBodyValues.put(string.valueOf(strCurrentMonth).leftPad(2,strPad)+'W'+ string.valueOf(j), '0%');  
                                    }                            
                                }
                            }
                            
                            //mapBodyValues.put(strWeekOfMonth, eff); 
                        }
                    }
                    else{
                        for(integer i=0; i<=monthsInCurrentQuarter.size()-1; i++){ 
                            string strCurrentMonth = string.valueOf(monthsInCurrentQuarter[i]).leftPad(2,strPad); 
                            Integer daysInAMonth = Date.daysInMonth(currentDate.year(), integer.valueOf(strCurrentMonth));
                            Integer weeksInAMonth = daysInAMonth / 7 ;
                            if(math.mod(daysInAMonth,7)>0){
                                weeksInAMonth = weeksInAMonth + 1;
                            } 
                            for(integer j=1; j<=weeksInAMonth; j++){
                                mapBodyValues.put(string.valueOf(strCurrentMonth).leftPad(2,strPad)+'W'+ string.valueOf(j), '0%');  
                            } 
                        }
                    }
                   
                    listBody.add(mapBodyValues);
                }                
            }            
        }
        
        if(filter1=='month' && filter2=='quarter'){
            Integer startDateMonth = startDate.month();
            Integer currentQuarter = fiscalQuartersMap.get(startDateMonth);
            List<Integer> lstMonths = mapQuarterToMonths.get(currentQuarter); 
            system.debug('lstMonths ==> '+ lstMonths);
            for(integer i=0; i<=lstMonths.size()-1; i++){  
                roEfficiencyWrapper.Header rHeader = new roEfficiencyWrapper.Header();                
                string strCurrentMonth = string.valueOf(lstMonths[i]).leftPad(2,strPad);         
                rHeader.key = strCurrentMonth;
                rHeader.value = mapMonths.get(lstMonths[i]);
                rHeader.Childheader = new List<roEfficiencyWrapper.Childheader>();
                listHeaders.add(rHeader);
            }
            
             if(mapResourceAndResourceEfficiencies.size()>0){               
                for(Id resourceId: mapResourceAndResourceEfficiencies.keySet()){
                    map<string, string> mapBodyValues = new map<string, string>();
                  
                    mapBodyValues.put('Rhead', mapResources.get(resourceId).fullName__c);
                    mapBodyValues.put('RRole', mapResources.get(resourceId).Role__c);
                    List<Resource_Utilization__c> lstEfficiencies = mapResourceAndResourceEfficiencies.get(resourceId);
                    if(lstEfficiencies.size()>0){
                        map<string,string> mapEfficiencies = new map<string, string>();
                        
                        for(Resource_Utilization__c re: lstEfficiencies){
                            string eff = re.Utilization__c != null ? string.valueOf(re.Utilization__c.setScale(2))+'%' : '0%';
                            string strMonth = string.valueOf(re.Month_Number__c).leftPad(2,strPad);
                            mapEfficiencies.put(strMonth, eff);
                            for(integer i=0; i<=lstMonths.size()-1; i++){ 
                                if(mapEfficiencies.containsKey(string.valueOf(lstMonths[i]).leftPad(2,strPad))){
                                    mapBodyValues.put(string.valueOf(lstMonths[i]).leftPad(2,strPad), eff);  
                                }
                                else{
                                    mapBodyValues.put(string.valueOf(lstMonths[i]).leftPad(2,strPad), '0%');  
                                } 
                            }
                           // mapBodyValues.put(strMonth, string.valueOf(re.Utilization__c.setScale(2))+'%'); 
                        }
                                   
                    }
                    else{
                         for(integer i=0; i<=lstMonths.size()-1; i++){ 
                              mapBodyValues.put(string.valueOf(lstMonths[i]).leftPad(2,strPad), '0%'); 
                         }
                    }                    
                    listBody.add(mapBodyValues);
                }                
            }   
        }
        
        
        if(filter1=='month' && filter2=='year'){
           list<integer> lstMonths = new List<integer>();
           lstMonths.addall(mapMonths.keyset());
           for(integer i=0; i<=lstMonths.size()-1; i++){                
                roEfficiencyWrapper.Header rHeader = new roEfficiencyWrapper.Header();                
                string strCurrentMonth = string.valueOf(lstMonths[i]).leftPad(2,strPad);         
                rHeader.key = strCurrentMonth;
                rHeader.value = mapMonths.get(lstMonths[i]);
                rHeader.Childheader = new List<roEfficiencyWrapper.Childheader>();
                listHeaders.add(rHeader);
            }
            
            if(mapResourceAndResourceEfficiencies.size()>0){               
                for(Id resourceId: mapResourceAndResourceEfficiencies.keySet()){
                    map<string, string> mapBodyValues = new map<string, string>();
                 
                    mapBodyValues.put('Rhead', mapResources.get(resourceId).fullName__c);
                    mapBodyValues.put('RRole', mapResources.get(resourceId).Role__c);
                    List<Resource_Utilization__c> lstEfficiencies = mapResourceAndResourceEfficiencies.get(resourceId);
                    if(lstEfficiencies.size()>0){
                        map<string,string> mapEfficiencies = new map<string, string>();
                        
                        for(Resource_Utilization__c re: lstEfficiencies){
                            string eff = re.Utilization__c != null ? string.valueOf(re.Utilization__c.setScale(2))+'%' : '0%';
                            string strMonth = string.valueOf(re.Month_Number__c).leftPad(2,strPad);
                            mapEfficiencies.put(strMonth, eff);
                            for(integer i=0; i<=lstMonths.size()-1; i++){ 
                                if(mapEfficiencies.containsKey(string.valueOf(lstMonths[i]).leftPad(2,strPad))){
                                    mapBodyValues.put(string.valueOf(lstMonths[i]).leftPad(2,strPad), eff);  
                                }
                                else{
                                    mapBodyValues.put(string.valueOf(lstMonths[i]).leftPad(2,strPad), '0%');  
                                } 
                            }
                           // mapBodyValues.put(strMonth, string.valueOf(re.Utilization__c.setScale(2))+'%'); 
                        }
                                   
                    }
                    else{
                         for(integer i=0; i<=lstMonths.size()-1; i++){ 
                              mapBodyValues.put(string.valueOf(lstMonths[i]).leftPad(2,strPad), '0%'); 
                         }
                    }                    
                    listBody.add(mapBodyValues);
                }                
            }   
        }
        rEtable.header = listHeaders;
        rEtable.Body = listBody;
        // assign rWrapper
        rWrapper.Etable = rEtable;
        
        return rWrapper;
    }
    
    public static Integer weekOfMonth(Date todaysDate){
        Integer weekCount = 0;
        Integer startWeekResidue = 0;
        Integer endWeekResidue = 0;
        
        //Calculating startWeekResidue
        Date dt = todaysDate.toStartOfMonth().addDays(-1);
        Date dtFirstWeekend = dt.toStartOfWeek().addDays(6);
        startWeekResidue = dt.daysBetween(dtFirstWeekend);
        
        //Calculating endWeekResidue
        Date dtLastWeekend = todaysDate.toStartOfWeek().addDays(-1);
        endWeekResidue = dtLastWeekend.daysBetween(todaysDate);
        
        //Counting the weeks
        weekCount = (todaysDate.day() - (startWeekResidue + endWeekResidue))/7;
        weekCount += (startWeekResidue > 0 ? 1:0)+(endWeekResidue > 0 ? 1:0);
        System.Debug('Week Number: ' + weekCount);
        return weekCount;
    }
}