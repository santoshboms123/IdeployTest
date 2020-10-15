/************************************************************************ 
Author : Santosh 
Details: 
    Purpose : roRelatedToPickerHandler is the controller for the LWC rorelatedtoPicker, which helps to associate an allocation to any record in salesforce. 
    Intial release date : October 05, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roRelatedToPickerHandler {


    public class returnresponse{
        @AuraEnabled public string ObjectApiName{get; set;}
        @AuraEnabled public string RecordDisplayValue{get; set;}
        @AuraEnabled public string RecordId {get; set;}
        @AuraEnabled public string Recorddetail {get; set;}
        @AuraEnabled public string RecordIconType {get; set;}
    }

   

    @AuraEnabled(cacheable=true)
    public static List<Resource_Optimizer_Relatedto_Config__mdt> getobjects(){
      
         if(roSecurityHandler.checkField(new String[] {'MasterLabel','ObjectApiName__c'},'Resource_Optimizer_Relatedto_Config__mdt',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
              return [Select id,MasterLabel,ObjectApiName__c from Resource_Optimizer_Relatedto_Config__mdt where Active__c = true];
        }else{
                return null;
          }
   
    }

    @AuraEnabled(cacheable=true)
    public static List<returnresponse> getresults( string searchstring, string objectapiname){
        List<returnresponse> FR = new List<returnresponse>();
        String Querystring = '';
        List<Sobject> allrecords = new List<Sobject>();
        List<string> displayfields = new List<string>();
        String recorddetail = '';
        Resource_Optimizer_Relatedto_Config__mdt RORC = New Resource_Optimizer_Relatedto_Config__mdt();
            
         
		if(roSecurityHandler.checkField(new String[] {'MasterLabel','Icon__c','ObjectApiName__c','Display_Field_Api_Names__c','Search_Attribute_Api_Name__c'},'Resource_Optimizer_Relatedto_Config__mdt',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
              RORC =  [Select id,MasterLabel,Icon__c,ObjectApiName__c,Display_Field_Api_Names__c,Search_Attribute_Api_Name__c from Resource_Optimizer_Relatedto_Config__mdt where Active__c = true AND ObjectApiName__c = :objectapiname];
        }
        	
        if(RORC != null && RORC.Display_Field_Api_Names__c != null){
            displayfields = String.valueof(RORC.Display_Field_Api_Names__c).split(',');
        }

        if(RORC != null && RORC.Search_Attribute_Api_Name__c != '' && searchstring != '' && displayfields.size()>0){
            
            List<string> Checkfields = new List<String>();
            Checkfields.addall(displayfields);
            Checkfields.add( RORC.Search_Attribute_Api_Name__c);
            
            if(roSecurityHandler.checkField( Checkfields,objectapiname,roSecurityHandler.permissionLevel.ISACCESSIBLE)){
              	 Querystring = 'Select Id,'+RORC.Display_Field_Api_Names__c+','+ RORC.Search_Attribute_Api_Name__c + ' FROM '+ objectapiname + ' WHERE '+ RORC.Search_Attribute_Api_Name__c + ' LIKE ' + '\'%'+searchstring+ '%\'';
       		 }
           }
        System.debug('QS'+Querystring);
        if(Querystring != ''){
            try{
                allrecords = database.query(Querystring);
            }catch(exception e){

            }
            
        }
        System.debug('AR'+allrecords);
        if(allrecords.size() > 0){
            string spacehodler = ' • ';
            for(sObject O : allrecords){
                recorddetail = '';
                returnresponse rr = new returnresponse();
                rr.ObjectApiName = objectapiname ;
                rr.RecordId =  String.valueof(O.Id) ;
                rr.RecordIconType = RORC.Icon__c ;
                rr.RecordDisplayValue = String.valueof(O.get(RORC.Search_Attribute_Api_Name__c));
             

                for(String S : displayfields){
                    if(O.get(S) != null && O.get(S) != ''){
                        recorddetail += String.valueof(O.get(S)) + spacehodler ;
                    }
                }
                recorddetail.removeEnd(spacehodler);
                rr.Recorddetail = recorddetail ;
                FR.add(rr);

            }
        }
        System.debug('FR'+FR);

    return FR ;
    }
}