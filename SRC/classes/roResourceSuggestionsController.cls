/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceSuggestionsController {

    public class finalresponse{
        @AuraEnabled
        public boolean showallocation ; 
        @AuraEnabled
        public List<resourcedata> finalresources ; 
        @AuraEnabled
        public string displaymessage ;
        @AuraEnabled
        public string startdatetime ;
        @AuraEnabled
        public string enddatetime ;
    }

    public class resourcedata{
        @AuraEnabled
        public decimal skillvalue ; 
        @AuraEnabled
        public resource__c resource ; 
        @AuraEnabled
        public String resourceId ;
        @AuraEnabled
        public String resourceProfilePictureURL ;  
        @AuraEnabled
        public String resourceFullName ; 
        @AuraEnabled
        public String resourceCompany ; 
        @AuraEnabled
        public String resourceRole ; 
        @AuraEnabled
        public String resourceDepartment ; 
        @AuraEnabled
        public String resourceTimeZone ; 
        @AuraEnabled
        public String resourceParentGroup ;
        @AuraEnabled
        public string resourceredirecturl ;
     

    }

    public class datetimeresponse{
        @AuraEnabled
        public string startdatetime ;
        @AuraEnabled
        public string enddatetime ;
    }

    @AuraEnabled(cacheable=true)
    public static List<resource_group__c> fetchgroups(){
        if(Schema.sObjectType.resource_group__c.fields.name.isAccessible()){
            return [select id,name from resource_group__c Order By name ASC];
        }else{
            return null;
        }
        
        
    }
    @AuraEnabled(cacheable=true)
    public static List<Skills__c> getskills(){
        if(Schema.sObjectType.Skills__c.fields.name.isAccessible()){
            return [select id,name from Skills__c] ;
        }else{
            return null;
        }
      

    }

    @AuraEnabled
    public static datetimeresponse getdatetime(String ObjectName, string rid){
        datetime localstarttime ;
        datetime localendtime;
        string StartDateFieldName ; 
        string EndDateFieldName ;
        string Querytogetdata;
        datetimeresponse DR = new datetimeresponse();

        Resource_Allocation_Parent__c RAP = new Resource_Allocation_Parent__c(); 

        if(Schema.sObjectType.Resource_Allocation_Parent__c.fields.Parent_JSON__c.isAccessible()){

            RAP = [select id,Parent_JSON__c from Resource_Allocation_Parent__c where Parent_API_Name__c	= :ObjectName LIMIT 1]; 

        }

        if(RAP != null){
            if(RAP.Parent_JSON__c != ''){

                roCalendarWrapper.resourceAllocationParentWrapper parentWrapper = (roCalendarWrapper.resourceAllocationParentWrapper) JSON.deserialize(RAP.Parent_JSON__c, roCalendarWrapper.resourceAllocationParentWrapper.Class);
                StartDateFieldName = parentWrapper.startDateTimeFielAPI;
                EndDateFieldName = parentWrapper.endDateTimeFielAPI;

            }
        }

        

        if(StartDateFieldName != '' && StartDateFieldName != null && EndDateFieldName != '' && EndDateFieldName != null && rid != '' && rid != null  ){
            Querytogetdata = 'Select id'+ ',' + String.escapeSingleQuotes(StartDateFieldName) + ',' + String.escapeSingleQuotes(EndDateFieldName) + ' From '+ String.escapeSingleQuotes(ObjectName) + ' Where Id = ' + '\'' + String.escapeSingleQuotes(rid) + '\'' + ' Limit 1' ;
        
		/*	if(roSecurityHandler.checkObject(ObjectName,roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
              roSecurityHandler.checkField(new String[] {StartDateFieldName,EndDateFieldName},ObjectName,roSecurityHandler.permissionLevel.ISACCESSIBLE))
            
            if(roSecurityHandler.isSafeObject(String.escapeSingleQuotes(ObjectName))&&
            roSecurityHandler.isSafeField(String.escapeSingleQuotes(StartDateFieldName),String.escapeSingleQuotes(ObjectName))&&
            roSecurityHandler.isSafeField(String.escapeSingleQuotes(EndDateFieldName),String.escapeSingleQuotes(ObjectName))&&
            roSecurityHandler.isSafeField('name',String.escapeSingleQuotes(ObjectName))) */
            
            if(roSecurityHandler.checkObject(String.escapeSingleQuotes(ObjectName),roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
              roSecurityHandler.checkField(new String[] {String.escapeSingleQuotes(StartDateFieldName),String.escapeSingleQuotes(EndDateFieldName)},ObjectName,roSecurityHandler.permissionLevel.ISACCESSIBLE)){
                sObject  s = Database.query(Querytogetdata);

                if(s.get(StartDateFieldName) != null){
                    localstarttime = (datetime)s.get(StartDateFieldName) ;  
                    }
                      if(s.get(EndDateFieldName) != null){
                    localendtime = (datetime)s.get(EndDateFieldName) ; 
                   } 
            }

            
        }

        if(localstarttime != null && localendtime != null && (localstarttime < localendtime)){

            DR.startdatetime = String.valueof(localstarttime.formatGMT('yyyy-MM-dd HH:mm:ss')) ;
            DR.enddatetime = String.valueof(localendtime.formatGMT('yyyy-MM-dd HH:mm:ss')) ;
        }

      return DR ;
    }

    private static List<resourcedata> sortresources(List<resource__c> incoming, string sortskillId){

        List<resourcedata> Outgoing = new List<resourcedata>();
        
        Map<Id,resource__c> incomingresourcemap = new Map<Id,resource__c>();
        set<Id> resourceIds = new set<Id>();

        if(sortskillId != '' && sortskillId != null && sortskillId != 'undefined'){
            for(resource__c R: incoming ){
                resourceIds.add(R.Id);
                incomingresourcemap.put(R.Id,R);
    
            }
            
            List<Resource_Skills__c> Resourceskills = new  List<Resource_Skills__c>();
            if(roSecurityHandler.checkField(new String[] {'resource__c','skill__c','Skill_Level__c'},'Resource_Skills__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
              roSecurityHandler.checkObject('Skills__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
                Resourceskills = [select id,Resource__c,Skill__c,Skill_Level__c from Resource_Skills__c  where Resource__c IN :resourceIds AND Skill__c = :sortskillId AND skill__r.active__c = true ORDER BY Skill_Level__c DESC];
            }
            
    
            for(Resource_Skills__c RS : Resourceskills){
                resourcedata RD = new resourcedata();
                resource__c rtemp = incomingresourcemap.get(RS.Resource__c);
             //  RD.resource = incomingresourcemap.get(RS.Resource__c);
                RD.resourceId = rtemp.Id;
                RD.resourceProfilePictureURL = rtemp.Profile_Picture_URL__c ;
                RD.resourceFullName = rtemp.First_Name__c + ' '+ rtemp.Last_Name__c;
                RD.resourceCompany = rtemp.Company_Name__c ;
                RD.resourceDepartment = rtemp.Department__c ;
                RD.resourceRole = rtemp.Role__c ;
                RD.resourceTimeZone = rtemp.Resource_Time_Zone__c ;
                RD.resourceParentGroup = rtemp.resource_group__r.name ;
                RD.skillvalue = RS.Skill_Level__c;
                RD.resourceredirecturl = '/'+RS.Resource__c ;
                Outgoing.add(RD);
            }
        }else{
            for(resource__c R: incoming ){
                resourcedata RD = new resourcedata();
             //   RD.resource = R;
              //  RD.resource = incomingresourcemap.get(RS.Resource__c);
                RD.resourceId = R.Id;
                RD.resourceProfilePictureURL = R.Profile_Picture_URL__c ;
                RD.resourceFullName = R.First_Name__c + ' '+ R.Last_Name__c;
                RD.resourceCompany = R.Company_Name__c ;
                RD.resourceDepartment = R.Department__c ;
                RD.resourceRole = R.Role__c ;
                RD.resourceTimeZone = R.Resource_Time_Zone__c ;
                RD.resourceParentGroup = R.resource_group__r.name ;
                RD.resourceredirecturl = '/'+R.Id ;
                Outgoing.add(RD);

            }

        }
        

        return Outgoing ;

    }

    

    @AuraEnabled
    public static finalresponse getresourcesdirect(String ObjectName, string GroupID, string Allskills, string sortskillId, string startdatetime, string enddatetime,Integer NumberofResources,Boolean isappointment ){
     system.debug('ObjectName'+ObjectName);
     system.debug('GroupID'+GroupID);
     system.debug('startdatetime'+startdatetime);
     system.debug('Allskills'+Allskills); 
        system.debug('isappointment'+isappointment);  
     string GrooupIDFilter = '';    
     Boolean Queryhasfilters = false ; 
     datetime localstarttime ;
     datetime localendtime;
     String Querytogetdata ;
     List<String> Skills = new List<string>() ;
     List<resource__c> FinalresourceList = new List<resource__c>();
     Set<Id> ResourceIds = new Set<Id>();

     finalresponse FR = new finalresponse();
     FR.showallocation = false;
        
    // Get Group Id to filter 
    if(GroupID != '' && GroupID != null && GroupID != 'null' ){
         GrooupIDFilter = '%'+  GroupID.substring(0, 15) +'%' ;  
         Queryhasfilters = true;
        }  
    // Get Skills filter 
        if(Allskills != '' && Allskills != null && Allskills != 'null'){
           Skills = Allskills.split(','); 
           
        }
    // Assign Datetime in case of input from filter 
        if(startdatetime != '' && startdatetime != null && startdatetime != 'null' && enddatetime != '' && enddatetime != null && startdatetime != 'null' ){
           
         startdatetime = startdatetime.removeEnd('.000Z').replace('T',' ');
         enddatetime = enddatetime.removeEnd('.000Z').replace('T',' ');
            localstarttime =  datetime.valueofGMT(startdatetime);
       
            localendtime = datetime.valueofGMT(enddatetime);
     

           
            
        } 

        system.debug('startdatetime'+startdatetime);
        system.debug('enddatetime'+enddatetime);
     // Get list of available resources 
       String ResourceListQuery = 'SELECT Id,name,Profile_Picture_URL__c,Resource_Time_Zone__c,First_Name__c,FullName__c,Skills_Backend__c,Last_Name__c,Role__c,Company_Name__c,Department__c,Division__c,Resource_Group__c,Resource_Group__r.name from resource__c WHERE Active__c = true ';
        	
        if(isappointment){
            ResourceListQuery += ' AND Active_for_Appointments__c = true ';
            
        }
        if(GrooupIDFilter != ''){
             ResourceListQuery += ' AND ResourceGroupIds__c like ' + '\'' + GrooupIDFilter + '\'' ; 
        }
            ResourceListQuery += ' ORDER BY First_Name__c ASC';  

                system.debug('ResourceListQuery'+ ResourceListQuery);

        List<resource__c> Queryresultstemp = New List<resource__c>();
        
        if(roSecurityHandler.checkField(new String[] {'name','Profile_Picture_URL__c','Active_for_Appointments__c','ResourceGroupIds__c','Resource_Time_Zone__c','First_Name__c','FullName__c','Skills_Backend__c','Last_Name__c','Role__c','Company_Name__c','Department__c','Division__c','Resource_Group__c','Active__c'},'resource__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
          roSecurityHandler.checkObject('resource__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
           roSecurityHandler.checkObject('Resource_Group__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
            	Queryresultstemp = database.query(ResourceListQuery);
        }
            
            
        List<Id> QueryresourceIds = new List<Id>();
        Map<Id,resource__c> QueryresourceIdMap = new  Map<Id,resource__c>();
        
        if(Queryresultstemp.size()>0){
            for(resource__c R : Queryresultstemp){
              QueryresourceIds.add(R.id); 
               QueryresourceIdMap.put(R.id,R); 
            }
            
        }
        system.debug('Queryresultstemp'+Queryresultstemp);
        List<resource__c> Queryresults = new List<resource__c>();
        List<Id> QueryresultIds = new List<Id>();
        if(string.valueof(localstarttime) != '' &&  localstarttime != null & string.valueof(localendtime) != '' && localendtime != null && localstarttime < localendtime){
               QueryresultIds = getAvailableResources(QueryresourceIds, localstarttime, localendtime);
            if(QueryresultIds.size()>0){
              for(Id rid : QueryresultIds){
                Queryresults.add(QueryresourceIdMap.get(rid)); 
            }  
            } 
        }else{
            Queryresults = Queryresultstemp ;
        }

        system.debug('Queryresults'+Queryresults);
        system.debug('QueryresultsSize'+Queryresults.size());

        if(Skills.size() > 0 && Queryresults.size() > 0){

    

            for(Resource__c R : Queryresults){

                system.debug('backendskills-'+R.Skills_Backend__c);

                if(R.Skills_Backend__c != '' && R.Skills_Backend__c != null ){

                    List<string> rskillslist = R.Skills_Backend__c.split(',');
                    Set<String> rskills = new Set<String>(rskillslist);
                    
                system.debug('rskills'+rskills);
                system.debug('sskills'+skills);
                    if(rskills.containsAll(skills)){
                  if(NumberofResources > 0 && NumberofResources != null ){
                            if(FinalresourceList.size() <= NumberofResources){
                                FinalresourceList.add(R);
                            }
                        }
                    }

                }

            }



        }else{

            if(Queryresults.size() > 0){

                if(NumberofResources > 0 && NumberofResources != null ){

                    if(NumberofResources > Queryresults.size()){
                        for(integer i = 0; i < Queryresults.size(); i++){
                            FinalresourceList.add(Queryresults[i]);
                        }
                    }else{
                        for(integer i = 0; i < NumberofResources; i++){
                            FinalresourceList.add(Queryresults[i]);
                        }
                    }

                    
    
                }

            }

            

        }
 system.debug('ResourceListQuery'+ ResourceListQuery);
         system.debug('FinalresourceList'+FinalresourceList);
        system.debug('FinalresourceListSize'+FinalresourceList.size());
        if(FinalresourceList.size()>0){
            FR.displaymessage = 'Success';
            FR.finalresources = sortresources(FinalresourceList,sortskillId)  ;
            
            
            if(localstarttime != null && localendtime != null && (localstarttime < localendtime)){
                FR.showallocation = true; 
                FR.startdatetime = String.valueof(localstarttime.formatGMT('yyyy-MM-dd HH:mm:ss')) ;
                FR.enddatetime = String.valueof(localendtime.formatGMT('yyyy-MM-dd HH:mm:ss')) ;
            }
            
        }else{
            FR.displaymessage = 'No resource is currently available. Please check for other time intervals or choose different group or skills ';
            FR.finalresources = null;
            FR.showallocation = false ;
        }
        
        
    system.debug('FR'+FR);

    return FR ;
   
      
    }

      @AuraEnabled
    public static List<Id> getAvailableResources(List<Id> resourceIds, datetime startDateTimeFinal, datetime endDateTimeFinal){
     	
        
        List<Id> availableresourceIds = new List<Id>();
        system.debug('santoshdebug1'+startDateTimeFinal.dateGMT()+'-'+startDateTimeFinal);
        system.debug('santoshdebug1'+endDateTimeFinal.dateGMT()+'-'+endDateTimeFinal);
        if(startDateTimeFinal.dateGMT() == endDateTimeFinal.dateGMT()){
                      
            availableresourceIds = getAvailableResourcesList(resourceIds,startDateTimeFinal,endDateTimeFinal);
        }
        else{
            
            datetime newendDateTimeFinal = Datetime.newInstanceGmt(startDateTimeFinal.dateGMT(), Time.newInstance(23, 59, 59, 0));
            datetime newstartDateTimeFinal = Datetime.newInstanceGmt(endDateTimeFinal.dateGMT(), Time.newInstance(0, 0, 0, 0));
            List<Id> resourcetemp1 = getAvailableResourcesList(resourceIds,startDateTimeFinal,newendDateTimeFinal);
            List<Id> resourcetemp2 = getAvailableResourcesList(resourceIds,newstartDateTimeFinal,endDateTimeFinal);
            for(Id rid: resourceIds){
                if(resourcetemp1.contains(rid) && resourcetemp2.contains(rid)){
                    availableresourceIds.add(rid);
                    
                }
            }
        }
         
        
       	
        return availableresourceIds; 
    }
    
     public static List<Id> getAvailableResourcesList(List<Id> resourceIds, datetime startDateTimeFinal, datetime endDateTimeFinal){
         Map<Id, Resource_Available_Hours__c> resourceAvailMap = new Map<Id, Resource_Available_Hours__c>();
        List<Id> availableresourceIds = new List<Id>();
         system.debug('santoshdebug2'+startDateTimeFinal.dateGMT()+'-'+startDateTimeFinal);
        system.debug('santoshdebug2'+endDateTimeFinal.dateGMT()+'-'+endDateTimeFinal);
        if(startDateTimeFinal.dateGMT() == endDateTimeFinal.dateGMT()){
            
          	List<Resource_Available_Hours__c> availableHours = [SELECT Id, Start_time__c, End_Time__c, Resource_Utilization__c, 
                Resource_Utilization__r.Resource__c, Resource_Utilization__r.Resource__r.First_Name__c, 
                Resource_Utilization__r.Resource__r.Last_Name__c, Resource_Utilization__r.Booked_Time_Slots__c, Resource_Utilization__r.Utilization_Date__c 
                FROM Resource_Available_Hours__c WHERE Resource_Utilization__r.Resource__c IN :resourceIds  
                AND Start_time__c <=  :startDateTimeFinal AND End_Time__c >= :endDateTimeFinal ];  
            system.debug('santoshdebug'+availableHours);
            for(Resource_Available_Hours__c availHours :availableHours ){
                if(!resourceAvailMap.containsKey(availHours.Resource_Utilization__r.Resource__c)){
                     resourceAvailMap.put(availHours.Resource_Utilization__r.Resource__c, availHours);
                }
            }
            
            Integer Starttimecompare = startDateTimeFinal.hourGMT() * 60 + startDateTimeFinal.minuteGmt();
            Integer endtimecompare = endDateTimeFinal.hourGMT() * 60 + endDateTimeFinal.minuteGmt();
            system.debug('Starttimecompare'+Starttimecompare);
            system.debug('endtimecompare'+endtimecompare);
            
            for(Id resId :resourceAvailMap.keySet()){
              	string bookedSlot = resourceAvailMap.get(resId).Resource_Utilization__r.Booked_Time_Slots__c; 
                
                 if(bookedSlot != null && bookedSlot != ''){
                     
                     boolean resourceavailable = true;
                     
                                for(string slot :bookedSlot.split(';')){
                                    Integer startSlot = Integer.valueOf(slot.split('-')[0]);
                                    Integer endSlot = Integer.valueOf(slot.split('-')[1]);
                                    system.debug('Starttimecompare'+Starttimecompare);
           							 system.debug('endtimecompare'+endtimecompare);
                                    
                                    if((startSlot >= Starttimecompare && endslot <= endtimecompare)||(startSlot <= Starttimecompare && endslot >= Starttimecompare)||(startSlot <= endtimecompare && endslot >= endtimecompare)){
                                        resourceavailable = false;
                                    }
                                }
                     
                     if(resourceavailable){
                        availableresourceIds.add(resId); 
                     }
                 }else{
                     availableresourceIds.add(resId); 
                 }
                
            }
            
            
              
            
        }
       
         return availableresourceIds; 
     }
    
    

}