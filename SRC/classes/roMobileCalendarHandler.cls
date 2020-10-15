/************************************************************************ 
Author : Santosh Rao Bompally 
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roMobileCalendarHandler {
    
    public class response implements Comparable{
        @AuraEnabled
        public Datetime startTime ; 
        @AuraEnabled
        public Datetime endTime ;
        @AuraEnabled
        Public String linkURL ; 
        @AuraEnabled
        Public String name ; 
        @AuraEnabled
        Public String id ; 
        @AuraEnabled
        Public String detail; 
        @AuraEnabled
        Public String objectType; 
        @AuraEnabled
        Public String style; 
        @AuraEnabled
        Public String displayTime; 
        
        public Integer compareTo(Object compareTo){
          response otherresponse = (response)compareTo;
         
         if(startTime == otherresponse.startTime){
              return 0;
            } else if(startTime < otherresponse.startTime){
              return -1;
            } else {
              return 1;
            }
     }
    }
    
    
    
    @AuraEnabled(cacheable = true)
    public static List<ResourceOptimizerMobileCalendarConfig__mdt> getfilters(){
        
        if(roSecurityHandler.checkField(new String[] {'MasterLabel','Style__c','Show_On_Calendar__c','Create_New__c','Create_New_Link__c','FilterID_Field_Api_Name__c','Object_Api_Name__c'},'ResourceOptimizerMobileCalendarConfig__mdt',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
              return [select id,MasterLabel,Style__c,Create_New__c,Create_New_Link__c,FilterID_Field_Api_Name__c,Object_Api_Name__c,Show_On_Calendar__c from ResourceOptimizerMobileCalendarConfig__mdt where Show_On_Calendar__c = true];
        }else{
                return null;
            }
    
        }
    
    @AuraEnabled
    public static List<response> getrecords(string inputdate){
        
    // Process Inputdate and get starttime and endtime parameters 
    inputdate = String.escapeSingleQuotes(inputdate);
    inputdate = inputdate.substring(0,inputdate.length()-5).replace('T',' ') ;
    datetime dt1 = Datetime.valueOfGMT(inputdate);
    system.debug(dt1);
    Time startTime = Time.newInstance(0, 0, 0, 0);
    Time EndTime = Time.newInstance(23, 59, 59, 0);
    Date myDate = dt1.date();
    
    datetime start = Datetime.newInstance(myDate, starttime);
    datetime endt = Datetime.newInstance(myDate, EndTime);
        
    system.debug('start'+start);
    system.debug('endt'+endt);
    system.debug('start'+string.valueof(start.formatGMT('yyyy-MM-dd HH:mm:ss')));
    system.debug('endt'+string.valueof(endt.formatGMT('yyyy-MM-dd HH:mm:ss')));
    // End of processing 
    
    // Get UserId 
    String UserId = UserInfo.getUserId();
        UserId = UserId.substring(0,15);
     
        system.debug('now'+system.now());
        // Initiate Final Resopnse 
        List<response> Finalresponse = new List<response>();
        // Initiate necessary Maps 
        Map<string,string> SOQLStrings = new Map<string,string>();
        Map<string,ResourceOptimizerMobileCalendarConfig__mdt> ObjectMetadataMap = new Map<string,ResourceOptimizerMobileCalendarConfig__mdt>();
        Map<string,List<sobject>> ObjectResultsMap = new Map<string,List<sobject>>();
        
        List<ResourceOptimizerMobileCalendarConfig__mdt> ConfigData = new List<ResourceOptimizerMobileCalendarConfig__mdt>();
        
        
        if(roSecurityHandler.checkField(new String[] {'developername','Style__c','StartTime_Api_Name__c','EndTime_Api_Name__c','Show_On_Calendar__c','NameField_Api_Name__C','Detail_Field_Api_Name__c','FilterID_Field_Api_Name__c','Object_Api_Name__c'},'ResourceOptimizerMobileCalendarConfig__mdt',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
            ConfigData =[select id,developername,NameField_Api_Name__C,FilterID_Field_Api_Name__c,Style__c,Object_Api_Name__c,StartTime_Api_Name__c,EndTime_Api_Name__c,Detail_Field_Api_Name__c,Show_On_Calendar__c from ResourceOptimizerMobileCalendarConfig__mdt where Show_On_Calendar__c = true ];
        }
        
      if(ConfigData.size() >0){
            for(ResourceOptimizerMobileCalendarConfig__mdt ROMC : ConfigData){

                if(roSecurityHandler.checkField(new String[]{ROMC.NameField_Api_Name__C,ROMC.StartTime_Api_Name__c,ROMC.EndTime_Api_Name__c,ROMC.Detail_Field_Api_Name__c,ROMC.FilterID_Field_Api_Name__c},ROMC.Object_Api_Name__c,roSecurityHandler.permissionLevel.ISACCESSIBLE)){
                      String Soqlstring = 'Select Id,'+ROMC.NameField_Api_Name__C+','+ROMC.StartTime_Api_Name__c +','+ROMC.EndTime_Api_Name__c ;
                if(ROMC.Detail_Field_Api_Name__c != '' && ROMC.Detail_Field_Api_Name__c != null){
                   Soqlstring += ','+ROMC.Detail_Field_Api_Name__c ;
                 }
                Soqlstring += ' FROM '+ ROMC.Object_Api_Name__c  + ' WHERE '+ROMC.StartTime_Api_Name__c + ' >= ' + String.valueof(start.formatGMT('yyyy-MM-dd HH:mm:ss')).replace(' ','T')+'Z' + ' AND ' +ROMC.StartTime_Api_Name__c + ' <= ' + String.valueof(endt.formatGMT('yyyy-MM-dd HH:mm:ss')).replace(' ','T')+'Z';
                Soqlstring += ' AND ' +ROMC.StartTime_Api_Name__c  + ' != null ' ;
                Soqlstring += ' AND ' + ROMC.FilterID_Field_Api_Name__c + ' = \''+ UserId +'\'';
                  system.debug(Soqlstring);
             SOQLStrings.put(ROMC.Object_Api_Name__c,Soqlstring);
             ObjectMetadataMap.put(ROMC.Object_Api_Name__c,ROMC);  
                }
             } 
        }
        
        for(String IndividualObject : SOQLStrings.keySet() ){
            
            List<Sobject> TempObjectResults = new List<sobject>();
            try{
                TempObjectResults= Database.query(SOQLStrings.get(IndividualObject));
            }catch(exception e){
              system.debug('Exception'+e.getmessage());
            }

            if(TempObjectResults.size()>0){
                ObjectResultsMap.put(IndividualObject,TempObjectResults);
            }  
        }
        
        for(String finalobject : ObjectResultsMap.KeySet()){
            
            for(Sobject S : ObjectResultsMap.get(finalobject)){
                response Tempresponse = new response();
                Tempresponse.name = String.Valueof(S.get(ObjectMetadataMap.get(finalobject).NameField_Api_Name__C)); 
                Tempresponse.id = String.Valueof(S.get('Id')); 
                Tempresponse.linkURL = '/'+String.Valueof(S.get('Id')); 
                Tempresponse.startTime = (datetime)S.get(ObjectMetadataMap.get(finalobject).StartTime_Api_Name__c);
                Tempresponse.endTime = (datetime)S.get(ObjectMetadataMap.get(finalobject).EndTime_Api_Name__c);
                Tempresponse.detail = String.Valueof(S.get(ObjectMetadataMap.get(finalobject).Detail_Field_Api_Name__c));
                Tempresponse.style = String.Valueof(ObjectMetadataMap.get(finalobject).Style__c);
                Tempresponse.objectType = finalobject ;
                Tempresponse.displayTime = String.Valueof(Tempresponse.startTime.format('HH:mm:ss.SSS'));
                Finalresponse.add(Tempresponse);
            }
            
        }
        
        
        system.debug(SOQLStrings);
        system.debug(Finalresponse);
        
        
        Finalresponse.sort();
        return Finalresponse ;
    }

}