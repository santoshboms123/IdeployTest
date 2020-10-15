/************************************************************************ 
Author : Santosh Rao Bompally 
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/

public with sharing class roAllocationUIhandler {
  

    public class allocationwrapper{

        public string resourceids {get;set;}
        public string parentid {get;set;}
        public boolean isbacklog {get;set;}
        public string startdatetime {get;set;}
        public string enddatetime {get;set;}
        public string subject {get;set;}
        public string description {get;set;}
        public string relatedtoid {get;set;}
        public string relatedtoname {get;set;}
        public string relatedtoobject {get;set;}
        public addresswrap address{get;set;}

    }

    public class addresswrap {
        public string street {get;set;}
        public string city {get;set;}
        public string province {get;set;}
        public string postalcode {get;set;}
        public string country {get;set;}
    }

    public class allocationresponse{
        @AuraEnabled
        public string allocationid {get;set;}
        @AuraEnabled
        public string allocationnumber {get;set;} 
        @AuraEnabled
        public integer allocationssize {get;set;}
        @AuraEnabled
        public string message {get;set;} 
        @AuraEnabled
        public string type {get;set;} 
        @AuraEnabled
        public boolean success {get;set;}  
    }
  /*  @AuraEnabled
    public static Resource_Allocation__c getallocation(string pid){

        return [select id,name,Subject__c,Description__c,Street__c,City__c,Province__c,Country__c,PostalCode__c,Relatedto_Id__c,Relatedto_Name__c,Relatedto_Object__c from Resource_Allocation__c where id = :pid LIMIT 1];
    
    } */

    private static Resource_Allocation__c generateallocation(string allocationjson, string resourceid, string objectapiname){
        allocationwrapper allocationinput = (allocationwrapper)JSON.deserialize(allocationjson,allocationwrapper.Class);

        Resource_Allocation__c RA = new Resource_Allocation__c();
        if(objectapiname != '' && objectapiname != null){
            
            RA.put(objectapiname,allocationinput.parentid);
        }
        
        RA.Allocated_Object_Id__c = allocationinput.parentid;
        RA.Allocated_Object__c = objectapiname ;
        
       if(allocationinput.isbacklog){
        RA.Status__c = 'New';
       }else{
        RA.Resource__c = resourceid ; 
        RA.Status__c = 'Scheduled';
       } 
        RA.Subject__c = allocationinput.subject;
        RA.Description__c = allocationinput.description;
        if(allocationinput.startdatetime != null && allocationinput.startdatetime != '')RA.Allocated_Start_DateTime__c = Datetime.valueOfGMT(allocationinput.startdatetime.replace('T',' ').replace('.000Z',''));
         if(allocationinput.enddatetime != null && allocationinput.enddatetime != '')RA.Allocated_End_Datetime__c = Datetime.valueOfGMT(allocationinput.enddatetime.replace('T',' ').replace('.000Z','')) ;
        RA.Street__c = allocationinput.address.street ;
        RA.City__c = allocationinput.address.city ;
        RA.Province__c = allocationinput.address.province;
        RA.Country__c = allocationinput.address.country;
        RA.PostalCode__c = allocationinput.address.postalcode;
        RA.Relatedto_Id__c = allocationinput.relatedtoid ;
        RA.Relatedto_Name__c = allocationinput.relatedtoname ;
        RA.Relatedto_Object__c = allocationinput.relatedtoobject ;
        RA.Calculate_Utilization__c = true;

        return RA;
    }

    @AuraEnabled
    public static allocationresponse createallocation(string allocationjson){

            system.debug('allocationjson'+allocationjson);
            allocationwrapper allocationinput = (allocationwrapper)JSON.deserialize(allocationjson,allocationwrapper.Class);
            system.debug('allocationjson'+ allocationinput.resourceids);
            allocationresponse AR = new allocationresponse();
            List<string> AllresourceIds = new List<string>();
        List<Resource__c> allresourceswithusers = new List<Resource__c>();
            List<Resource_Allocation__c> Allocationstoinsert = new List<Resource_Allocation__c>();
            Map<string,string> ResourceUserMap = new Map<string,string>();
            string objectapiname = '';

        

        // Fetch the parent Object
        if(allocationinput.parentid != null && allocationinput.parentid != ''){

            Id Pid = allocationinput.parentid ;
            objectapiname = Pid.getSObjectType().getDescribe().getName();
            if(! objectapiname.toLowerCase().contains('__c')){
                objectapiname += '__c';
            }
            system.debug('PID'+allocationinput.parentid);
            system.debug('POName'+objectapiname);

        }

        // Split resources from the Json
        if(allocationinput.resourceids != '' && allocationinput.resourceids != null){
            AllresourceIds = allocationinput.resourceids.split(',');
        }else{
            if(!allocationinput.isbacklog){
                AR.message = 'Please select atleast one resource';
                AR.success = false; 
                return AR;
            }
            
        }
        
        if(AllresourceIds.size()>0){
                allresourceswithusers = [select id,user__c from Resource__c where id IN :AllresourceIds AND user__c != null];

            for(Resource__c R : allresourceswithusers){
                ResourceUserMap.put(string.valueof(R.id).substring(0,15),string.valueof(R.user__c).substring(0,15));
                }
            system.debug(allresourceswithusers);
            system.debug(ResourceUserMap);
            
        }



        if(!objectapiname.contains('Resource_Allocation__c') ){
			
            if(AllresourceIds.size()>0){
                
            for(String resourceid : AllresourceIds){
                    Resource_Allocation__c RA = new Resource_Allocation__c();
                    RA = generateallocation(allocationjson,resourceid,objectapiname);
    
                    system.debug(ResourceUserMap.get(resourceid));
                    if(ResourceUserMap.get(resourceid) != null && ResourceUserMap.get(resourceid) != ''){
                        RA.ownerid = ResourceUserMap.get(resourceid) ;
                    }
                
    
                    Allocationstoinsert.add(RA); 
    
                }
            }else{
                Resource_Allocation__c RA1 = new Resource_Allocation__c();
                    RA1 = generateallocation(allocationjson,'',objectapiname);
                    Allocationstoinsert.add(RA1); 

            }
          
			system.debug('santoshtest'+Allocationstoinsert);
            try{
            insert Allocationstoinsert ;
			system.debug('santoshtestAllocationstoinserted'+Allocationstoinsert);
            AR.allocationid =  Allocationstoinsert[0].id;  
            AR.allocationnumber =  [select name from Resource_Allocation__c where id = :Allocationstoinsert[0].id limit 1].name; 
            AR.allocationssize = Allocationstoinsert.size();
            AR.message = 'Success';
            AR.type = 'C'; // Indicates Created
            AR.success = true; 
            }catch(exception e){
                system.debug(e.getMessage());
                AR.message = e.getmessage();
                AR.success = false; 
            }
            


        }else{
            if(AllresourceIds.size()>0 && objectapiname.contains('Resource_Allocation__c')){

                Resource_Allocation__c RA = [select id,name from Resource_Allocation__c where id = :allocationinput.parentid LIMIT 1];

               
                RA.Resource__c = AllresourceIds[0] ; 
                RA.Status__c = 'Scheduled';
                RA.Subject__c = allocationinput.subject;
                RA.Description__c = allocationinput.description;
                RA.Allocated_Start_DateTime__c = Datetime.valueOfGMT(allocationinput.startdatetime.replace('T',' ').replace('.000Z',''));
                RA.Allocated_End_Datetime__c = Datetime.valueOfGMT(allocationinput.enddatetime.replace('T',' ').replace('.000Z','')) ;
                RA.Street__c = allocationinput.address.street ;
                RA.City__c = allocationinput.address.city ;
                RA.Province__c = allocationinput.address.province;
                RA.Country__c = allocationinput.address.country;
                RA.PostalCode__c = allocationinput.address.postalcode;
                RA.Relatedto_Id__c = allocationinput.relatedtoid ;
                RA.Relatedto_Name__c = allocationinput.relatedtoname ;
                RA.Relatedto_Object__c = allocationinput.relatedtoobject ;
                RA.Calculate_Utilization__c = true;

                system.debug(ResourceUserMap.get(AllresourceIds[0]));
                if(ResourceUserMap.get(AllresourceIds[0]) != null && ResourceUserMap.get(AllresourceIds[0]) != ''){
                    RA.ownerid = ResourceUserMap.get(AllresourceIds[0]) ;
                }

               
                try{
                    Update RA;
                    AR.allocationid =  RA.id;  
                    AR.allocationnumber =  RA.name; 
                    AR.message = 'Allocation Successfully Updated';
                    AR.type = 'U'; // Indicates Updated
                    AR.success = true; 
                    }catch(exception e){
                        AR.message = e.getmessage();
                        AR.success = false; 
                    }
            }
        }





            return AR;

    }
}